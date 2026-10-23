DROP POLICY IF EXISTS idempotency_records_worker_service ON idempotency_records;
DROP TRIGGER IF EXISTS outbox_events_protect_evidence ON outbox_events;
DROP FUNCTION IF EXISTS memora_protect_outbox_event();
CREATE TRIGGER outbox_events_append_only
BEFORE UPDATE OR DELETE ON outbox_events
FOR EACH ROW EXECUTE FUNCTION memora_forbid_mutation();
