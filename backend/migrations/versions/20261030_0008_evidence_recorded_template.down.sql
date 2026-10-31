-- Restore the pre-fix template-key allowlist.

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
    'memory.explanation.weak_prerequisite'
  ));
