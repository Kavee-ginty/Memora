# Tools

Repository maintenance tools live here. `docs/` contains deterministic builders for review documents and project diagrams; application runtime code must not depend on these tools.

## Contracts

`tools/contracts/generate_contracts.py` exports the reviewed OpenAPI artifact and
generates the Dart client:

```powershell
python tools/contracts/generate_contracts.py --write
python tools/contracts/generate_contracts.py --check
```

Requirements are Java 17+ and Dart 3.12+ on `PATH`; CI uses Java 21 and Dart
3.13.0. The generator is pinned to 7.26.0 with a SHA-256 in
`tools/contracts/openapi-generator.json`. The verified JAR is cached in
`tools/.cache/openapi-generator/`, which is ignored; a cache miss downloads it
from Maven Central and checks the checksum before use.

`tools/contracts/templates/pubspec.mustache` overrides the generator's pubspec
template because 7.26.0 with `useOptional: true` emits `optional.dart` importing
`json_annotation` without declaring it.

`.github/workflows/contracts.yml` runs the backend contract tests, the drift check,
and the generated client and contract-test analysis/tests.

## Documentation

Install the documentation-only dependencies:

```powershell
python -m venv tools/.venv
.\tools\.venv\Scripts\python.exe -m pip install --require-hashes -r tools/requirements.lock
```

Regenerate review documents and the network diagram from the repository root:

```powershell
.\tools\.venv\Scripts\python.exe tools/docs/build_ui_spec_docx.py
.\tools\.venv\Scripts\python.exe tools/docs/build_backend_schema_docx.py
.\tools\.venv\Scripts\python.exe tools/docs/build_app_flow_docx.py
.\tools\.venv\Scripts\python.exe tools/docs/build_api_contract_docx.py
.\tools\.venv\Scripts\python.exe tools/docs/build_network_diagram.py
```

The Markdown specifications remain authoritative; generated DOCX and PNG files are review artifacts.
