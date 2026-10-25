DROP TRIGGER outbox_events_append_only ON outbox_events;

CREATE FUNCTION memora_protect_outbox_event() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    RAISE EXCEPTION 'outbox_events is append-only' USING ERRCODE = '55000';
  END IF;

  IF NEW.id IS DISTINCT FROM OLD.id
    OR NEW.domain_event_key IS DISTINCT FROM OLD.domain_event_key
    OR NEW.aggregate_type IS DISTINCT FROM OLD.aggregate_type
    OR NEW.aggregate_id IS DISTINCT FROM OLD.aggregate_id
    OR NEW.event_type IS DISTINCT FROM OLD.event_type
    OR NEW.event_version IS DISTINCT FROM OLD.event_version
    OR NEW.payload IS DISTINCT FROM OLD.payload
    OR NEW.correlation_id IS DISTINCT FROM OLD.correlation_id
    OR NEW.created_at IS DISTINCT FROM OLD.created_at
  THEN
    RAISE EXCEPTION 'outbox event evidence is immutable' USING ERRCODE = '55000';
  END IF;

  IF OLD.publication_status = 'published'
    AND (
      NEW.publication_status <> 'published'
      OR NEW.published_at IS DISTINCT FROM OLD.published_at
    )
  THEN
    RAISE EXCEPTION 'published outbox event is immutable' USING ERRCODE = '55000';
  END IF;

  IF (NEW.publication_status = 'published') <> (NEW.published_at IS NOT NULL) THEN
    RAISE EXCEPTION 'published status and timestamp must agree' USING ERRCODE = '23514';
  END IF;

  RETURN NEW;
END $$;

CREATE TRIGGER outbox_events_protect_evidence
BEFORE UPDATE OR DELETE ON outbox_events
FOR EACH ROW EXECUTE FUNCTION memora_protect_outbox_event();

CREATE POLICY idempotency_records_worker_service ON idempotency_records
FOR ALL TO memora_worker
USING (user_id IS NULL)
WITH CHECK (user_id IS NULL);
