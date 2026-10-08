# Release conventions

Nabu uses the Mise and semantic-release convention adapted from Argus. Use semantic version tags in the form `vMAJOR.MINOR.PATCH`. Conventional Commits determine the next version. The process updates `VERSION` and `CHANGELOG.md`, creates a tag, and publishes a GitHub Release.

## Version rules

The Angular preset treats `feat` as a minor change, `fix` and `perf` as patch changes, and a breaking change marker or `BREAKING CHANGE` footer as a major change. Review every dry run before publishing.

## Commands

Run from a clean, current `main` checkout with GitHub authentication:

```bash
mise run release:drift       # inspect version, tag, and unreleased commits
mise run release:dry         # preview semantic-release without publishing
mise run release:full        # preflight, version, and postflight
```

`release:preflight` checks the clean tree, branch, upstream alignment, GitHub credentials, Conventional Commits, and release tooling. `release:version` runs semantic-release. `release:postflight` checks the clean tree, upstream alignment, tag, and recorded version. No release is inferred from a branch push.

Nabu does not publish compiled binaries. Samples, cloned projects, Ghidra databases, credentials, and generated reports remain outside Git. A release contains the repository source, documented methods, and reproducible scripts.

## Pull requests

Use a dedicated worktree and an atomic Conventional Commit. Open the PR against `main`, wait for review, and let the maintainer merge it. Release only after the reviewed changes have reached current `main`.
