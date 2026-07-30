import pathlib
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]


class CailiaoCycleContractsTest(unittest.TestCase):
    def read(self, relative):
        return (ROOT / relative).read_text(encoding="utf-8")

    def test_cycle_defaults_to_cli_session_to_session(self):
        script = self.read("scripts/run-cailiao-cycle.ps1")

        self.assertIn("[switch]$UseUiA", script)
        self.assertIn("cli_session_to_session = -not [bool]$UseUiA", script)
        self.assertIn("send-claude-task.ps1", script)
        self.assertIn("observed_kind -eq \"none\"", script)
        self.assertIn("Claude produced no matching ack/report/diff", script)
        self.assertIn("quality_gates", script)
        self.assertIn("tools\\run_quality_gates.py", script)
        self.assertIn("check-cailiao-roadmap-guard.ps1", script)
        self.assertIn("sync-wsl-from-windows-bundle.ps1", script)
        self.assertIn("gh run watch", script)
        self.assertIn("tmp\\cycles", script)
        self.assertIn("Pass -Push to publish", script)

    def test_roadmap_guard_hard_codes_real_stage2b_blockers(self):
        script = self.read("scripts/check-cailiao-roadmap-guard.ps1")

        self.assertIn("stage2b-real-query-set", script)
        self.assertIn("stage2b-real-bm25-calibration", script)
        self.assertIn("stage2b-real-vector-provider-index", script)
        self.assertIn("stage2b-real-reranker-rrf", script)
        self.assertIn("stage2b-real-nli-llm-conflict-evidence", script)
        self.assertIn("StartsWith(\"- [ ]\")", script)
        self.assertIn('"roadmap_parent_items_checked"\\s*:\\s*true', script)
        self.assertIn('"ready_for_stage2b_completion"\\s*:\\s*true', script)
        self.assertIn("exit 1", script)

    def test_status_dashboard_reads_roadmap_handoff_and_ci(self):
        script = self.read("scripts/get-cailiao-status.ps1")

        self.assertIn("docs\\ROADMAP.md", script)
        self.assertIn("CODEX_HANDOFF.json", script)
        self.assertIn("open_roadmap_items", script)
        self.assertIn("gh run list", script)
        self.assertIn("[switch]$IncludeCi", script)
        self.assertIn("next_step", script)
        self.assertIn("Stage 2B real external evidence remains blocked", script)


if __name__ == "__main__":
    unittest.main()
