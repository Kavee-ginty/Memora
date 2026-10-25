# Contributing to Memora

## Task workflow

1. Select a Ready task from `docs/project-management/Memora_Development_Task_Table.md`.
2. Set its Owner and status to In Progress.
3. Create the exact listed branch from the latest `develop`.
4. Implement only the task's acceptance boundary.
5. Run affected checks and update generated artifacts.
6. Open one pull request with the task ID in its title.
7. Merge only after review and green checks.
8. Mark the task Done and expose newly unblocked successors.

## Commit style

Use a concise conventional prefix and task ID:

```text
feat(T13): add idempotent mission start
fix(T22): reconcile pending answers in order
test(T25): cover cross-user mission access
docs(T01): define repository workflow
```

## Pull requests

Use `.github/pull_request_template.md`. A reviewer must be able to connect every material change to the task contract and an approved specification.

## Shared files

Avoid concurrent edits to migrations, OpenAPI, generated clients, design tokens, global routing and CI. When a task must change one, call it out before implementation and include every dependent artifact in the same pull request.
