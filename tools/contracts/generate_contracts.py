from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import subprocess
import sys
import urllib.request
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
BACKEND_SRC = ROOT / "backend" / "src"
ARTIFACT = ROOT / "contracts" / "openapi" / "memora-v1.json"
CLIENT_DIR = ROOT / "contracts" / "dart" / "memora_api_client"
GENERATOR_CONFIG = ROOT / "tools" / "contracts" / "openapi-generator.json"
CLIENT_CONFIG = ROOT / "tools" / "contracts" / "dart-dio-config.yaml"
TEMPLATE_DIR = ROOT / "tools" / "contracts" / "templates"
CACHE_DIR = ROOT / "tools" / ".cache" / "openapi-generator"
CHECK_DIR = ROOT / "tools" / ".cache" / "contract-check"

IGNORED_COMPARE_DIRS = frozenset({".dart_tool", ".git", ".packages", ".pub", "build"})


class ContractToolError(RuntimeError):
    pass


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _run(
    command: list[str],
    *,
    cwd: Path = ROOT,
    env: dict[str, str] | None = None,
) -> None:
    print(f"+ {' '.join(command)}")
    subprocess.run(command, cwd=cwd, env=env, check=True)


def _dart_command(*args: str) -> list[str]:
    dart = shutil.which("dart")
    if not dart:
        raise ContractToolError("dart was not found on PATH")
    if os.name == "nt":
        return ["cmd.exe", "/c", dart, *args]
    return [dart, *args]


def _java_command() -> str:
    java = shutil.which("java")
    if not java:
        raise ContractToolError("java was not found on PATH")
    return java


