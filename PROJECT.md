# RouteFix

RouteFix is a desktop application that diagnoses network routing issues.

This is **not** a speed test.

It helps developers understand why services like GitHub, PyPI, Docker, or APIs
may feel slow even when bandwidth looks fine.

## Product direction

- Flutter Desktop (macOS, Windows, Linux)
- Dark mode, Material 3
- Developer-first UX (calm, precise, evidence-backed)

Design references: Linear, Raycast, Arc Browser, Apple Settings.

## Engineering rules

- Never infer recommendations from generic failures.
- Every recommendation must cite evidence.
- Every latency label must describe what is actually measured.
- Never display mocked values in production.
- Prefer "Unknown" over an incorrect diagnosis.
- Prefer "Insufficient evidence" over a wrong fix.
