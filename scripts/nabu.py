#!/usr/bin/env python3
"""Nabu command line entry point for reproducible reverse-engineering cases."""
from __future__ import annotations

import argparse
import hashlib
import importlib.metadata
import json
import os
import platform
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path


def home() -> Path:
    return Path(os.environ.get("NABU_HOME", Path.home() / "Nabu")).expanduser()


def tool(name: str) -> str | None:
    return shutil.which(name)


def ghidra_headless() -> Path | None:
    configured = os.environ.get("NABU_GHIDRA_HEADLESS")
    candidates: list[Path] = []
    if configured:
        candidates.append(Path(configured).expanduser())
    runner = tool("ghidraRun")
    if runner:
        resolved = Path(runner).resolve()
        candidates.extend([
            resolved.parent / "support" / "analyzeHeadless",
            resolved.parent.parent / "support" / "analyzeHeadless",
            resolved.parent.parent / "libexec" / "support" / "analyzeHeadless",
        ])
    for root in (Path("/opt/homebrew/opt/ghidra"), Path("/usr/local/opt/ghidra")):
        candidates.append(root / "libexec" / "support" / "analyzeHeadless")
        candidates.append(root / "support" / "analyzeHeadless")
    candidates.append(home() / "tools" / "ghidra" / "support" / ("analyzeHeadless.bat" if os.name == "nt" else "analyzeHeadless"))
    for candidate in candidates:
        if candidate.is_file() and (os.name == "nt" or os.access(candidate, os.X_OK)):
            return candidate
    return None


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def case_id(value: str) -> str:
    safe = "".join(ch if ch.isalnum() or ch in "-_" else "-" for ch in value).strip("-")
    if not safe:
        raise SystemExit("case name must contain letters or numbers")
    return safe.lower()


def write_json(path: Path, value: object) -> None:
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def init_case(name: str) -> Path:
    target = home() / "cases" / case_id(name)
    target.mkdir(parents=True, exist_ok=True)
    metadata = target / "metadata.json"
    if not metadata.exists():
        write_json(metadata, {"case": target.name, "created_at": datetime.now(timezone.utc).isoformat(), "targets": []})
    readme = target / "README.md"
    if not readme.exists():
        readme.write_text(f"# Case: {target.name}\n\nRecord target revisions, hashes, evidence, and findings here.\n", encoding="utf-8")
    return target


def doctor(_: argparse.Namespace) -> int:
    root = home()
    print(f"Nabu home: {root}")
    print(f"Platform: {platform.system()} {platform.machine()}")
    checks = {"git": tool("git"), "python": sys.executable, "ghidraRun": tool("ghidraRun"), "radare2": tool("r2"), "semgrep": tool("semgrep"), "jq": tool("jq"), "Ghidra headless": ghidra_headless()}
    failed = []
    for name, value in checks.items():
        if value:
            print(f"OK   {name}: {value}")
        else:
            print(f"MISS {name}")
            if name in {"git", "python", "Ghidra headless"}:
                failed.append(name)
    for package in ("angr", "semgrep"):
        try:
            print(f"OK   {package}: {importlib.metadata.version(package)}")
        except importlib.metadata.PackageNotFoundError:
            print(f"MISS {package}")
            failed.append(package)
    print("Cases:", root / "cases")
    print("Projects:", root / "projects")
    return 1 if failed else 0


def analyze(args: argparse.Namespace) -> int:
    target = Path(args.target).expanduser().resolve()
    if not target.is_file():
        print(f"target does not exist or is not a file: {target}", file=sys.stderr)
        return 2
    analyzer = ghidra_headless()
    if analyzer is None:
        print("Ghidra headless analyzer was not found; run the installer or set NABU_GHIDRA_HEADLESS", file=sys.stderr)
        return 2
    name = case_id(args.case or target.stem)
    case = init_case(name)
    project = home() / "projects" / name
    project.mkdir(parents=True, exist_ok=True)
    metadata_path = case / "metadata.json"
    metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
    record = {"path": str(target), "sha256": sha256(target), "analyzed_at": datetime.now(timezone.utc).isoformat(), "tool": "Ghidra"}
    env = os.environ.copy()
    java_home = env.get("JAVA_HOME") or env.get("NABU_JAVA_HOME")
    if java_home:
        env["JAVA_HOME"] = java_home
    command = [str(analyzer), str(project), name, "-import", str(target)]
    print("Running:", " ".join(command), flush=True)
    result = subprocess.run(command, env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, check=False)
    print(result.stdout, end="")
    if result.returncode != 0 or "REPORT: Import succeeded" not in result.stdout or "REPORT: Analysis succeeded" not in result.stdout:
        print("Ghidra did not report a successful import and analysis", file=sys.stderr)
        return result.returncode or 1
    metadata.setdefault("targets", []).append(record)
    write_json(metadata_path, metadata)
    return 0


def source(args: argparse.Namespace) -> int:
    name = case_id(args.case)
    case = init_case(name)
    destination = case / "source"
    if destination.exists() and any(destination.iterdir()):
        print(f"source directory already contains files: {destination}", file=sys.stderr)
        return 2
    destination.parent.mkdir(parents=True, exist_ok=True)
    result = subprocess.run(["git", "clone", "--filter=blob:none", args.url, str(destination)], check=False)
    return result.returncode


def main() -> int:
    parser = argparse.ArgumentParser(prog="nabu", description="Reproducible reverse-engineering workbench")
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("doctor", help="check the installed analysis stack").set_defaults(func=doctor)
    paths = sub.add_parser("paths", help="show Nabu storage paths")
    paths.set_defaults(func=lambda _: (print(f"NABU_HOME={home()}"), print(f"cases={home() / 'cases'}"), print(f"projects={home() / 'projects'}"), 0)[-1])
    init = sub.add_parser("case", help="create a case workspace")
    init.add_argument("name")
    init.set_defaults(func=lambda args: (print(init_case(args.name)), 0)[-1])
    binary = sub.add_parser("analyze", help="import and analyze a binary with Ghidra")
    binary.add_argument("target")
    binary.add_argument("--case", help="case name; defaults to the binary filename")
    binary.set_defaults(func=analyze)
    source_cmd = sub.add_parser("source", help="clone a GitHub or Git source project into a case")
    source_cmd.add_argument("url")
    source_cmd.add_argument("--case", required=True)
    source_cmd.set_defaults(func=source)
    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
