# Changelog

All notable changes to RouteFix are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Flush DNS and Cloudflare DNS preset (1.1.1.1 / 1.0.0.1) with restore on macOS, Windows, and Linux
- DNS resolver controls in Network Controls (Automatic / Cloudflare, flush cache)

### Changed

- Auto Fix catalog: Flush DNS and Use Cloudflare DNS are available (admin required) instead of Coming soon

## [1.1.0] - 2026-07-23

### Added

- End-user install guide ([`docs/INSTALL.md`](docs/INSTALL.md)) for macOS, Windows, and Linux
- Admin elevation prompts on Linux (`pkexec`) and Windows (UAC) for network preference changes
- Persisted Network Controls selection and clearer Connection preference UI (Automatic / Prefer IPv4)

### Changed

- Network Controls: removed duplicate Disable IPv6 option; honest dark-only appearance in Settings
- macOS Auto Fix applies IPv6 preference to all enabled network services (consistent Current state after apply)
- Navigation fix: Done from scan results returns to Dashboard
- Recommendation cards and Network Controls UX improvements

### Fixed

- Linux/Windows network apply no longer fails silently without admin prompt
- Concurrent Auto Fix test assertion aligned with current error message

## [1.0.0] - 2026-07-15

### Added

- Desktop routing diagnostics (DNS, IPv4/IPv6 TCP, HTTPS/TLS timings)
- Developer endpoint probes (GitHub, PyPI, Cloudflare)
- Evidence-gated diagnosis engine and health score
- Prefer IPv4 Auto Fix and Restore Defaults (macOS, Linux, Windows)
- Network Controls for manual IPv6 preference
- Dark Material 3 desktop UI

[Unreleased]: https://github.com/MrHacker26/route-fix/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/MrHacker26/route-fix/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/MrHacker26/route-fix/releases/tag/v1.0.0
