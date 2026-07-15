# Changelog

All notable changes to RouteFix are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- GitHub Actions CI and release workflows for macOS, Windows, and Linux
- Settings (appearance, diagnostics timeout, auto-rerun, technical details)
- About RouteFix dialog
- GitHub issue templates and pull request template

### Changed

- Desktop bundle identifiers no longer use placeholder `com.example` branding
- Removed unused `android/` and `ios/` scaffolds (desktop-only product)
- Simplified README

## [1.0.0] - 2026-07-15

### Added

- Desktop routing diagnostics (DNS, IPv4/IPv6 TCP, HTTPS/TLS timings)
- Developer endpoint probes (GitHub, PyPI, Cloudflare)
- Evidence-gated diagnosis engine and health score
- Prefer IPv4 Auto Fix and Restore Defaults (macOS, Linux, Windows)
- Network Controls for manual IPv6 preference
- Dark Material 3 desktop UI

[Unreleased]: https://github.com/MrHacker26/route-fix/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/MrHacker26/route-fix/releases/tag/v1.0.0
