# WSL Claude Networking Runbook

This runbook records the tested recovery path for Claude Code running inside an isolated WSL environment when Web Search or outbound HTTPS becomes unreliable.

## What Happened

Observed symptoms:

- Claude Code could run in the visible frontend window, but Web Search returned intermittent `502 Upstream service temporarily unavailable` errors from the configured inference/search gateway.
- WSL direct networking was partially usable: some public hosts responded, while Google or other routes timed out.
- Windows v2rayN/xray was running on `127.0.0.1:10811`.
- The isolated WSL environment did not inherit the Windows proxy and could not reach Windows loopback in the old NAT-style setup.

The important distinction:

- If WSL cannot reach the proxy, local configuration is incomplete.
- If WSL can browse normally but Claude Web Search still returns `502`, the likely failure is the upstream search/gateway service, not the local machine.

## Preferred Fix

Use official WSL mirrored networking and automatic proxy import instead of exposing the proxy to the LAN.

Create or update:

```text
C:\Users\<user>\.wslconfig
```

with:

```ini
[wsl2]
networkingMode=mirrored
autoProxy=true
dnsTunneling=true
firewall=true
```

Then restart WSL:

```powershell
wsl --shutdown
```

Reopen Claude Code from the normal launcher. If the Claude auth/key is intentionally not persisted, the operator may need to re-enter it after the WSL restart.

## Safety Notes

Prefer this path:

```text
WSL mirrored networking + autoProxy
```

over this path:

```text
v2rayN "Allow LAN" / listen on 0.0.0.0
```

Reasons:

- Mirrored networking keeps the intent scoped to WSL using the Windows network stack.
- `autoProxy=true` follows the Windows system proxy instead of hard-coding secrets or proxy credentials.
- It avoids broadly exposing a local proxy service to the physical LAN.

If mirrored networking is unavailable and a port bridge is required, bind it only to the WSL host address and restrict the firewall to the WSL subnet. Do not open the proxy to `0.0.0.0` without an explicit operator decision.

## Verification

After reopening WSL/Claude Code, run from the same WSL environment where Claude runs:

```bash
env | grep -i proxy || true
curl -I --max-time 20 https://github.com
curl -I --max-time 20 https://www.google.com
curl -I --max-time 20 https://sub.flash-l.cloud
```

Then ask Claude Code to use Web Search on a time-sensitive query. A successful live result confirms the Claude-side search tool path is restored.

## Operator Rule

Codex may help configure WSL networking only with an explicit operator request and only by using the official WSL/user configuration path or a narrowly scoped firewall/portproxy rule.

Codex must not:

- extract Claude API keys from process environments;
- write secrets into `.wslconfig`, task files, logs, or Git;
- connect Claude to a host browser/account session;
- broadly expose a local proxy to the LAN as a convenience shortcut.

## Troubleshooting Matrix

| Symptom | Likely Cause | Next Step |
|---|---|---|
| `env | grep -i proxy` is empty after restart | Windows system proxy is disabled or WSL autoProxy did not import it | Enable Windows/v2rayN system proxy, then `wsl --shutdown` again |
| `curl https://github.com` works but Google times out | Route filtering or no proxy path for that destination | Confirm mirrored networking is active and Windows proxy is enabled |
| `curl https://sub.flash-l.cloud` works but Web Search returns `502` | Upstream gateway/search service issue | Retry later or use Codex-side verification as fallback |
| WSL distribution disappears from normal sandbox view | User/session boundary between sandbox and host WSL registration | Use approved host/elevated checks for observation only |
| Claude Code asks for login after restart | Auth is not persisted by design | Operator re-enters auth/key through the trusted launcher |