def _load_generator() -> dict[str, str]:
    try:
        data: Any = json.loads(GENERATOR_CONFIG.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ContractToolError(
            f"Unable to read generator configuration: {GENERATOR_CONFIG}"
        ) from exc
    if not isinstance(data, dict):
        raise ContractToolError(f"Invalid generator configuration: {GENERATOR_CONFIG}")
    for key in ("version", "url", "sha256"):
        if not isinstance(data.get(key), str) or not data[key]:
            raise ContractToolError(f"Generator configuration is missing {key}")
    return data


def ensure_generator() -> Path:
    config = _load_generator()
    expected = config["sha256"].lower()
    jar = CACHE_DIR / f"openapi-generator-cli-{config['version']}.jar"

    if jar.is_file():
        if _sha256(jar) == expected:
            return jar
        print(f"Cached generator checksum mismatch; removing {jar}")
        jar.unlink()

    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    temporary = jar.with_suffix(".jar.tmp")
    print(f"Downloading pinned OpenAPI generator {config['version']}...")
    request = urllib.request.Request(
        config["url"],
        headers={"User-Agent": "memora-contract-tool/1.0"},
    )
    with (
        urllib.request.urlopen(request, timeout=60) as response,
        temporary.open("wb") as handle,
    ):
        shutil.copyfileobj(response, handle)

    actual = _sha256(temporary)
    if actual != expected:
        temporary.unlink(missing_ok=True)
        raise ContractToolError(
            f"Generator checksum mismatch: expected {expected}, downloaded {actual}"
        )

    temporary.replace(jar)
    return jar


def _export_env() -> dict[str, str]:
    env = os.environ.copy()
    existing = env.get("PYTHONPATH")
    env["PYTHONPATH"] = str(BACKEND_SRC) + (os.pathsep + existing if existing else "")
    return env


def export_artifact(*, check: bool) -> None:
    command = [sys.executable, "-m", "memora.api.export_openapi"]
    if check:
        command.append("--check")
    command.extend(["--output", str(ARTIFACT)])
    _run(command, env=_export_env())


def validate_artifact(jar: Path) -> None:
    _run([_java_command(), "-jar", str(jar), "validate", "-i", str(ARTIFACT)])


def generate_client(jar: Path, output: Path) -> None:
    if output.exists():
        shutil.rmtree(output)
    _run(
        [
            _java_command(),
            "-jar",
            str(jar),
            "generate",
            "-i",
            str(ARTIFACT),
            "-g",
            "dart-dio",
            "-o",
            str(output),
            "-c",
            str(CLIENT_CONFIG),
            "-t",
            str(TEMPLATE_DIR),
        ]
    )


def _dart_pub_get(client_dir: Path, *, enforce_lockfile: bool) -> None:
    command = _dart_command("pub", "get")
    if enforce_lockfile:
        command.append("--enforce-lockfile")
    _run(command, cwd=client_dir)


def _build_client(client_dir: Path, *, enforce_lockfile: bool) -> None:
    _dart_pub_get(client_dir, enforce_lockfile=enforce_lockfile)
    _run(_dart_command("run", "build_runner", "build"), cwd=client_dir)
    _run(_dart_command("format", "lib"), cwd=client_dir)


def _files(root: Path) -> set[str]:
    files: set[str] = set()
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        relative = path.relative_to(root)
        if any(part in IGNORED_COMPARE_DIRS for part in relative.parts):
            continue
        files.add(relative.as_posix())
    return files


def _normalized_bytes(path: Path) -> bytes:
    return path.read_bytes().replace(b"\r\n", b"\n")


def _compare_client(committed: Path, generated: Path) -> bool:
    committed_files = _files(committed)
    generated_files = _files(generated)

    missing = sorted(committed_files - generated_files)
    unexpected = sorted(generated_files - committed_files)
    changed = sorted(
        path
        for path in committed_files & generated_files
        if _normalized_bytes(committed / path) != _normalized_bytes(generated / path)
    )

    if not missing and not unexpected and not changed:
        return True

    if missing:
        print("Missing generated files:", *missing, sep="\n  ")
    if unexpected:
        print("Unexpected generated files:", *unexpected, sep="\n  ")
    if changed:
        print("Changed generated files:", *changed, sep="\n  ")
    return False


def write_client(jar: Path) -> None:
    # Save the committed lockfile before regeneration
    lockfile = CLIENT_DIR / "pubspec.lock"
    lockfile_existed = lockfile.is_file()
    saved_lockfile = ROOT / ".tmp_contracts_lockfile"
    if lockfile_existed:
        saved_lockfile.write_bytes(lockfile.read_bytes())

    try:
        generate_client(jar, CLIENT_DIR)

        # Restore the lockfile so --enforce-lockfile can find it
        if lockfile_existed:
            CLIENT_DIR.mkdir(parents=True, exist_ok=True)
            (CLIENT_DIR / "pubspec.lock").write_bytes(saved_lockfile.read_bytes())

        _build_client(CLIENT_DIR, enforce_lockfile=lockfile_existed)
    finally:
        saved_lockfile.unlink(missing_ok=True)


def check_client(jar: Path) -> None:
    lockfile = CLIENT_DIR / "pubspec.lock"
    if not lockfile.is_file():
        raise ContractToolError(
            f"Missing committed client lock file: {lockfile}. Run --write and commit it first."
        )

    generate_client(jar, CHECK_DIR)
    shutil.copy2(lockfile, CHECK_DIR / "pubspec.lock")
    _build_client(CHECK_DIR, enforce_lockfile=True)
    if not _compare_client(CLIENT_DIR, CHECK_DIR):
        raise ContractToolError(
            "Generated Dart client is stale or does not match the artifact"
        )


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Generate or check the Memora Dart API client."
    )
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument(
        "--write", action="store_true", help="Regenerate the committed client."
    )
    mode.add_argument(
        "--check", action="store_true", help="Verify the committed client is current."
    )
    args = parser.parse_args(argv)

    try:
        jar = ensure_generator()
        if args.write:
            export_artifact(check=False)
            validate_artifact(jar)
            write_client(jar)
        else:
            export_artifact(check=True)
            validate_artifact(jar)
            check_client(jar)
    except (ContractToolError, OSError, subprocess.CalledProcessError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
