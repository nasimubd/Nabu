# Nabu terminology

Nabu is the name of this reverse-engineering workbench. Pronounce it **NAH-boo**.

Use **target** for the binary or project being studied, **reference** for the current software used for comparison, **finding** for an evidence-backed observation, and **claim** for an interpretation that still needs evidence.

Every finding should include its evidence source, target version or commit, analysis method, confidence, and reproduction steps when available.

## Release boundary

Nabu follows the Mise and semantic-release convention adapted from Argus. Conventional Commits determine the next semantic version. semantic-release updates `VERSION` and `CHANGELOG.md`, creates a `vMAJOR.MINOR.PATCH` tag, and publishes the GitHub Release. Run `mise run release:full` only from a clean, current `main` checkout after review. No release is inferred from a branch push.


## Installation boundary

Nabu installs into `~/Nabu` by default because Ghidra rejects hidden path components in project locations. Keep installers idempotent, verify downloaded Ghidra archives with the published SHA-256 digest, and run the macOS installer and a real headless binary import before release. The core provisioned stack is Ghidra, angr, Semgrep, and radare2 where available; CodeQL and Joern are optional integrations.
