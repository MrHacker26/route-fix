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
  RouteFix is a local desktop app for <em>network routing</em> diagnostics.<br>
  It is <strong>not</strong> a speed test.
</p>

<p align="center">
  <img src="assets/screenshots/dashboard.png" alt="RouteFix dashboard" width="920">
</p>

---

## Features

- **Routing-focused diagnosis** — DNS, dual-stack TCP, TLS/HTTPS timing, and developer endpoints
- **Evidence-gated recommendations** — fixes are suggested only when confidence is high
- **Prefer IPv4 Auto Fix** — when IPv6 is broken or significantly slower than IPv4
- **Restore defaults** — reverse Prefer IPv4 changes on the same platform path
- **Network Controls** — manual IPv6 preference (Automatic / Prefer IPv4) with confirmation
- **Calm desktop UI** — dark Material 3, built for developers

---

## How it works

1. **Probe** — RouteFix runs local checks against public endpoints (DNS lookup, IPv4/IPv6 TCP to port 443, staged HTTP where applicable).
2. **Analyze** — A diagnosis engine scores health and emits issues with cited evidence.
3. **Recommend** — Actionable fixes appear only when rules meet a high-confidence threshold (≥ 0.85). Prefer “Unknown” over a wrong diagnosis.
4. **Fix (optional)** — Auto Fix / Network Controls apply OS-level IPv6 preference changes. Administrator approval is required.

Default probe host: `www.cloudflare.com`. Developer endpoints include GitHub and PyPI.

---

## Supported diagnostics

| Check | What is measured |
|-------|------------------|
| **DNS** | A/AAAA lookup duration for the target host |
| **IPv4 connectivity** | TCP connect latency to port 443 (IPv4) |
| **IPv6 connectivity** | TCP connect latency to port 443 (native IPv6) |
| **TLS / HTTPS** | Handshake and HTTP timings from probe metadata |
| **GitHub** | Staged HTTP probe of `https://api.github.com/` |
| **PyPI** | Latency to `pypi.org` and `files.pythonhosted.org` |
| **Cloudflare** | HTTP probe of `https://www.cloudflare.com/` (shown in the UI) |

Diagnosis rules currently evaluate DNS failure, IPv6 availability, IPv6 latency vs IPv4, GitHub connectivity, and PyPI latency.

Health score: **0–100** with labels Excellent · Good · Fair · Poor · Critical.

---

## Supported Auto Fixes

| Fix | Platforms | Elevation |
|-----|-----------|-----------|
| **Prefer IPv4** | macOS, Linux, Windows | Required |
| **Restore Default Network Configuration** | macOS, Linux, Windows | Required |

**macOS** — `networksetup` via a native administrator dialog  
**Linux** — `sysctl` IPv6 disable flags  
**Windows** — adapter IPv6 binding via PowerShell  

Prefer IPv4 is recommended only when DNS and IPv4 succeed, and IPv6 fails or is much slower (roughly ≥ 3× IPv4 and ≥ 200 ms).

---

## Platform compatibility

Status values reflect **actual verification**, not intended support.

| Feature | macOS | Linux | Windows |
|---------|-------|-------|---------|
| Builds successfully | Verified | Not Verified | Not Verified |
| Diagnostics | Verified | Not Verified | Not Verified |
| DNS | Verified | Not Verified | Not Verified |
| IPv4 | Verified | Not Verified | Not Verified |
| IPv6 | Verified | Not Verified | Not Verified |
| HTTPS | Verified | Not Verified | Not Verified |
| GitHub | Verified | Not Verified | Not Verified |
| PyPI | Verified | Not Verified | Not Verified |
| Cloudflare | Verified | Not Verified | Not Verified |
| Auto Fix | Not Verified | Not Verified | Not Verified |
| Restore Defaults | Not Verified | Not Verified | Not Verified |

**Verification notes**

- **macOS** — `flutter build macos` succeeded; live diagnostic probes against public endpoints succeeded on this host.
- **Linux / Windows** — Flutter desktop builds are host-OS-only (`flutter build linux` / `flutter build windows` cannot run from macOS). Not Verified here.
- **Auto Fix / Restore Defaults** — Implemented for each desktop OS in source, but not exercised end-to-end in this verification pass (requires administrator elevation and changes host networking).

---

## Installation

### Prebuilt binaries

