# Production builds

RouteFix is **desktop-only** (macOS, Windows, Linux).

## Versioning

Use SemVer. Keep these in sync before every release:

| Location | Example |
|----------|---------|
| `pubspec.yaml` | `version: 1.0.0+1` (`+` = build number) |
| `lib/core/app_info.dart` | `version = '1.0.0'`, `build = '1'` |
| Git tag | `v1.0.0` (must start with `v`) |
| `CHANGELOG.md` | Move items under `[1.0.0]` |

Prerelease tags (`v1.0.0-rc.1`) are published as GitHub prereleases.

---

## GitHub Releases (recommended)

CI builds and uploads artifacts when you push a version tag.

```bash
# 1. Commit version + CHANGELOG bumps on main
git checkout main && git pull

# 2. Tag and push
git tag v1.0.0
git push origin v1.0.0
```

Or create the release with a custom title/notes first (workflow still attaches binaries):

```bash
gh release create v1.0.0 \
  --title "RouteFix 1.0.0" \
  --notes "First desktop release."
```

**Workflow:** `.github/workflows/release.yml` → builds on macOS / Windows / Linux runners → uploads assets.

**Current CI assets**

| File | Contents |
|------|----------|
| `RouteFix-vX.Y.Z-macos.zip` | `RouteFix.app` |
| `RouteFix-vX.Y.Z-windows.zip` | Release folder (`route_fix.exe` + DLLs) |
| `RouteFix-vX.Y.Z-linux.tar.gz` | Flutter `bundle/` |

Installers / AppImage are **not** built in CI yet — use the local steps below if you need them.

---

## Local release builds

Requirements: Flutter **stable**, desktop enabled, build on the **target OS**.

```bash
flutter pub get
flutter analyze --fatal-warnings --no-fatal-infos
flutter test
```

### macOS packaging

```bash
flutter build macos --release
```

App path:

`build/macos/Build/Products/Release/RouteFix.app`

**ZIP (same as CI):**

```bash
mkdir -p dist
ditto -c -k --sequesterRsrc --keepParent \
  build/macos/Build/Products/Release/RouteFix.app \
  dist/RouteFix-v1.0.0-macos.zip
```

**Optional DMG** (create with Disk Utility, or `create-dmg` if installed):

```bash
# Example with create-dmg (brew install create-dmg)
create-dmg \
  --volname "RouteFix" \
  --app-drop-link 600 185 \
  dist/RouteFix-v1.0.0-macos.dmg \
  build/macos/Build/Products/Release/RouteFix.app
```

**Signing / notarization:** unsigned builds may show Gatekeeper warnings. For distribution outside CI zips, use Apple Developer ID + `codesign` / `notarytool` (not configured in this repo).

> Auto Fix needs admin elevation; Release entitlements leave App Sandbox off for `networksetup`.

### Windows installer

```bash
flutter build windows --release
```

Output:

`build\windows\x64\runner\Release\` (`route_fix.exe` + dependencies)

**ZIP (same as CI):** zip the entire `Release` folder.

**Installer (Inno Setup — recommended local path):**

1. Install [Inno Setup](https://jrsoftware.org/isinfo.php).
2. Point the script at `build\windows\x64\runner\Release\`.
3. Build an installer named e.g. `RouteFix-v1.0.0-windows-setup.exe`.

Minimal `installer/windows/routefix.iss` sketch:

```iss
[Setup]
AppName=RouteFix
AppVersion=1.0.0
DefaultDirName={autopf}\RouteFix
OutputBaseFilename=RouteFix-v1.0.0-windows-setup
Compression=lzma
SolidCompression=yes

[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs

[Icons]
Name: "{autoprograms}\RouteFix"; Filename: "{app}\route_fix.exe"
Name: "{autodesktop}\RouteFix"; Filename: "{app}\route_fix.exe"
```

Compile with the Inno Setup Compiler. Code signing is optional but preferred for SmartScreen.

### Linux AppImage

```bash
flutter build linux --release
```

Bundle path:

`build/linux/x64/release/bundle/`

**tarball (same as CI):**

```bash
mkdir -p dist
tar -C build/linux/x64/release -czf dist/RouteFix-v1.0.0-linux.tar.gz bundle
```

**AppImage (local):**

1. Install [appimagetool](https://github.com/AppImage/appimagetool).
2. Build an AppDir from the Flutter bundle (binary + `lib/` sit at the bundle root):

```bash
APPDIR=dist/RouteFix.AppDir
BUNDLE=build/linux/x64/release/bundle
rm -rf "$APPDIR" && mkdir -p "$APPDIR"
cp -a "$BUNDLE/." "$APPDIR/"

cat > "$APPDIR/RouteFix.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=RouteFix
Exec=route_fix
Icon=routefix
Categories=Network;Utility;
EOF

cp assets/icon/app_icon.png "$APPDIR/routefix.png"

cat > "$APPDIR/AppRun" <<'EOF'
#!/bin/bash
HERE="$(dirname "$(readlink -f "$0")")"
export LD_LIBRARY_PATH="${HERE}/lib:${LD_LIBRARY_PATH}"
exec "${HERE}/route_fix" "$@"
EOF
chmod +x "$APPDIR/AppRun" "$APPDIR/route_fix"

appimagetool "$APPDIR" dist/RouteFix-v1.0.0-x86_64.AppImage
```
---

## Installation (end users)

See **[`docs/INSTALL.md`](INSTALL.md)** for step-by-step install instructions on macOS, Windows, and Linux (Applications folder, Start menu shortcuts, app menu, uninstall).

Quick reference:

| Platform | Steps |
|----------|--------|
| **macOS** | Unzip → drag `RouteFix.app` to Applications |
| **Windows** | Unzip → run `route_fix.exe` (portable; no installer in CI yet) |
| **Linux** | Extract tarball → run `./route_fix` from `bundle/` |

Admin password may be required for Prefer IPv4 / Restore Defaults.

### From source

```bash
git clone https://github.com/MrHacker26/route-fix.git
cd route-fix
flutter pub get
flutter run -d macos    # or windows / linux
```

---

## Checklist before tagging

- [ ] `pubspec.yaml` + `AppInfo` versions match
- [ ] `CHANGELOG.md` updated
- [ ] CI green on `main`
- [ ] Tag `vX.Y.Z` pushed (or `gh release create`)
- [ ] Release assets appear on the GitHub Release page
