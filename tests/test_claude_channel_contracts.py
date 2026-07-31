import pathlib
import re
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]


class ClaudeChannelContractsTest(unittest.TestCase):
    def read(self, relative):
        return (ROOT / relative).read_text(encoding="utf-8")

    def test_send_task_requires_current_task_artifact(self):
        script = self.read("scripts/send-claude-task.ps1")

        self.assertIn("[int]$PollSeconds = 2", script)
        self.assertRegex(script, r"Task ID:\\s\*\(\[A-Za-z0-9_\.:-\]\+\)")
        self.assertIn("$ReportMtimeBefore", script)
        self.assertIn('"$mtime" -gt', script)
        self.assertIn("grep -q '__TASKID__'", script)
        self.assertIn("observed_kind", script)
        self.assertIn("matching_report", script)
        self.assertIn("matching_ack", script)
        self.assertIn("wsl_diff", script)
        self.assertIn("ShowWindow", script)
        self.assertIn("GetForegroundWindow", script)
        self.assertIn("Claude paste verification failed", script)
        self.assertIn("$SentVerified", script)
        self.assertIn("ConvertTo-Base64Utf8", script)
        self.assertIn("Invoke-WslBash", script)
        self.assertIn('replace "`r`n", "`n"', script)

    def test_cli_probe_documents_non_interactive_path(self):
        script = self.read("scripts/check-claude-cli.ps1")

        self.assertIn("Get-Command claude", script)
        self.assertIn("claude --help", script)
        self.assertIn("--print", script)
        self.assertIn("non-interactive", script)
        self.assertIn("LiveProbe", script)
        self.assertIn("authentication failed or expired", script)
        self.assertIn("candidate_for_background_dispatch", script)
        self.assertIn("usable_for_background_dispatch", script)
        self.assertIn("$LiveProbe -and $Status.live_probe.ok", script)

    def test_docs_explain_cli_probe_before_uia(self):
        docs = self.read("docs/CLAUDE_CHANNEL_SCRIPTS.md")

        self.assertIn("check-claude-cli.ps1", docs)
        self.assertIn("-LiveProbe", docs)
        self.assertIn("OAuth", docs)
        self.assertIn("UseUiA", docs)

    def test_docs_enforce_frontend_only_strict_mode(self):
        docs = self.read("docs/CLAUDE_CHANNEL_SCRIPTS.md")

        self.assertIn("Frontend-only strict mode", docs)
        self.assertIn("visible Claude Code frontend/window", docs)
        self.assertIn("must not paste into hidden Claude sessions", docs)
        self.assertIn("write to Claude TTY", docs)
        self.assertIn("Codex does not take over implementation", docs)
        self.assertIn("awaiting_visible_claude_window", docs)
        self.assertIn("Do not use hidden dispatch", docs)
        self.assertIn("must return the exact defect to Claude through the visible frontend window", docs)
        self.assertIn("The next stage may be dispatched only after", docs)

    def test_readme_frontend_loop_matches_strict_mode(self):
        readme = self.read("README.md")

        self.assertIn("前端严格循环", readme)
        self.assertIn("可见 Claude Code 前端窗口", readme)
        self.assertIn("awaiting_visible_claude_window", readme)
        self.assertIn("不得改用隐藏 TTY、WSL、API 或脚本继续派发/返工", readme)
        self.assertIn("审核不通过", readme)
        self.assertIn("Codex 不直接接管实现", readme)
        self.assertIn("只有当前阶段完成、推送、Actions/门禁确认", readme)


if __name__ == "__main__":
    unittest.main()
