# Nabu

[![Release](https://img.shields.io/github/v/release/nasimubd/Nabu?display_name=tag&sort=semver&style=for-the-badge&color=ff69b4)](https://github.com/nasimubd/Nabu/releases)
[![License](https://img.shields.io/github/license/nasimubd/Nabu?style=for-the-badge&color=ff69b4)](LICENSE)
[![Release convention](https://img.shields.io/github/actions/workflow/status/nasimubd/Nabu/release-convention.yml?branch=main&label=release%20convention&style=for-the-badge&color=ff69b4)](https://github.com/nasimubd/Nabu/actions/workflows/release-convention.yml)
[![Stars](https://img.shields.io/github/stars/nasimubd/Nabu?style=for-the-badge&color=ffb000)](https://github.com/nasimubd/Nabu/stargazers)

> 🧭 **Nabu** is a reproducible reverse-engineering workbench for binaries and source projects.

Nabu organizes static analysis, decompilation, source inspection, evidence, and feature comparison in one home-level workspace. Use it to understand an authorized target, compare its behavior and capabilities with your software, and turn validated findings into implementation work.

## ✨ About

- **Binary analysis:** Ghidra headless analysis with persistent, hash-recorded cases.
- **Program analysis:** angr symbolic execution and Semgrep source/data-flow checks.
- **Supporting tools:** radare2, CodeQL, and Joern can be added to the same workspace.
- **Evidence first:** target revisions, SHA-256 hashes, tool versions, observations, and confidence stay together.
- **Safe storage:** binaries, cloned projects, credentials, and generated databases live under `~/Nabu` and remain outside Git.
- **Automation ready:** every case can be analyzed from a terminal or CI job with a stable command.

Nabu is for targets you are authorized to inspect. Follow the target's license, terms, privacy requirements, and applicable law.

## 🚀 Install the complete core stack

Each platform has one bootstrap command. It creates a home-level `NABU_HOME`, installs the required runtime and analysis tools, creates an isolated Python environment, installs angr and Semgrep, and writes the `nabu` command plus persistent case directories.

### macOS

```bash
curl -fsSL https://raw.githubusercontent.com/nasimubd/Nabu/main/scripts/install.sh | bash
```

The macOS installer installs Homebrew when absent and uses it to install OpenJDK 21, Ghidra, radare2, Python 3.13, and jq. It installs angr and Semgrep into an isolated virtual environment.

### Linux

```bash
curl -fsSL https://raw.githubusercontent.com/nasimubd/Nabu/main/scripts/install.sh | bash
```

The Linux installer targets Debian and Ubuntu systems with `apt`. It installs OpenJDK 21, radare2, Python, jq, and the Ghidra release archive, then installs angr and Semgrep in an isolated virtual environment. It requires `sudo` for system packages.

### Windows PowerShell

```powershell
irm https://raw.githubusercontent.com/nasimubd/Nabu/main/scripts/install.ps1 | iex
```

The Windows installer requires WinGet. It installs Git, Python 3.13, OpenJDK 21, the Ghidra and radare2 release archives, angr, and Semgrep. Windows x64 is supported by this installer. Run the generated PowerShell wrapper after installation.

For reproducible automation, replace `main` in the installer URL with a released tag that includes these installers.

The Python tools are pinned to angr 9.2.186 and Semgrep 1.180.0. Package managers select the system tool versions; the installer records the resolved Python packages in `python-packages.txt`. Ghidra and radare2 downloads are verified against SHA-256 digests published by GitHub.

**Verification:** the macOS ARM64 installation and binary analysis were exercised on a real Mac. Linux and Windows installation scripts still require native end-to-end validation.

## 🧰 User commands

After installation, load the environment once per shell:

```bash
source "$HOME/Nabu/env"                 # macOS/Linux
```

PowerShell users run the generated wrapper directly:

```powershell
& "$HOME/Nabu/bin/nabu.ps1" doctor
```

### Check the stack

```bash
nabu doctor
nabu paths
```

### Start a case

```bash
nabu case my-project
```

This creates an isolated case under `~/Nabu/cases/my-project/` and keeps projects under `~/Nabu/projects/`.

### Reverse-engineer a supported binary

```bash
nabu analyze ./path/to/program --case program-analysis
```

After Ghidra reports a successful import and analysis, Nabu records the target path, SHA-256, analysis timestamp, and tool in case metadata. The generated project is stored at `~/Nabu/projects/program-analysis/`.

### Inspect a GitHub project

```bash
nabu source https://github.com/OWNER/PROJECT.git --case project-source
```

The source checkout is placed in the case workspace. Record the exact commit, license, and scope in the case metadata before drawing conclusions.

### Run Ghidra directly

```bash
"$NABU_GHIDRA_HEADLESS" "$HOME/Nabu/projects/program-analysis" program-analysis \
  -import ./path/to/program
```

### Run supporting analysis

```bash
source "$HOME/Nabu/env"
python -c "import angr; print(angr.__version__)"
semgrep --config auto ./source-tree
r2 -AA ./path/to/program
```

## 🗂️ Workspace layout

```text
~/Nabu/
├── bin/nabu                  # stable command wrapper
├── env                       # environment exports
├── venv/                     # isolated Python analysis tools
├── tools/                    # downloaded tool runtimes
├── cases/                    # metadata, source checkouts, findings
├── projects/                 # persistent Ghidra projects
├── reports/                  # generated reports
└── samples/                  # local inputs, ignored by Git
```

The repository itself stores methods, templates, scripts, and conclusions. It does not store target binaries, credentials, cloned dependencies, or generated analysis databases.

## 🔬 Analysis workflow

1. **Identify:** record origin, revision, platform, architecture, license, and SHA-256.
2. **Survey:** inspect formats, symbols, imports, strings, dependencies, and source structure.
3. **Analyze:** run Ghidra, angr, radare2, Semgrep, CodeQL, or Joern as appropriate.
4. **Corroborate:** reproduce behavior and separate observations from inferences.
5. **Compare:** map target features and behavior against the reference implementation.
6. **Implement:** turn validated differences into a reviewed issue, design, or pull request.

See [the evidence methodology](docs/methodology.md), [the case template](cases/template.md), and [the comparison guide](comparisons/README.md).

## 📦 Release and version

The current version is maintained in [`VERSION`](VERSION) and published as a GitHub Release. The badge at the top of this page reads the latest repository release dynamically, so it stays aligned after every release.

Nabu follows Conventional Commits and semantic version tags:

```bash
mise run release:drift
mise run release:dry
mise run release:full
```

Run the full release only from a clean, current `main` after reviewed changes have been merged. See [docs/RELEASE.md](docs/RELEASE.md).

## 📚 Project citations

Nabu combines these open-source projects and their official documentation:

- [Ghidra](https://github.com/NationalSecurityAgency/ghidra) — software reverse-engineering framework and decompiler.
- [angr](https://github.com/angr/angr) — multi-architecture binary analysis and symbolic execution.
- [radare2](https://github.com/radareorg/radare2) — Unix-like reverse-engineering framework and CLI toolset.
- [Semgrep](https://github.com/semgrep/semgrep) — source pattern and data-flow analysis.
- [CodeQL](https://github.com/github/codeql) — query-based source and compiled-language analysis.
- [Joern](https://github.com/joernio/joern) — code property graph analysis for source, bytecode, and binaries.

Tool roles and source links are also recorded in [`tools/manifest.yml`](tools/manifest.yml).

## 🤝 Contributing

Use a dedicated worktree, an atomic Conventional Commit, and a pull request against `main`. Keep target data and secrets outside Git. See [CONTRIBUTING.md](CONTRIBUTING.md).

## 📄 License

Nabu is released under the [MIT License](LICENSE). Each integrated tool and each analyzed target retains its own license.
