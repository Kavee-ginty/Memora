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
for the pilot. They are not a redistribution licence. The self-review and import
approval do not grant redistribution rights. Do not add private student content
here.

## Verification mode

The pilot uses `expert_review` with the named Physics teacher self-review
recorded in `pilot/REVIEW_RECORD.md`. The printed official marking-scheme grid
remains the answer-key authority. The review is a self-review; independence is
not claimed, and the qualification reference is self-declared. Every item is
approved for import batch `T24-PHYS-PILOT-2026-11`.

## Commands

```powershell
$env:PYTHONPATH = "backend/src"
.\.venv\Scripts\python.exe -m memora.modules.questions.pilot_validation validate content/physics/pilot/questions
.\.venv\Scripts\python.exe -m memora.modules.questions.pilot_reports --root content/physics/pilot --write
```
