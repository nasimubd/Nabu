#!/usr/bin/env bash
set -euo pipefail

check_clean_tree() {
  if [ -n "$(git status --porcelain)" ]; then
    echo "working directory is not clean" >&2
    git status --short >&2
    return 1
  fi
  echo "working directory clean"
}

check_on_main() {
  if [ "$(git branch --show-current)" != "main" ]; then
    echo "release must run on main" >&2
    return 1
  fi
  echo "on main"
}

check_remote_main() {
  git fetch --quiet origin main --tags
  if [ "$(git rev-parse HEAD)" != "$(git rev-parse origin/main)" ]; then
    echo "local main differs from origin/main" >&2
    return 1
  fi
  echo "local main matches origin/main"
}

ensure_gh_token() {
  if [ -z "${GH_TOKEN:-}" ]; then
    command -v gh >/dev/null 2>&1 || { echo "install gh or set GH_TOKEN" >&2; return 1; }
    GH_TOKEN="$(gh auth token)"
    export GH_TOKEN
  fi
  export GITHUB_TOKEN="$GH_TOKEN"
  echo "GitHub token available"
}

check_commits_conventional() {
  local range latest_tag baseline hash subject bad=0
  latest_tag="$(git describe --tags --abbrev=0 2>/dev/null || true)"
  if [ -n "$latest_tag" ]; then
    range="$latest_tag..HEAD"
  else
    baseline="$(git log --format='%H' --grep='^chore(release): adopt Mise release convention$' -n 1)"
    if [ -z "$baseline" ]; then
      echo "release convention boundary is missing" >&2
      return 1
    fi
    range="$baseline..HEAD"
  fi
  while IFS= read -r hash; do
    subject="$(git log -1 --format=%s "$hash")"
    if [[ "$subject" =~ ^Merge\ pull\ request\ #[0-9]+\ from\  ]]; then
      continue
    fi
    if ! git log -1 --format=%B "$hash" | node scripts/release/commitlint.cjs; then
      echo "non-conventional commit: $hash $subject" >&2
      bad=$((bad + 1))
    fi
  done < <(git log --format='%H' "$range")
  if [ "$bad" -ne 0 ]; then
    return 1
  fi
  echo "all unreleased commits are conventional"
}
