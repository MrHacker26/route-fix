# RouteFix

RouteFix is a desktop application that diagnoses network routing issues.

This is NOT a speed test.

It helps users understand why services like GitHub, PyPI, Docker or APIs may be slow even when bandwidth is high.

The design language is inspired by:

- Linear
- Raycast
- Arc Browser
- Apple Settings

Target:

Flutter Desktop

Dark Mode

Material 3

Developer-first.

We value:

- Premium UI
- Simple UX
- Accurate diagnosis
- Calm animations
- Beautiful typography

Never generate code outside the requested task.

## Engineering Rules

- Never infer recommendations from generic failures.
- Every recommendation must cite evidence.
- Every latency label must describe what is actually measured.
- Never display mocked values in production.
- Prefer "Unknown" over an incorrect diagnosis.
- It is better to return "Insufficient evidence" than a wrong fix.