-- T11 review fix: stale (out-of-order) memory evidence is recorded as a
-- strict no-op decision explained by the new evidence-recorded template,
-- so the closed template-key allowlist gains one value.

ALTER TABLE memory_decisions DROP CONSTRAINT ck_memory_decisions_template_keys;

ALTER TABLE memory_decisions
  ADD CONSTRAINT ck_memory_decisions_template_keys
  CHECK (explanation_template_key IN (
    'memory.explanation.state_initialized',
    'memory.explanation.exposure_recorded',
    'memory.explanation.recall_success',
    'memory.explanation.recall_lapse',
    'memory.explanation.first_review_scheduled',
    'memory.explanation.comeback',
    'memory.explanation.low_confidence',
    'memory.explanation.weak_prerequisite',
    'memory.explanation.evidence_recorded'
  ));
