# Install RouteFix

RouteFix is a **desktop app** for macOS, Windows, and Linux.

Download the latest release: [GitHub Releases](https://github.com/MrHacker26/route-fix/releases)

| Asset | Platform |
|-------|----------|
| `RouteFix-vX.Y.Z-macos.zip` | macOS |
| `RouteFix-vX.Y.Z-windows.zip` | Windows |
| `RouteFix-vX.Y.Z-linux.tar.gz` | Linux |

> **Portable vs installed:** Current GitHub releases are portable archives (except macOS when you move the app to Applications). They do not run a system installer on Windows or Linux. See each section below for what shows up in your app menu or installed-apps list.

---

## macOS

### Install (recommended)

1. Download `RouteFix-vX.Y.Z-macos.zip` from [Releases](https://github.com/MrHacker26/route-fix/releases).
2. Double-click the zip to extract `RouteFix.app`.
3. Drag **RouteFix.app** into **Applications**.
4. Open it from **Launchpad** or **Spotlight** (`⌘ Space` → type `RouteFix`).

### First launch (Gatekeeper)

If macOS says the app is from an unidentified developer:

1. **Right-click** (or Control-click) **RouteFix.app**
2. Choose **Open**
3. Click **Open** in the dialog

Alternatively: **System Settings → Privacy & Security → Open Anyway**.

### Where it appears

| Location | After drag to Applications |
|----------|----------------------------|
| Applications folder | Yes |
| Launchpad | Yes |
| Spotlight | Yes |

### Admin password

**Prefer IPv4**, **Restore defaults**, **Flush DNS**, **Cloudflare DNS**, and other **Auto Fix** actions may ask for your macOS administrator password.

---

## Windows

### Install (current release — portable)

1. Download `RouteFix-vX.Y.Z-windows.zip`.
2. Extract the zip to a folder you keep, for example:
   - `C:\Program Files\RouteFix`
   - or `%LOCALAPPDATA%\RouteFix`
3. Run **`route_fix.exe`**.

### Shortcut (optional)

1. Right-click `route_fix.exe` → **Show more options** → **Create shortcut**
2. Move the shortcut to the **Desktop** or **Start menu** folder:
   - `%APPDATA%\Microsoft\Windows\Start Menu\Programs`

### Where it appears

| Location | Current `.zip` release |
|----------|------------------------|
| Start menu (automatic) | No |
| Settings → Installed apps | No |
| Desktop shortcut (manual) | Yes, if you create one |

> A proper **Windows installer** (`.exe` setup) would add Start menu and Installed apps entries automatically. That is not shipped in GitHub releases yet. Maintainers can build one locally — see [`BUILD.md`](BUILD.md).

### Admin / UAC

Network changes may show a **UAC** prompt (“Do you want to allow this app to make changes?”). Choose **Yes** to apply Prefer IPv4, DNS changes, flush DNS, or Restore defaults.

---

## Linux

### Install (current release — portable)

1. Download `RouteFix-vX.Y.Z-linux.tar.gz`.
2. Extract the archive:

```bash
tar -xzf RouteFix-vX.Y.Z-linux.tar.gz
cd bundle
```

3. Run the app:

```bash
./route_fix
```

### App menu entry (optional)

To show RouteFix in your desktop environment’s application menu, create a launcher file:

```bash
mkdir -p ~/.local/share/applications

cat > ~/.local/share/applications/routefix.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=RouteFix
Comment=Network routing diagnostics for developers
Exec=/full/path/to/bundle/route_fix
Icon=/full/path/to/bundle/data/flutter_assets/assets/icon/app_icon.png
Terminal=false
Categories=Network;Utility;
EOF
```

Replace `/full/path/to/bundle` with the actual path where you extracted the tarball.

Then refresh the menu (log out/in, or run `update-desktop-database ~/.local/share/applications` on some distros).

### Where it appears

| Location | Current `.tar.gz` release |
|----------|---------------------------|
| Application menu | Only if you add a `.desktop` file |
| “Installed apps” list | No (portable bundle) |

> **AppImage** builds (single file, often easier to run) are documented for maintainers in [`BUILD.md`](BUILD.md) but are not attached to GitHub releases yet.

### Admin password

Prefer IPv4, DNS changes, flush DNS, and Restore defaults use **`pkexec`** (PolicyKit) on most desktop distros. Approve the prompt and enter your password when asked.

---

## From source (developers)

```bash
git clone https://github.com/MrHacker26/route-fix.git
cd route-fix
flutter pub get
flutter run -d macos    # or windows / linux
```

Requires [Flutter stable](https://flutter.dev) with desktop enabled (Dart 3.12+).

Building release binaries, installers, and tagging releases: [`BUILD.md`](BUILD.md).

---

## Uninstall

| Platform | Steps |
|----------|--------|
| **macOS** | Move `RouteFix.app` from Applications to Trash |
| **Windows** | Delete the folder where you extracted the zip (and any shortcuts you created) |
| **Linux** | Delete the `bundle` folder; remove `~/.local/share/applications/routefix.desktop` if you added one |

RouteFix settings are stored under your user profile (for example `~/Library/Application Support/RouteFix` on macOS). Delete that folder too if you want a clean removal.

---

## Troubleshooting

| Issue | What to try |
|-------|-------------|
| macOS won’t open the app | Right-click → Open, or allow in Privacy & Security |
| Windows SmartScreen warning | Expected for unsigned builds; use “More info → Run anyway” if you trust the release |
| Linux `permission denied` | `chmod +x route_fix` inside `bundle/` |
| Fix asks for password | Required for network/DNS changes — same as changing system network settings manually |
| DNS didn’t change after Apply | VPN, corporate policy, or NetworkManager may override; use **Restore defaults** or revert in system settings |

Report bugs: [GitHub Issues](https://github.com/MrHacker26/route-fix/issues)
