# Tools

Repository maintenance tools live here. `docs/` contains deterministic builders for review documents and project diagrams; application runtime code must not depend on these tools.

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
