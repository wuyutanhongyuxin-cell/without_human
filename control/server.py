from __future__ import annotations

import json
import os
import re
import socket
import subprocess
import time
from datetime import datetime
from http import HTTPStatus
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any
from urllib.parse import parse_qs, urlparse


ROOT = Path(__file__).resolve().parents[1]
FRONTEND = ROOT / "frontend"
CONFIG = ROOT / "control" / "projects.json"
STATE_PATH = ROOT / "control" / "state.json"
LOG_DIR = ROOT / "control" / "logs"
STAGES = ROOT / "orchestration" / "stages.json"
MEMORY_STATE: dict[str, Any] = {"events": [], "last_actions": {}}

LOG_DIR.mkdir(parents=True, exist_ok=True)

SECRET_PATTERNS = [
    re.compile(r"sk-[A-Za-z0-9_-]{12,}"),
    re.compile(r"ghp_[A-Za-z0-9_]{12,}"),
    re.compile(r"github_pat_[A-Za-z0-9_]{12,}"),
    re.compile(r"AKIA[0-9A-Z]{16}"),
    re.compile(r"-----BEGIN (?:RSA|OPENSSH|EC) PRIVATE KEY-----"),
]


def load_json(path: Path, default: Any) -> Any:
    if not path.exists():
        return default
    with path.open("r", encoding="utf-8-sig") as f:
        return json.load(f)


def save_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")


def now() -> str:
    return datetime.now().isoformat(timespec="seconds")


def redact_text(text: str) -> str:
    redacted = text
    for pattern in SECRET_PATTERNS:
        redacted = pattern.sub("[REDACTED_SECRET]", redacted)
    return redacted


def config() -> dict[str, Any]:
    return load_json(CONFIG, {"projects": []})


def state() -> dict[str, Any]:
    try:
        return load_json(STATE_PATH, MEMORY_STATE)
    except OSError:
        return MEMORY_STATE


def record_event(project_id: str, action: str, status: str, summary: str, log: str | None = None) -> None:
    data = state()
    event = {
        "at": now(),
        "project_id": project_id,
        "action": action,
        "status": status,
        "summary": summary,
        "log": log,
    }
    data.setdefault("events", []).append(event)
    data["events"] = data["events"][-100:]
    data.setdefault("last_actions", {})[f"{project_id}:{action}"] = event
    MEMORY_STATE.clear()
    MEMORY_STATE.update(data)
    try:
        save_json(STATE_PATH, data)
    except OSError:
        pass


def project(project_id: str) -> dict[str, Any]:
    for item in config().get("projects", []):
        if item.get("id") == project_id:
            return item
    raise KeyError(f"unknown project: {project_id}")


def run_command(args: list[str], cwd: Path | None = None, timeout: int = 120, stdin: bytes | None = None) -> dict[str, Any]:
    start = time.time()
    try:
        proc = subprocess.run(
            args,
            cwd=str(cwd) if cwd else None,
            input=stdin,
            capture_output=True,
            timeout=timeout,
            shell=False,
        )
        out = redact_text(proc.stdout.decode("utf-8", errors="replace"))
        err = redact_text(proc.stderr.decode("utf-8", errors="replace"))
        return {
            "ok": proc.returncode == 0,
            "code": proc.returncode,
            "duration_sec": round(time.time() - start, 2),
            "stdout": out,
            "stderr": err,
            "args": args,
        }
    except subprocess.TimeoutExpired as exc:
        return {
            "ok": False,
            "code": "timeout",
            "duration_sec": round(time.time() - start, 2),
            "stdout": redact_text((exc.stdout or b"").decode("utf-8", errors="replace") if isinstance(exc.stdout, bytes) else (exc.stdout or "")),
            "stderr": redact_text((exc.stderr or b"").decode("utf-8", errors="replace") if isinstance(exc.stderr, bytes) else (exc.stderr or "")),
            "args": args,
        }
    except FileNotFoundError as exc:
        return {
            "ok": False,
            "code": "not_found",
            "duration_sec": round(time.time() - start, 2),
            "stdout": "",
            "stderr": str(exc),
            "args": args,
        }


def write_log(project_id: str, action: str, result: Any) -> str | None:
    safe_project = "".join(c if c.isalnum() or c in "-_" else "_" for c in project_id)
    safe_action = "".join(c if c.isalnum() or c in "-_" else "_" for c in action)
    path = LOG_DIR / f"{datetime.now().strftime('%Y%m%d-%H%M%S')}-{safe_project}-{safe_action}.json"
    try:
        save_json(path, result)
        return str(path.relative_to(ROOT))
    except OSError:
        return None


