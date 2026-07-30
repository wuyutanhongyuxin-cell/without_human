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


if __name__ == "__main__":
    unittest.main()
