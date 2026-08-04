# Claude channel and frontend-only protocol

This document separates two concerns that must not be mixed:

1. Claude interaction: dispatching tasks, observing Claude, and sending rework instructions.
2. Codex review/publish: reading artifacts, inspecting diffs, running tests, committing, pushing, and updating progress.

## Frontend-only strict mode

When the operator requests frontend-only interaction, these rules override all bridge-script habits:

1. Claude dispatch, observation, and rework prompts must happen only through the visible Claude Code frontend/window.
2. Codex must not paste into hidden Claude sessions, write to Claude TTY, call a Claude API, or use `send-claude-task.ps1` / `send-claude-handshake.ps1` to dispatch or rework.
3. Claude Code implements. Codex does not take over implementation after a timeout or first failure. If Claude is stuck, take repeated frontend screenshots and prompt Claude from the visible window.
4. After Claude clearly delivers, Codex may enter review mode: read `CLAUDE_TO_CODEX.md`, inspect diff/status, run tests, commit, push, and update progress. These review actions are not Claude interaction.
5. If review fails, Codex must return the exact defect to Claude through the visible frontend window. Codex must not fix the implementation directly.
6. If the visible Claude frontend/window cannot be found, stop at `awaiting_visible_claude_window`. Do not use hidden dispatch, do not create the next task, do not push the current task, and do not mark progress complete.
7. The next stage may be dispatched only after the current stage is reviewed, pushed to `cailiao`, CI/actions or required gates are confirmed, and `without_human` progress is updated.

This rule exists because a missing window is a control-plane failure, not a license to switch channels. Hidden fallback made the loop look active while breaking the operator's requested interaction model.

## Review-mode allowance

Frontend-only mode does not ban Codex from reviewing a completed delivery. Once Claude has visibly claimed completion or produced a matching `CLAUDE_TO_CODEX.md`, Codex may use normal repository tools to:

- read the report;
- inspect `git status --short` and `git diff --stat`;
- review implementation diffs;
- run focused tests, full tests, quality gates, JSON checks, and `git diff --check`;
- commit and push only after review passes;
- update `without_human` progress.

These actions are allowed because they do not control Claude. They verify the delivered artifact.

## Non-frontend bridge scripts

The scripts below remain available only when the operator has not requested frontend-only interaction. They reduce fragile manual steps, but they do not let Claude push to GitHub.

```powershell
powershell -ExecutionPolicy Bypass -File scripts\check-claude-channel.ps1
```

Checks the configured project, WSL distro, Claude PID, Claude TTY, writable status, ack path, and isolated repo status. Historical setups may expect Claude PID `9` and TTY `/dev/pts/0`; verify current state before relying on it.

```powershell
powershell -ExecutionPolicy Bypass -File scripts\check-claude-cli.ps1
powershell -ExecutionPolicy Bypass -File scripts\check-claude-cli.ps1 -LiveProbe
```

Checks whether the local `claude` command exposes non-interactive `--print` and background-agent flags. `-LiveProbe` sends a minimal non-mutating prompt and reports whether auth is usable. If the live probe returns an OAuth/authentication failure, background CLI dispatch is not stable yet.

```powershell
powershell -ExecutionPolicy Bypass -File scripts\send-claude-handshake.ps1 -UseUiA
```

Writes a handshake task, focuses the verified Claude Code window, sends a one-line command, and waits for the matching `ACK <task-id>` file. Do not use this in frontend-only strict mode.

```powershell
powershell -ExecutionPolicy Bypass -File scripts\send-claude-task.ps1 -TaskPath .\path\to\task.md -UseUiA
```

Writes a long task to `CODEX_TO_CLAUDE_LATEST.md`, then sends only one short command to Claude Code. Do not use this in frontend-only strict mode.

```powershell
powershell -ExecutionPolicy Bypass -File scripts\sync-wsl-from-windows-bundle.ps1 -ProjectId cailiao
```

Synchronizes the isolated WSL repo from the verified Windows release repo without relying on WSL network or `/mnt/e`. It creates a git bundle in the Windows repo, transfers it to WSL through a binary stdin stream, verifies the bundle inside the WSL repo, stashes any dirty WSL work by default, then resets the isolated repo to the bundle head. Do not use PowerShell text pipelines, `cmd type`, or base64 through normal pipeline text for git bundles; those paths can corrupt binary bundle bytes.

## Success criteria

Do not treat command exit code or visible Claude prose as delivery success by itself. Success requires artifacts:

- `CLAUDE_TO_CODEX.md` with the expected Task ID for implementation tasks;
- relevant `git diff --stat`;
- Codex-run focused tests and full gates;
- push to `cailiao` only after review passes;
- `without_human` progress update after push/CI confirmation.

## Known edge

The normal Codex sandbox user may not see the host user's WSL registration. Use an approved host/elevated command context for review-mode checks when needed. In frontend-only strict mode, do not use that context to dispatch to Claude or send rework.

## WSL networking and Claude Web Search

Claude Code Web Search failures must be diagnosed before treating them as task failures. The tested recovery path is documented in `docs/WSL_CLAUDE_NETWORKING.md`.

Use:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\check-wsl-claude-network.ps1
```

This script is observation-only: it checks Windows proxy hints, `.wslconfig`, WSL proxy environment variables, and HTTPS reachability. It must not print secrets and must not decide that an upstream `502` is a local machine fault when WSL HTTPS probes are otherwise healthy.
