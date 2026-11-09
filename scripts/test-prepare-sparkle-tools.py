import hashlib
import importlib.util
import io
import json
import pathlib
import shutil
import tarfile
import tempfile
import unittest
from unittest import mock

spec = importlib.util.spec_from_file_location("sparkle_tools", pathlib.Path(__file__).with_name("prepare-sparkle-tools.py"))
tools = importlib.util.module_from_spec(spec)
spec.loader.exec_module(tools)


class SigningToolVerificationTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.archive = pathlib.Path(self.directory.name) / "fixture.tar.xz"

    def make_archive(self, name="bin/sign_update"):
        with tarfile.open(self.archive, "w:xz") as archive:
            entry = tarfile.TarInfo(name)
            entry.size = 4
            archive.addfile(entry, io.BytesIO(b"tool"))
        return hashlib.sha256(self.archive.read_bytes()).hexdigest()

    def test_release_tools_match_the_locked_runtime_version(self):
        root = pathlib.Path(__file__).resolve().parents[1]
        lock = root / "macshot.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
        pins = json.loads(lock.read_text())["pins"]
        runtime = next(pin for pin in pins if pin["identity"] == "sparkle")
        self.assertEqual(runtime["state"]["version"], tools.VERSION)

    def test_matching_archive_exposes_signing_tool(self):
        digest = self.make_archive()
        with mock.patch.object(tools, "SHA256", digest):
            result = tools.prepare(self.archive)
        self.addCleanup(shutil.rmtree, result)
        self.assertEqual((result / "tools/bin/sign_update").read_bytes(), b"tool")

    def test_checksum_mismatch_never_reaches_extraction(self):
        self.make_archive()
        with mock.patch.object(tools.tarfile, "open") as extract:
            with self.assertRaisesRegex(ValueError, "SHA-256 mismatch"):
                tools.prepare(self.archive)
            extract.assert_not_called()

    def test_tampering_with_verified_bytes_is_rejected(self):
        digest = self.make_archive()
        self.archive.write_bytes(self.archive.read_bytes() + b"tampered")
        with mock.patch.object(tools, "SHA256", digest):
            with self.assertRaisesRegex(ValueError, "SHA-256 mismatch"):
                tools.prepare(self.archive)

    def test_missing_tool_fails_closed(self):
        digest = self.make_archive("unexpected/file")
        with mock.patch.object(tools, "SHA256", digest):
            with self.assertRaisesRegex(ValueError, "missing bin/sign_update"):
                tools.prepare(self.archive)

    def test_archive_path_escape_is_rejected_even_with_matching_digest(self):
        digest = self.make_archive("../escaped-tool")
        with mock.patch.object(tools, "SHA256", digest):
            with self.assertRaises(tarfile.FilterError):
                tools.prepare(self.archive)

    def test_failed_verification_removes_its_temporary_directory(self):
        self.make_archive()
        working = pathlib.Path(self.directory.name) / "working"
        working.mkdir()
        with mock.patch.object(tools.tempfile, "mkdtemp", return_value=str(working)):
            with self.assertRaises(ValueError):
                tools.prepare(self.archive)
        self.assertFalse(working.exists())


if __name__ == "__main__":
    unittest.main()
