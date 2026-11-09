#!/usr/bin/env python3
"""Build offline Linux/Windows x86_64 release ZIPs with Godot 4.6.3."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import zipfile

from install_export_templates import ARCHIVE_NAME, MEMBERS, VERSION, install

ROOT = Path(__file__).resolve().parents[1]
PRODUCT = "ALetterToNowhere"
PLATFORMS = {
    "linux": ("Linux x86_64", "linux-x86_64", PRODUCT + ".x86_64"),
    "windows": ("Windows x86_64", "windows-x86_64", PRODUCT + ".exe"),
}


def run(command, log: Path, env) -> str:
    print("Running: " + " ".join(str(item) for item in command), flush=True)
    result = subprocess.run(command, cwd=ROOT, env=env, text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    log.write_text(result.stdout, encoding="utf-8")
    plain_log = re.sub(r"\x1b\[[0-?]*[ -/]*[@-~]", "", result.stdout)
    if result.returncode or any(line.lstrip().startswith(("ERROR:", "SCRIPT ERROR:"))
                                for line in plain_log.splitlines()):
        print(result.stdout)
        raise RuntimeError(f"Build command failed; inspect {log}")
    return result.stdout


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def source_state():
    # Include uncommitted implementation/assets, not only the previous commit.
    paths = sorted(path for path in ROOT.rglob("*") if path.is_file() and not any(
        component in {".git", ".godot", "__pycache__", "builds"}
        for component in path.relative_to(ROOT).parts))
    digest = hashlib.sha256()
    for path in paths:
        digest.update(path.relative_to(ROOT).as_posix().encode() + b"\0")
        digest.update(bytes.fromhex(sha256(path)))
    commit = subprocess.run(["git", "rev-parse", "HEAD"], cwd=ROOT,
                            capture_output=True, text=True)
    status = subprocess.run(["git", "status", "--porcelain"], cwd=ROOT,
                            capture_output=True, text=True)
    return {
        "source_sha256": digest.hexdigest(),
        "git_commit": commit.stdout.strip() if commit.returncode == 0 else None,
        "uncommitted_changes": bool(status.stdout) if status.returncode == 0 else None,
    }


def package(platform, folder: Path, output: Path, engine_version: str, source):
    preset, label, executable = PLATFORMS[platform]
    if not (folder / executable).is_file() or not (folder / (PRODUCT + ".pck")).is_file():
        raise RuntimeError(f"Export is incomplete: {folder}")
    if platform == "linux":
        (folder / executable).chmod(0o755)
        launcher = folder / "play.sh"
        launcher.write_text(
            '#!/bin/sh\nset -eu\ncd -- "$(dirname -- "$0")"\n'
            f'exec "./{executable}" "$@"\n', encoding="utf-8")
        launcher.chmod(0o755)
        start = "Extract the entire ZIP, then double-click play.sh or run ./play.sh.\n"
        start += "If needed: chmod +x play.sh " + executable + "\n"
        start += "Requires a Linux x86_64 desktop with OpenGL 3.3 support.\n"
    else:
        start = "Extract the entire ZIP, then open " + executable + ".\n"
        start += "Keep the .pck file beside the .exe. No Godot installation is needed.\n"
        start += "Requires Windows x86_64 and OpenGL 3.3 graphics support.\n"
        start += "This independent build is unsigned and Windows runtime testing is not claimed.\n"
    (folder / "START_HERE.txt").write_text(
        "A LETTER TO NOWHERE\nA Perspective Crime game\n\n" + start
        + "\nCONTROLS\n"
        + "Click Enter the city to begin or resume at the saved district.\n"
        + "Drag brass grips to rotate streets or slide a facade.\n"
        + "Click glowing landings to walk along reachable paths.\n"
        + "The brass pin in the final district holds a linked street still.\n"
        + "Restart district: R. Sound: M. Help: ?. Close help: Esc.\n"
        + "Replay is available after the ending comic.\n"
        + "\nThe experience runs completely offline.\n"
        + "Read SOURCE_README.md for the full controls, credits, and tested-platform limits.\n"
        + "\nEngine: " + engine_version + "\n", encoding="utf-8")
    shutil.copy2(ROOT / "README.md", folder / "SOURCE_README.md")
    licenses = folder / "licenses"
    licenses.mkdir()
    for name in ("GODOT_LICENSE.txt", "GODOT_COPYRIGHT.txt"):
        shutil.copy2(ROOT / "third_party" / name, licenses / name)
    shutil.copy2(ROOT / "assets/fonts/LICENSE.txt", licenses / "DEJAVU_LICENSE.txt")
    for source_license in (ROOT / "assets/audio/licenses").glob("*.txt"):
        shutil.copy2(source_license, licenses / source_license.name)
    shutil.copy2(ROOT / "assets/CREDITS.md", folder / "ASSET_CREDITS.md")
    manifest = dict(source, title="A Letter to Nowhere", project="Perspective Crime",
                    platform=label, engine=engine_version, export_preset=preset,
                    files={path.relative_to(folder).as_posix(): sha256(path)
                           for path in sorted(folder.rglob("*")) if path.is_file()})
    (folder / "BUILD_INFO.json").write_text(json.dumps(manifest, indent=2) + "\n",
                                            encoding="utf-8")
    archive = output / (PRODUCT + "-" + label + ".zip")
    temporary = archive.with_suffix(".zip.partial")
    with zipfile.ZipFile(temporary, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as bundle:
        for path in sorted(folder.rglob("*")):
            if path.is_file():
                entry = zipfile.ZipInfo(PRODUCT + "-" + label + "/" + path.relative_to(folder).as_posix(),
                                        date_time=(2026, 1, 1, 0, 0, 0))
                entry.create_system = 3
                entry.external_attr = (path.stat().st_mode & 0xFFFF) << 16
                entry.compress_type = zipfile.ZIP_DEFLATED
                bundle.writestr(entry, path.read_bytes(), compresslevel=9)
    temporary.replace(archive)
    checksum = sha256(archive)
    archive.with_suffix(".zip.sha256").write_text(checksum + "  " + archive.name + "\n")
    print(f"Packaged: {archive} ({archive.stat().st_size / 1024 / 1024:.1f} MiB)", flush=True)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default=os.environ.get("GODOT", "godot"))
    parser.add_argument("--output", type=Path, default=ROOT.parent / "perspective-crime-builds")
    parser.add_argument("--platform", choices=("all", "linux", "windows"), default="all")
    parser.add_argument("--template-archive", type=Path)
    parser.add_argument("--install-templates", action="store_true",
                        help="Download/verify/install official templates if missing")
    args = parser.parse_args()
    output = args.output.resolve()
    # Artifacts/caches must not pollute the Godot project or exported resource set.
    if output == ROOT or ROOT in output.parents:
        parser.error("--output must be outside the repository")
    output.mkdir(parents=True, exist_ok=True)
    data_home = output / ".godot-data"
    template_folder = data_home / "godot/export_templates" / VERSION
    if not all((template_folder / name).is_file() for name in MEMBERS):
        if not (args.install_templates or args.template_archive):
            parser.error("Missing local templates. Use --install-templates for the official download, "
                         "or --template-archive /path/to/Godot_v4.6.3-stable_export_templates.tpz")
        install(args.template_archive or output / "downloads" / ARCHIVE_NAME, data_home)
    env = dict(os.environ, XDG_DATA_HOME=str(data_home),
               XDG_CONFIG_HOME=str(output / ".godot-config"),
               XDG_CACHE_HOME=str(output / ".godot-cache"), GODOT_SILENCE_ROOT_WARNING="1")
    for key in ("XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"):
        Path(env[key]).mkdir(parents=True, exist_ok=True)
    engine_version = run([args.godot, "--version"], output / "engine.log", env).strip()
    if not engine_version.startswith(VERSION + "."):
        parser.error("Expected Godot " + VERSION + "; found " + engine_version)
    run([args.godot, "--headless", "--path", str(ROOT), "--editor", "--import", "--quit"],
        output / "import.log", env)
    source = source_state()
    platforms = PLATFORMS if args.platform == "all" else [args.platform]
    for platform in platforms:
        preset, label, executable = PLATFORMS[platform]
        # Export into a fresh staging directory so stale files never enter ZIPs.
        with tempfile.TemporaryDirectory(prefix="export-" + platform + "-", dir=output) as staging:
            folder = Path(staging)
            run([args.godot, "--headless", "--path", str(ROOT), "--export-release", preset,
                 str(folder / executable)], output / ("export-" + platform + ".log"), env)
            if source_state()["source_sha256"] != source["source_sha256"]:
                raise RuntimeError("Sources changed during export. Let edits finish, then rebuild.")
            package(platform, folder, output, engine_version, source)
    print("Exports complete. ZIP hashes are in the adjacent .sha256 files.")
    print("An export succeeding is not a Windows runtime test.")


if __name__ == "__main__":
    main()
