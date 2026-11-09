#!/usr/bin/env python3
"""Install checksum-pinned official Godot desktop export templates locally."""

import argparse
import hashlib
from pathlib import Path
import shutil
import subprocess
import zipfile

VERSION = "4.6.3.stable"
ARCHIVE_NAME = "Godot_v4.6.3-stable_export_templates.tpz"
URL = "https://github.com/godotengine/godot-builds/releases/download/4.6.3-stable/" + ARCHIVE_NAME
# Published in SHA512-SUMS.txt beside the official 4.6.3 release.
SHA512 = (
    "da606b61c10157844f8300172df374472665f95015495cb1a7cd132c40ede404faa9"
    "6cc1016a4b9662db9909ddea69632c4948b2cd11163438dad4808881fb68"
)
MEMBERS = (
    "version.txt",
    "linux_debug.x86_64", "linux_release.x86_64",
    "windows_debug_x86_64.exe", "windows_debug_x86_64_console.exe",
    "windows_release_x86_64.exe", "windows_release_x86_64_console.exe",
)


def install(archive: Path, data_home: Path) -> Path:
    """Download if absent, verify the whole archive, extract only safe members."""
    archive = archive.resolve()
    if not archive.is_file():
        archive.parent.mkdir(parents=True, exist_ok=True)
        partial = archive.with_suffix(archive.suffix + ".partial")
        print(f"Downloading official templates (about 1.2 GB): {URL}", flush=True)
        subprocess.run([
            "curl", "--fail", "--location", "--retry", "2", "--proto", "=https",
            "--tlsv1.2", URL, "--output", str(partial),
        ], check=True)
        partial.replace(archive)
    print(f"Verifying SHA-512: {archive}", flush=True)
    hasher = hashlib.sha512()
    with archive.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            hasher.update(chunk)
    if hasher.hexdigest() != SHA512:
        raise RuntimeError(f"Template checksum mismatch; do not use {archive}.")
    destination = data_home.resolve() / "godot" / "export_templates" / VERSION
    destination.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(archive) as bundle:
        if bundle.read("templates/version.txt").decode().strip() != VERSION:
            raise RuntimeError("Unexpected Godot export template version.")
        for name in MEMBERS:
            target = destination / name
            temporary = target.with_suffix(target.suffix + ".partial")
            with bundle.open("templates/" + name) as source, temporary.open("wb") as output:
                shutil.copyfileobj(source, output)
            temporary.replace(target)
            if name.startswith("linux_"):
                target.chmod(0o755)
    print(f"Verified desktop export templates installed: {destination}", flush=True)
    return destination


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--archive", type=Path, required=True,
                        help="Download/cache location for the official .tpz archive")
    parser.add_argument("--data-home", type=Path, required=True,
                        help="Godot data directory, used as XDG_DATA_HOME during export")
    args = parser.parse_args()
    install(args.archive, args.data_home)


if __name__ == "__main__":
    main()
