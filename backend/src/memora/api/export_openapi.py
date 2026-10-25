from __future__ import annotations

import argparse
import json
import sys
from collections.abc import Sequence
from pathlib import Path
from typing import Any

from fastapi import FastAPI

DEFAULT_OUTPUT = Path("contracts/openapi/memora-v1.json")


def _app() -> FastAPI:
    from memora.main import create_app

    return create_app()


def canonical_document(app: FastAPI | None = None) -> str:
    schema: dict[str, Any] = dict((app or _app()).openapi())
    schema.pop("servers", None)
    return json.dumps(schema, sort_keys=True, indent=2, ensure_ascii=False) + "\n"


def write_document(path: str | Path, app: FastAPI | None = None) -> None:
    output = Path(path)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(canonical_document(app), encoding="utf-8", newline="\n")


def document_is_current(path: str | Path) -> bool:
    output = Path(path)
    if not output.is_file():
        return False
    try:
        content = output.read_bytes().decode("utf-8")
    except (OSError, UnicodeDecodeError):
        return False
    if "\r" in content:
        return False
    return content == canonical_document()


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Export or check the Memora OpenAPI artifact.")
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args(argv)

    if args.check:
        if document_is_current(args.output):
            return 0
        print(f"OpenAPI artifact is stale or invalid: {args.output}", file=sys.stderr)
        return 1

    write_document(args.output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
