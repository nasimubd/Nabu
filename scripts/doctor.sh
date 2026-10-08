#!/usr/bin/env bash
set -euo pipefail

printf 'Nabu environment check\n'
for command_name in git gh; do
  if command -v "$command_name" >/dev/null 2>&1; then
    printf 'ok   %-12s %s\n' "$command_name" "$(command -v "$command_name")"
  else
    printf 'miss %-12s\n' "$command_name"
  fi
done

if command -v ghidraRun >/dev/null 2>&1; then
  printf 'ok   %-12s %s\n' ghidraRun "$(command -v ghidraRun)"
else
  printf 'miss %-12s install Ghidra from https://ghidra-sre.org/\n' ghidraRun
fi

if [[ -n "${JAVA_HOME:-}" ]]; then
  printf 'ok   %-12s %s\n' JAVA_HOME "$JAVA_HOME"
else
  printf 'info %-12s set JAVA_HOME for Ghidra headless analysis\n' JAVA_HOME
fi
