# Nabu

Nabu is a public, reproducible reverse-engineering workbench for understanding binaries and GitHub projects, recording evidence, and comparing recovered behavior with an existing implementation.

The repository stores methods, scripts, metadata, and conclusions. Large binaries, cloned third-party repositories, generated Ghidra databases, credentials, and other artifacts stay outside Git and are referenced by hashes.

## Workflow

1. Create a case under `cases/<case-id>/`.
2. Record the target URL, commit or release, platform, architecture, and SHA-256.
3. Run static analysis with Ghidra and source analysis with CodeQL, Semgrep, or Joern as appropriate.
4. Record observations with evidence links and confidence in `reports/`.
5. Compare target capabilities with the current implementation in `comparisons/`.
6. Turn validated findings into implementation issues or pull requests in the current software repository.

Use this project only for software and targets that you are authorized to analyze. Respect licenses, terms, privacy, and applicable law.

## Local setup

Ghidra is the primary binary analysis tool. On macOS with Homebrew:

```bash
brew install ghidra
export JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
ghidraRun
```

Run the environment check:

```bash
./scripts/doctor.sh
```

The headless analyzer can import a target into a disposable project:

```bash
analyzeHeadless <project-location> <project-name> -import <target>
```

## Repository layout

- `cases/`: target metadata and case-specific notes
- `comparisons/`: feature and behavior comparisons
- `docs/`: methodology and evidence standards
- `reports/`: analysis reports and conclusions
- `scripts/`: reproducible helper scripts
- `tools/`: pinned tool and source references
- `vale/`: writing checks and the Nabu glossary

## Releases

Nabu uses Conventional Commits and semantic version tags in the form `vMAJOR.MINOR.PATCH`. The release steward runs the ordered Mise workflow from clean, current `main`:

```bash
mise run release:drift
mise run release:dry
mise run release:full
```

The workflow updates `VERSION` and `CHANGELOG.md`, creates the tag, and publishes a GitHub Release. The release convention check runs on pull requests and pushes to `main`. Nabu has no binary publication step; case inputs and generated analysis artifacts remain outside Git.