def repo_path(p: dict[str, Any]) -> Path:
    return Path(p["windows_repo"])


def file_info(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {"exists": False}
    stat = path.stat()
    return {"exists": True, "size": stat.st_size, "mtime": datetime.fromtimestamp(stat.st_mtime).isoformat(timespec="seconds")}


def wsl_test_file(p: dict[str, Any], path: str) -> bool:
    res = run_command(["wsl", "-d", p["wsl_distro"], "--", "test", "-f", path], timeout=20)
    return bool(res["ok"])


def wsl_file_summary(p: dict[str, Any], path: str) -> dict[str, Any]:
    res = run_command(["wsl", "-d", p["wsl_distro"], "--", "stat", "-c", "%s|%y", path], timeout=20)
    if not res["ok"]:
        fallback = run_command(["wsl", "-d", p["wsl_distro"], "--", "cat", path], timeout=20)
        if fallback["ok"]:
            return {"exists": True, "path": path, "size": len(fallback["stdout"].encode("utf-8")), "mtime": None}
        return {"exists": False, "path": path}
    text = res["stdout"].strip()
    size, _, mtime = text.partition("|")
    return {"exists": True, "path": path, "size": int(size or 0), "mtime": mtime}


def project_status(p: dict[str, Any]) -> dict[str, Any]:
    cwd = repo_path(p)
    status = run_command(["git", "-c", f"safe.directory={cwd.as_posix()}", "-C", str(cwd), "status", "--short"], timeout=20)
    head = run_command(["git", "-c", f"safe.directory={cwd.as_posix()}", "-C", str(cwd), "rev-parse", "HEAD"], timeout=20)
    diff_stat = run_command(["git", "-c", f"safe.directory={cwd.as_posix()}", "-C", str(cwd), "diff", "--stat"], timeout=20)
    return {
        "id": p["id"],
        "name": p["name"],
        "github": p["github"],
        "windows_repo": p["windows_repo"],
        "wsl_repo": p["wsl_repo"],
        "branch": p.get("branch", "main"),
        "head": head["stdout"].strip() if head["ok"] else None,
        "dirty": bool(status["stdout"].strip()) if status["ok"] else None,
        "status_short": status["stdout"].splitlines(),
        "diff_stat": diff_stat["stdout"].splitlines(),
        "runner_ready": wsl_test_file(p, p["ready_file"]),
        "task_file": wsl_file_summary(p, p["task_file"]),
        "report_file": wsl_file_summary(p, p["report_file"]),
    }


def default_task(p: dict[str, Any]) -> str:
    stages = load_json(STAGES, {})
    current_stage = stages.get("current_stage", "unknown")
    target_commit = stages.get("target_main_commit", "")
    return f"""你是隔离环境里的 Claude Code。请严格执行本任务；这是 Codex 监督的无人化流程：Claude 只在隔离工作区修改文件，Codex 负责测试、审查、GitHub commit/push。不要运行 Git，不要 push，不要读取凭据。

目标项目：{p['github']}
当前阶段：{current_stage}
已知目标 main commit：{target_commit}
工作目录：{p['wsl_repo']}

请先阅读：
- /home/kiro/kiro-work/work/CLAUDE.md
- {p['wsl_repo']}/CODEX_HANDOFF.json
- {p['wsl_repo']}/README.md
- {p['wsl_repo']}/docs/ROADMAP.md

安全边界：
- 只在 {p['wsl_repo']} 内修改授权文件。
- 不读取父目录、用户目录、浏览器数据、SSH/GitHub配置、API Key、.env。
- 不新增外部依赖，除非任务书明确允许。
- 不声称实现未实际落地的能力。

任务：
请根据 README、ROADMAP 和 CODEX_HANDOFF.json，提出下一阶段最小可验收切片；如上下文足够，则实现该切片并补测试与文档。若信息不足，写明需要 Codex 提供什么。

完成后必须把交付报告写入：{p['report_file']}
交付报告必须包含：修改文件、实现能力、未实现内容、建议 Codex 执行的测试、已知风险。
不要自己声明测试通过；真实测试由 Codex 执行。
"""


def run_gates(p: dict[str, Any]) -> dict[str, Any]:
    cwd = repo_path(p)
    results = []
    for cmd in p.get("test_commands", []):
        args = cmd
        if args and args[0] == "git":
            args = ["git", "-c", f"safe.directory={cwd.as_posix()}"] + args[1:]
        results.append(run_command(args, cwd=cwd, timeout=180))
    scan_args = p.get("credential_scan")
    if scan_args:
        scan = run_command(scan_args, cwd=cwd, timeout=60)
        # rg returns 1 when there are no matches. A match is a gate failure.
        scan["ok"] = scan["code"] == 1
        scan["note"] = "code 1 means no secret-shaped matches; code 0 means potential secret matches"
        results.append(scan)
    ok = all(item["ok"] for item in results)
    return {"ok": ok, "results": results}


def write_task(p: dict[str, Any], text: str) -> dict[str, Any]:
    content = text.encode("utf-8")
    res = run_command(["wsl", "-d", p["wsl_distro"], "--", "tee", p["task_file"]], timeout=30, stdin=content)
    res["stdout"] = "[suppressed task body]"
    return {"ok": res["ok"], "path": p["task_file"], "bytes": len(content), "result": res}


def read_report(p: dict[str, Any]) -> dict[str, Any]:
    res = run_command(["wsl", "-d", p["wsl_distro"], "--", "cat", p["report_file"]], timeout=30)
    return {"ok": res["ok"], "path": p["report_file"], "content": res["stdout"], "stderr": res["stderr"]}


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args: Any, **kwargs: Any) -> None:
        super().__init__(*args, directory=str(FRONTEND), **kwargs)

    def json_response(self, data: Any, status: int = 200) -> None:
        raw = json.dumps(data, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(raw)))
        self.end_headers()
        self.wfile.write(raw)

    def read_json(self) -> dict[str, Any]:
        length = int(self.headers.get("Content-Length", "0"))
        if not length:
            return {}
        return json.loads(self.rfile.read(length).decode("utf-8"))

    def do_GET(self) -> None:
        parsed = urlparse(self.path)
        if parsed.path == "/favicon.ico":
            self.send_response(HTTPStatus.NO_CONTENT)
            self.end_headers()
            return
        if parsed.path == "/api/status":
            projects = []
            for p in config().get("projects", []):
                try:
                    projects.append(project_status(p))
                except Exception as exc:
                    projects.append({"id": p.get("id"), "name": p.get("name"), "error": str(exc)})
            self.json_response({"ok": True, "at": now(), "stages": load_json(STAGES, {}), "projects": projects, "state": state()})
            return
        if parsed.path == "/api/report":
            qs = parse_qs(parsed.query)
            try:
                self.json_response(read_report(project(qs.get("project", ["cailiao"])[0])))
            except KeyError as exc:
                self.json_response({"ok": False, "error": str(exc)}, HTTPStatus.NOT_FOUND)
            return
        return super().do_GET()

    def do_POST(self) -> None:
        try:
            if urlparse(self.path).path != "/api/action":
                self.json_response({"ok": False, "error": "unsupported endpoint"}, HTTPStatus.NOT_FOUND)
                return
            payload = self.read_json()
            project_id = payload.get("project_id", "cailiao")
            p = project(project_id)
            action = payload.get("action")
            if action == "write_task":
                text = payload.get("task") or default_task(p)
                result = write_task(p, text)
            elif action == "run_gates":
                result = run_gates(p)
            elif action == "fetch":
                cwd = repo_path(p)
                result = run_command(["git", "-c", f"safe.directory={cwd.as_posix()}", "-C", str(cwd), "fetch", "origin"], timeout=120)
            elif action == "remote_main":
                cwd = repo_path(p)
                result = run_command(["git", "-c", f"safe.directory={cwd.as_posix()}", "-C", str(cwd), "ls-remote", "origin", "refs/heads/main"], timeout=60)
            elif action == "diff_stat":
                cwd = repo_path(p)
                result = run_command(["git", "-c", f"safe.directory={cwd.as_posix()}", "-C", str(cwd), "diff", "--stat"], timeout=30)
            else:
                self.json_response({"ok": False, "error": f"unsupported action: {action}"}, HTTPStatus.BAD_REQUEST)
                return
            log = write_log(project_id, action or "unknown", result)
            record_event(project_id, action or "unknown", "pass" if result.get("ok") else "fail", str(result.get("code", result.get("ok"))), log)
            result["log"] = log
            self.json_response(result)
        except KeyError as exc:
            self.json_response({"ok": False, "error": str(exc)}, HTTPStatus.NOT_FOUND)
        except Exception as exc:
            self.json_response({"ok": False, "error": str(exc)}, HTTPStatus.INTERNAL_SERVER_ERROR)


if __name__ == "__main__":
    port = int(os.getenv("WITHOUT_HUMAN_PORT", "8787"))
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as probe:
        if probe.connect_ex(("127.0.0.1", port)) == 0:
            port += 1
    server = ThreadingHTTPServer(("127.0.0.1", port), Handler)
    print(f"Without Human console: http://127.0.0.1:{port}", flush=True)
    server.serve_forever()
