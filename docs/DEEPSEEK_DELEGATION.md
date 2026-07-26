# DeepSeek delegation

This project keeps the two-CLI operating model:

```text
Codex CLI: orchestration, verification, git, GitHub, quality gates
Claude Code CLI: isolated implementation workspace
```

Scripts do not replace either CLI. They only automate the mechanical bridge:

- write the long task to `CODEX_TO_CLAUDE_LATEST.md`;
- send one short command to the verified Claude Code window;
- wait for ack/report/diff artifacts.

## Where DeepSeek fits

DeepSeek is a Codex-side helper for low-risk, non-authoritative work. It is not a third committer and it does not talk to Claude directly.

Allowed examples:

- summarize a long handoff or diff for Codex review;
- draft a task outline from already-public project context;
- rewrite documentation text;
- classify a task as simple/complex;
- propose test cases for Codex to inspect.

Not allowed:

- read or handle credentials;
- push, commit, or modify repositories;
- declare tests passed;
- decide security-sensitive changes;
- replace Codex review or GitHub Actions;
- receive private material unless the user has explicitly allowed that data flow.

## Credential boundary

For unattended use, `DEEPSEEK_API_KEY` must be available to the Codex-side process environment, but it must stay outside this repository.

Supported environment variables:

```powershell
$env:DEEPSEEK_API_KEY = "..."
$env:DEEPSEEK_MODEL = "deepseek-v4-flash"
$env:DEEPSEEK_BASE_URL = "https://api.deepseek.com"
```

The script `scripts/invoke-deepseek-task.ps1` reads those variables and calls the OpenAI-compatible `/chat/completions` endpoint. It does not write the key to disk.

## Usage

```powershell
powershell -ExecutionPolicy Bypass -File scripts\invoke-deepseek-task.ps1 `
  -PromptPath .\scratch\simple-summary-task.md `
  -OutputPath .\scratch\deepseek-result.md
```

The delegated prompt should include only the context DeepSeek is allowed to see. If the task needs repository writes, tests, credentials, or high-risk judgment, the script's system prompt instructs DeepSeek to return `ESCALATE_TO_CODEX`.

## Unattended rule

Fully unattended operation is possible only after one-time credential provisioning outside Git, such as a user environment variable or a launcher-provided environment. If the key is absent, the script fails closed.
