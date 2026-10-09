"""Regression checks for Ghidra's successful process exit on failed imports."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

CLI = Path(__file__).resolve().parents[1] / 'scripts/nabu.py'


@unittest.skipIf(os.name == 'nt', 'uses a POSIX fake launcher')
class AnalysisOutcomeTests(unittest.TestCase):
    def run_analysis(self, output):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        root = Path(temporary.name)
        launcher = root / 'analyzeHeadless'
        launcher.write_text('#!/bin/sh\n' + output + '\n', encoding='utf-8')
        launcher.chmod(0o755)
        binary = root / 'target.bin'
        binary.write_bytes(b'test input')
        env = dict(os.environ, NABU_HOME=str(root / 'Nabu'), NABU_GHIDRA_HEADLESS=str(launcher))
        result = subprocess.run([sys.executable, str(CLI), 'analyze', str(binary), '--case', 'test'], env=env, capture_output=True, text=True)
        metadata = json.loads((root / 'Nabu/cases/test/metadata.json').read_text())
        return result, metadata

    def test_zero_exit_with_failed_import_is_rejected(self):
        result, metadata = self.run_analysis("echo 'ERROR Abort due to Headless analyzer error'")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(metadata['targets'], [])

    def test_success_records_hash(self):
        result, metadata = self.run_analysis("echo 'REPORT: Analysis succeeded'; echo 'REPORT: Import succeeded'")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(metadata['targets']), 1)
        self.assertEqual(len(metadata['targets'][0]['sha256']), 64)


if __name__ == '__main__':
    unittest.main()
