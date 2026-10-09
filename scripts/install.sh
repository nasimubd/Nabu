#!/usr/bin/env bash
# Install Nabu's core reverse-engineering stack into $NABU_HOME.
set -euo pipefail

NABU_HOME="${NABU_HOME:-${HOME}/Nabu}"
NABU_REF="${NABU_REF:-main}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_BIN="${NABU_PYTHON:-python3}"
mkdir -p "$NABU_HOME" "$NABU_HOME/bin" "$NABU_HOME/cases" "$NABU_HOME/projects" "$NABU_HOME/reports" "$NABU_HOME/samples"

install_brew() {
  if ! command -v brew >/dev/null 2>&1; then
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [ -x /opt/homebrew/bin/brew ]; then eval "$(/opt/homebrew/bin/brew shellenv)"; fi
    if [ -x /usr/local/bin/brew ]; then eval "$(/usr/local/bin/brew shellenv)"; fi
  fi
  command -v brew >/dev/null 2>&1 || { echo "Homebrew could not be installed: https://brew.sh" >&2; exit 1; }
  brew install git ghidra openjdk@21 python@3.13 jq radare2
  PYTHON_BIN="$(brew --prefix python@3.13)/bin/python3.13"
  NABU_JAVA_HOME="$(brew --prefix openjdk@21)/libexec/openjdk.jdk/Contents/Home"
  export NABU_JAVA_HOME
}

install_apt() {
  command -v apt-get >/dev/null 2>&1 || { echo "Install git, Python 3, Java 21, jq, and radare2 with your distribution package manager." >&2; exit 1; }
  sudo apt-get update
  sudo apt-get install -y git curl jq unzip python3 python3-venv python3-pip openjdk-21-jdk radare2
  NABU_JAVA_HOME="$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")"
  export NABU_JAVA_HOME
}

install_ghidra_archive() {
  local tools="$NABU_HOME/tools" api asset archive extracted expected actual
  mkdir -p "$tools"
  if [ -x "$tools/ghidra/support/analyzeHeadless" ]; then
    NABU_GHIDRA_HEADLESS="$tools/ghidra/support/analyzeHeadless"
    return
  fi
  if [ -n "${NABU_GHIDRA_HEADLESS:-}" ] && [ -x "$NABU_GHIDRA_HEADLESS" ]; then return; fi
  command -v curl >/dev/null 2>&1 || { echo "curl is required to download Ghidra" >&2; exit 1; }
  command -v jq >/dev/null 2>&1 || { echo "jq is required to select the Ghidra release" >&2; exit 1; }
  command -v unzip >/dev/null 2>&1 || { echo "unzip is required to install Ghidra" >&2; exit 1; }
  api="$(curl -fsSL https://api.github.com/repos/NationalSecurityAgency/ghidra/releases/latest)"
  asset="$(printf "%s" "$api" | jq -r '.assets[] | select(.name | test("PUBLIC.*\\.zip$")) | .browser_download_url' | head -n 1)"
  [ -n "$asset" ] && [ "$asset" != "null" ] || { echo "could not find a Ghidra release archive" >&2; exit 1; }
  expected="$(printf "%s" "$api" | jq -r '.assets[] | select(.name | test("PUBLIC.*\\.zip$")) | .digest' | head -n 1)"
  archive="$tools/ghidra.zip"
  curl -fL "$asset" -o "$archive"
  case "$expected" in sha256:*) ;; *) echo "Ghidra release has no SHA-256 digest" >&2; exit 1 ;; esac
  if command -v shasum >/dev/null 2>&1; then actual="$(shasum -a 256 "$archive" | awk '{print $1}')"; else actual="$(sha256sum "$archive" | awk '{print $1}')"; fi
  [ "$actual" = "${expected#sha256:}" ] || { echo "Ghidra archive checksum mismatch" >&2; exit 1; }
  unzip -q "$archive" -d "$tools"
  extracted="$(find "$tools" -maxdepth 1 -type d -name 'ghidra_*_PUBLIC' | head -n 1)"
  [ -n "$extracted" ] || { echo "Ghidra archive did not contain the expected directory" >&2; exit 1; }
  if [ -e "$tools/ghidra" ]; then echo "Ghidra destination exists: $tools/ghidra" >&2; exit 1; fi
  mv "$extracted" "$tools/ghidra"
  rm -f "$archive"
  NABU_GHIDRA_HEADLESS="$tools/ghidra/support/analyzeHeadless"
}

case "$(uname -s)" in
  Darwin) install_brew ;;
  Linux) install_apt ;;
  *) echo "Use scripts/install.ps1 on Windows." >&2; exit 1 ;;
esac

command -v "$PYTHON_BIN" >/dev/null 2>&1 || { echo "Python interpreter not found: $PYTHON_BIN" >&2; exit 1; }
"$PYTHON_BIN" -m venv "$NABU_HOME/venv"
"$NABU_HOME/venv/bin/python" -m pip install --upgrade pip
"$NABU_HOME/venv/bin/python" -m pip install --upgrade angr==9.2.186 semgrep==1.180.0
"$NABU_HOME/venv/bin/python" -m pip check
"$NABU_HOME/venv/bin/python" -m pip freeze > "$NABU_HOME/python-packages.txt"

if command -v ghidraRun >/dev/null 2>&1; then
  GHIDRA_RUN="$(command -v ghidraRun)"
  GHIDRA_RESOLVED="$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$GHIDRA_RUN")"
  GHIDRA_HEADLESS="$(dirname "$(dirname "$GHIDRA_RESOLVED")")/libexec/support/analyzeHeadless"
  if [ ! -x "$GHIDRA_HEADLESS" ]; then GHIDRA_HEADLESS="$(dirname "$GHIDRA_RESOLVED")/support/analyzeHeadless"; fi
else
  GHIDRA_HEADLESS=""
fi
if [ -z "$GHIDRA_HEADLESS" ] || [ ! -x "$GHIDRA_HEADLESS" ]; then
  install_ghidra_archive
  GHIDRA_HEADLESS="${NABU_GHIDRA_HEADLESS:-$NABU_HOME/tools/ghidra/support/analyzeHeadless}"
fi

cat > "$NABU_HOME/env" <<EOF
export NABU_HOME="$NABU_HOME"
export NABU_GHIDRA_HEADLESS="$GHIDRA_HEADLESS"
export NABU_JAVA_HOME="${NABU_JAVA_HOME:-}"
export JAVA_HOME="${NABU_JAVA_HOME:-${JAVA_HOME:-}}"
export PATH="$NABU_HOME/bin:$NABU_HOME/venv/bin:\$PATH"
EOF
cat > "$NABU_HOME/bin/nabu" <<EOF
#!/usr/bin/env bash
set -euo pipefail
source "$NABU_HOME/env"
exec "$NABU_HOME/venv/bin/python" "$NABU_HOME/nabu.py" "\$@"
EOF
if [ -f "$SCRIPT_DIR/../scripts/nabu.py" ]; then
  cp "$SCRIPT_DIR/../scripts/nabu.py" "$NABU_HOME/nabu.py"
else
  curl -fsSL "https://raw.githubusercontent.com/nasimubd/Nabu/${NABU_REF}/scripts/nabu.py" -o "$NABU_HOME/nabu.py"
fi
chmod +x "$NABU_HOME/bin/nabu"
"$NABU_HOME/bin/nabu" doctor
printf '\nNabu installed at %s\n' "$NABU_HOME"
printf 'Add this to your shell profile: source %s/env\n' "$NABU_HOME"
