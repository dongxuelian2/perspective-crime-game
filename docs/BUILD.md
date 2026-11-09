# Building A Letter to Nowhere

## Play a packaged release

Unzip the complete package first. No Godot installation, account, network
connection, or additional asset download is needed to play.

- **Linux x86_64:** run `play.sh` (or `./ALetterToNowhere.x86_64`). If the
  extraction tool dropped executable permissions, run
  `chmod +x play.sh ALetterToNowhere.x86_64` first.
- **Windows x86_64:** open `ALetterToNowhere.exe`. Keep
  `ALetterToNowhere.pck` beside the executable. This independent build is
  unsigned. A successful Windows export is not a Windows runtime test.
- Both packages use Godot's Compatibility renderer and require OpenGL 3.3
  support. See the main README for the Linux environment actually tested.

For controls and the current graphical testing record, see [README.md](../README.md).

## Reproduce the desktop exports

The automated build host is **Linux** with Python 3.9+, `curl`, and the official
standard (non-.NET) **Godot 4.6.3 stable** editor available as `godot`. The engine
version used during development is `4.6.3.stable.official.7d41c59c4`.

From a clean clone:

```sh
python3 tools/build.py --install-templates
```

The initial run downloads the official 4.6.3 export-template archive (about
1.2 GB), verifies its pinned SHA-512 against Godot's release checksum, and
installs just the Linux/Windows x86_64 templates into the output directory.
The installed desktop templates occupy about 333 MiB. Subsequent runs can use:

```sh
python3 tools/build.py
```

The default output is `../perspective-crime-builds`, outside the repository.
Do not commit generated executables, PCK files, ZIPs, engine downloads, or caches.

Options:

```sh
# Use a specific editor binary and external output directory.
python3 tools/build.py --godot /path/to/godot --output /path/to/builds --install-templates

# Reuse an already downloaded official archive, still verifying its checksum.
python3 tools/build.py --template-archive /path/to/Godot_v4.6.3-stable_export_templates.tpz

# Export one target only after templates have been installed.
python3 tools/build.py --platform linux
python3 tools/build.py --platform windows
```

The script imports assets, exports release builds from the tracked
`export_presets.cfg`, packages credits and licenses, and writes:

- `ALetterToNowhere-linux-x86_64.zip`
- `ALetterToNowhere-windows-x86_64.zip`
- Adjacent `.zip.sha256` checksums
- `import.log`, `export-linux.log`, `export-windows.log`, and `engine.log`

Each ZIP includes `BUILD_INFO.json` with the exact engine version, source-content
hash, Git revision and dirty state, and hashes of its packaged files. An export
from uncommitted work is labeled as such; the recorded revision is not presented
as the full source state. The archive timestamps are normalized, but bit-for-bit
identity across machines is not promised by Godot's import/export pipeline.

The script checks engine version and fails on reported import/export errors. It
does not substitute for the gameplay regression tests or graphical playtesting.
Follow the test commands in the main README before distribution.

## Godot editor export

On a Linux or Windows development computer, install Godot 4.6.3, import
`project.godot`, then use **Editor > Manage Export Templates** to install the
matching standard templates. **Project > Export** includes the tracked
`Linux x86_64` and `Windows x86_64` release presets. Export into an external
directory. Keep the `.pck` next to the executable and include the asset credits,
font license, and Godot license/copyright notices if distributing an export by
hand. The Python build script handles these packaging steps automatically.

## Upstream provenance

- [Godot 4.6.3 official release](https://github.com/godotengine/godot-builds/releases/tag/4.6.3-stable)
- [Official export-template archive](https://github.com/godotengine/godot-builds/releases/download/4.6.3-stable/Godot_v4.6.3-stable_export_templates.tpz)
- [Official SHA-512 checksums](https://github.com/godotengine/godot-builds/releases/download/4.6.3-stable/SHA512-SUMS.txt)
- [Godot license](https://github.com/godotengine/godot/blob/4.6.3-stable/LICENSE.txt)
- [Godot third-party notices](https://github.com/godotengine/godot/blob/4.6.3-stable/COPYRIGHT.txt)

The latter two are reproduced in `third_party/` and included in each ZIP.
Project art, font, and sound provenance is in [assets/CREDITS.md](../assets/CREDITS.md).
