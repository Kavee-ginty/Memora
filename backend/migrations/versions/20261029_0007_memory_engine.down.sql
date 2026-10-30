-- Revert the T11 memory engine surface: functions, allowlists and the
-- delivery index. Persisted memory evidence and decisions are retained.

DROP FUNCTION IF EXISTS memora_memory_apply_decision(
  uuid, uuid, uuid, uuid, uuid, jsonb, jsonb, numeric, timestamptz, text[],
  text, text, text, timestamptz, text, jsonb, uuid
);
DROP FUNCTION IF EXISTS memora_memory_record_event(
  uuid, uuid, text, text, uuid, timestamptz, numeric, numeric, boolean, text, jsonb
);
DROP FUNCTION IF EXISTS memora_memory_context(uuid, uuid);

ALTER TABLE memory_decisions DROP CONSTRAINT IF EXISTS ck_memory_decisions_template_keys;
ALTER TABLE memory_decisions DROP CONSTRAINT IF EXISTS ck_memory_decisions_reason_codes;

DROP INDEX IF EXISTS ix_memory_events_delivery;
