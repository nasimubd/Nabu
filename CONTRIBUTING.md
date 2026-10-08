# Contributing to Nabu

Nabu welcomes reproducible analysis methods, documentation, scripts, and comparison reports that respect target licenses and authorization boundaries.

## Before you start

1. Search existing issues and pull requests.
2. Keep binaries, cloned repositories, Ghidra databases, credentials, and personal data out of Git.
3. Record target revisions and SHA-256 hashes when adding analysis evidence.

## Development setup

Start from current `main` in a dedicated worktree:

```bash
git fetch origin main
git worktree add ../Nabu-change -b change/name origin/main
```

Use active-voice Conventional Commits such as `docs(methodology): define evidence levels`. Run the relevant checks before opening a PR:

```bash
mise run release:check
```

## Pull requests

Describe the scope, target or workflow affected, evidence, security and license considerations, and verification commands. Keep the history reviewable and do not merge your own PR. Maintainers perform the final merge and release.

## Release workflow

Releases run only from clean, current `main`:

```bash
mise run release:drift
mise run release:dry
mise run release:full
```
