# Physics content

`T08` creates the versioned curriculum and knowledge seed framework. `T12`
creates the question bank and grading path. `T24` adds the pilot content bundle
under `pilot/`.

## Layout

- `pilot/` - eight sealed past-paper MCQs, the fourteen-concept brief, schema,
  reports and source evidence. Read `pilot/README.md` first.
- `source_documents/` - local-only past papers, marking schemes and syllabus.
  Gitignored pending reproduction and licence approval.
- `pilot/local_review/` - local-only full transcription workspace. Gitignored.

The tracked files under `pilot/questions/` are short selected excerpts required
for the pilot. They are not a redistribution licence and they are not import
approval. Do not add private student content here.

## Verification mode

The pilot uses official marking-scheme verification, not a named human reviewer.
The limitation is recorded in `pilot/DEVIATION_REVIEW_MODE.md`, and every item
remains blocked from the T12 import path.

## Commands

```powershell
$env:PYTHONPATH = "backend/src"
.\.venv\Scripts\python.exe -m memora.modules.questions.pilot_validation validate content/physics/pilot/questions
.\.venv\Scripts\python.exe -m memora.modules.questions.pilot_reports --root content/physics/pilot --write
```
