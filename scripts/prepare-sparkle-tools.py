#!/usr/bin/env python3
"""Download and verify the pinned Sparkle release before exposing signing tools.

The digest is pinned from the official 2.9.6 release asset metadata, not fetched
at runtime. --archive permits offline verification and rejection tests.
"""
import argparse
import hashlib
import pathlib
import shutil
import tarfile
import tempfile
import urllib.request

VERSION = "2.9.6"
SHA256 = "52bf9e88cdd972fc0c81501377a880e90d47031bd8ca5462488f843e2609e192"
URL = f"https://github.com/sparkle-project/Sparkle/releases/download/{VERSION}/Sparkle-{VERSION}.tar.xz"


def prepare(archive=None):
    directory = pathlib.Path(tempfile.mkdtemp(prefix="macshot-sparkle-"))
    try:
        if archive is None:
            archive = directory / "release.tar.xz"
            with urllib.request.urlopen(URL, timeout=120) as response, archive.open("wb") as output:
                if not response.url.startswith("https://"):
                    raise ValueError("Sparkle download must use HTTPS")
                shutil.copyfileobj(response, output)
        digest = hashlib.sha256()
        with pathlib.Path(archive).open("rb") as source:
            for block in iter(lambda: source.read(1024 * 1024), b""):
                digest.update(block)
        if digest.hexdigest() != SHA256:
            raise ValueError("Sparkle archive SHA-256 mismatch; refusing to extract or execute it")
        tools = directory / "tools"
        with tarfile.open(archive, "r:xz") as release:
            release.extractall(tools, filter="data")
        if not (tools / "bin" / "sign_update").is_file():
            raise ValueError("Verified Sparkle release is missing bin/sign_update")
        return directory
    except BaseException:
        shutil.rmtree(directory)
        raise


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--archive", type=pathlib.Path)
    arguments = parser.parse_args()
    print(prepare(arguments.archive))
