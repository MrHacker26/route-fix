<p align="center">
  <img src="assets/icon/app_icon.png" alt="RouteFix logo" width="128" height="128">
</p>

<h1 align="center">RouteFix</h1>

<p align="center">
  <strong>Diagnose why developer services feel slow — even when your bandwidth is fine.</strong>
</p>

<p align="center">
  <a href="https://github.com/MrHacker26/route-fix/actions/workflows/ci.yml"><img src="https://github.com/MrHacker26/route-fix/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-Desktop-02569B?style=flat-square&logo=flutter&logoColor=white" alt="Flutter Desktop"></a>
  <img src="https://img.shields.io/badge/target-Desktop-111827?style=flat-square" alt="Desktop target">
  <img src="https://img.shields.io/badge/Dart-3.12%2B-0175C2?style=flat-square&logo=dart&logoColor=white" alt="Dart">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue?style=flat-square" alt="MIT License"></a>
  <a href="https://github.com/MrHacker26/route-fix/releases"><img src="https://img.shields.io/github/v/release/MrHacker26/route-fix?style=flat-square&include_prereleases&label=release" alt="Release"></a>
</p>

<p align="center">
  Local desktop app for <em>network routing</em> diagnostics.<br>
  macOS · Windows · Linux · <strong>Not a speed test.</strong>
</p>

<p align="center">
  <img src="assets/screenshots/dashboard.png" alt="RouteFix dashboard" width="920">
</p>

---

## Features

- DNS, IPv4/IPv6, HTTPS, GitHub, PyPI, and Cloudflare probes
- Evidence-gated recommendations (no invented metrics)
- Prefer IPv4 Auto Fix + Restore Defaults (admin required)
- Network Controls for manual IPv6 preference
- Dark Material 3 UI

---

## Install

**Releases:** [GitHub Releases](https://github.com/MrHacker26/route-fix/releases)  
(`RouteFix-v*-macos.zip` / `windows.zip` / `linux.tar.gz`)

**From source:**

```bash
git clone https://github.com/MrHacker26/route-fix.git
cd route-fix
flutter pub get
flutter run -d macos    # or windows / linux
```

```bash
flutter build macos --release
flutter build windows --release
flutter build linux --release
```

Requires Flutter stable with desktop enabled (Dart 3.12+).

---

## Screenshots

| Scanning | Results |
|:--------:|:-------:|
| <img src="assets/screenshots/scanning.png" alt="Scan in progress" width="420"> | <img src="assets/screenshots/result.png" alt="Diagnostics result" width="420"> |

<p align="center">
  <img src="assets/screenshots/auto-fix.png" alt="Auto Fix" width="720">
</p>

---

## How it works

1. Probe public endpoints (DNS / TCP / HTTPS)
2. Score health and list issues with evidence
3. Recommend fixes only when confidence is high
4. Optionally apply Prefer IPv4 (admin password required)

---

## Privacy

Runs locally. No telemetry. Traffic only goes to endpoints you diagnose, plus OS commands for Auto Fix.

---

## Contributing

PRs welcome. Keep diagnosis honest — prefer **Unknown** over a wrong fix.

See [`PROJECT.md`](PROJECT.md), [`CHANGELOG.md`](CHANGELOG.md), [`SECURITY.md`](SECURITY.md).

Release: bump version → tag `vX.Y.Z` → push (GitHub Actions publishes binaries).

---

## License

[MIT](LICENSE)