Download the latest desktop build from
[GitHub Releases](https://github.com/MrHacker26/route-fix/releases)
(published automatically when a `v*` tag is pushed).

| Asset | Platform |
|-------|----------|
| `RouteFix-vX.Y.Z-macos.zip` | macOS (`.app` inside) |
| `RouteFix-vX.Y.Z-windows.zip` | Windows |
| `RouteFix-vX.Y.Z-linux.tar.gz` | Linux bundle |

If no release exists yet, build from source below.

### Requirements (from source)

- [Flutter](https://docs.flutter.dev/get-started/install) (stable) with desktop support enabled
- Dart SDK **3.12+**
- macOS, Windows, or Linux

### Build from source

```bash
git clone https://github.com/MrHacker26/route-fix.git
cd route-fix
flutter pub get
```

Run on your desktop target:

```bash
flutter run -d macos    # macOS
flutter run -d windows  # Windows
flutter run -d linux    # Linux
```

Release builds:

```bash
flutter build macos --release
flutter build windows --release
flutter build linux --release
```

On macOS, Auto Fix needs a real administrator prompt (the app is not App Sandboxed for elevated `networksetup`).

---

## Screenshots

| Scanning | Results |
|:--------:|:-------:|
| <img src="assets/screenshots/scanning.png" alt="Scan in progress" width="420"> | <img src="assets/screenshots/result.png" alt="Diagnostics result" width="420"> |

<p align="center">
  <img src="assets/screenshots/auto-fix.png" alt="Auto Fix and network controls" width="720">
  <br>
  <em>Auto Fix &amp; Network Controls</em>
</p>

---

## Architecture overview

```
lib/
  features/       UI — dashboard, diagnostics, network controls, settings
  application/    Diagnostics coordinator
  domain/         Models, diagnosis engine & rules, Auto Fix ports
  data/           dart:io probes, platform fix executors
  di/             Composition root (AppServices)
  design_system/  Theme, tokens, shared components
```

```text
UI  →  DiagnosticsCoordinator  →  probe services (DNS / IPv4 / IPv6 / HTTP)
                              →  DiagnosisEngine (rules + health score)
                              →  DiagnosticReport

UI  →  AutoFixService  →  PlatformFixExecutor (macOS | Linux | Windows)
```

Recommendations must cite evidence. Production UI does not display mocked metrics.

---

## Versioning & releases

- App version lives in `pubspec.yaml` (`MAJOR.MINOR.PATCH+BUILD`) and should match `lib/core/app_info.dart`
- Human-readable history: [`CHANGELOG.md`](CHANGELOG.md)
- Publish a GitHub Release by tagging SemVer with a `v` prefix:

```bash
# After updating pubspec.yaml, AppInfo, and CHANGELOG.md
git tag v1.0.0
git push origin v1.0.0
```

The [Release](.github/workflows/release.yml) workflow builds macOS / Windows / Linux,
attaches binaries, and generates release notes.

---

## Privacy

- Runs **entirely on your machine**
- **No telemetry or analytics**
- Network traffic is limited to the **public endpoints you diagnose** (e.g. Cloudflare, GitHub, PyPI) plus local OS commands for Auto Fix
- Applied-fix state is **in-memory for the session** (not persisted)

---

## Roadmap

- Packaged installers for macOS, Windows, and Linux
- Clearer dual-stack comparisons and technical detail views
- Additional evidence-backed fixes where OS support is reliable
- Stronger test coverage around diagnosis rules and fix executors

See [Issues](https://github.com/MrHacker26/route-fix/issues) to discuss priorities.

---

## Contributing

Contributions are welcome.

1. Fork the repo and create a feature branch
2. Keep diagnosis honest — prefer **Unknown** / insufficient evidence over a wrong fix
3. Do not invent metrics or recommendations without cited probe evidence
4. Match existing structure (`domain` / `data` / `features`) and naming
5. Open a pull request using the PR template; note how you tested
6. Update [`CHANGELOG.md`](CHANGELOG.md) under **Unreleased** for user-facing changes

Engineering principles: [`PROJECT.md`](PROJECT.md).  
Security reports: [`SECURITY.md`](SECURITY.md) (private advisory preferred).

---

## License

Released under the [MIT License](LICENSE).

---

<p align="center">
  <sub>Built with Flutter · Not a bandwidth speed test</sub>
</p>
