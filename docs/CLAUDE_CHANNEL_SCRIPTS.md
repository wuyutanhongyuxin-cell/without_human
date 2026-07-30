# Claude channel scripts

The operating model remains two CLI sessions:

```text
1. Codex CLI session: controller/reviewer/publisher
2. Claude Code CLI session: isolated implementer
```

The scripts only reduce fragile manual steps. They do not remove the Claude Code CLI and do not let Claude push to GitHub.

## Scripts

```powershell
powershell -ExecutionPolicy Bypass -File scripts\check-claude-channel.ps1
```

Checks the configured project, WSL distro, Claude PID, Claude TTY, writable status, ack path, and isolated repo status. In the current setup it expects Claude PID `9` and TTY `/dev/pts/0`.

```powershell
powershell -ExecutionPolicy Bypass -File scripts\check-claude-cli.ps1
powershell -ExecutionPolicy Bypass -File scripts\check-claude-cli.ps1 -LiveProbe
```

Checks whether the local `claude` command exposes non-interactive `--print` and background-agent flags. `-LiveProbe` sends a minimal non-mutating prompt and reports whether auth is usable. If the live probe returns an OAuth/authentication failure, background CLI dispatch is not stable yet; keep using the TTY/UIA bridge until the Claude account is reauthenticated.

```powershell
powershell -ExecutionPolicy Bypass -File scripts\send-claude-handshake.ps1 -UseUiA
```

Writes a handshake task, focuses the verified Claude Code window, sends a one-line command, and waits for the matching `ACK <task-id>` file.

```powershell
powershell -ExecutionPolicy Bypass -File scripts\send-claude-task.ps1 -TaskPath .\path\to\task.md -UseUiA
```

Writes a long task to `CODEX_TO_CLAUDE_LATEST.md`, then sends only one short command to Claude Code. Use `-UseUiA` when direct TTY writes do not produce ack/report artifacts.

```powershell
powershell -ExecutionPolicy Bypass -File scripts\sync-wsl-from-windows-bundle.ps1 -ProjectId cailiao
```

Synchronizes the isolated WSL repo from the verified Windows release repo without relying on WSL network or `/mnt/e`. It creates a git bundle in the Windows repo, transfers it to WSL through a binary stdin stream, verifies the bundle inside the WSL repo, stashes any dirty WSL work by default, then resets the isolated repo to the bundle head. Do not use PowerShell text pipelines, `cmd type`, or base64 through normal pipeline text for git bundles; those paths can corrupt binary bundle bytes.

## Success criteria

Do not treat command exit code as delivery success. Success requires an artifact:

- `CLAUDE_ACK_FROM_CODEX.txt` for handshake tasks;
- `CLAUDE_TO_CODEX.md` with the expected Task ID for implementation tasks;
- relevant `git diff --stat`;
- Codex-run quality gates.

## Known edge

The normal Codex sandbox user may not see the host user's WSL registration. Use an approved host/elevated command context for these scripts when checking `KiroUbuntu` or interacting with the Claude Code window.
