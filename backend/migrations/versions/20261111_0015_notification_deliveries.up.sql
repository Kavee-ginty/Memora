-- T19 notification deliveries: one append-only row per send attempt outcome.
--
-- The ledger serves three contracts at once (Task Table T19; Schema §13.3,
-- TRD §3.2):
--   * consume-once at the source: a trigger dedupe key resolves to at most
--     one send fan-out, so duplicate domain events never double-push;
--   * PRD 032 frequency caps: delivered reminder rows counted per user-local
--     day, honouring the recipient's IANA timezone;
--   * provider delivery results: bounded safe reason codes only — payload
--     parameters, push tokens and provider response bodies are never stored.
--
-- Worker DML goes through SECURITY DEFINER functions (migration 0004 removed
-- direct worker DML on user tables); each function requires the caller to
-- have set ``memora.user_id`` to the delivery owner first.

CREATE TABLE notification_deliveries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id),
  notification_id text NOT NULL,
  category text NOT NULL CHECK (category IN (
    'mission_ready', 'due_memories', 'verification_required',
    'learning_path_ready', 'reward_ready', 'privacy_export_ready'
  )),
  resource_type text NOT NULL,
  resource_id text NOT NULL,
  dedupe_key text NOT NULL,
  device_id uuid REFERENCES device_registrations(id),
  status text NOT NULL CHECK (status IN ('sent', 'failed', 'skipped')),
  skip_reason text CHECK (skip_reason IN (
    'already_delivered', 'category_disabled', 'expired', 'no_devices',
    'notifications_disabled', 'quiet_hours', 'reminder_cap_reached',
    'token_unreadable'
  )),
  provider_code text,
  provider_message_id text,
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK ((status = 'skipped') = (skip_reason IS NOT NULL)),
  CHECK ((status = 'failed') = (provider_code IS NOT NULL)),
  CHECK (provider_message_id IS NULL OR status = 'sent')
);

CREATE UNIQUE INDEX ux_notification_deliveries_send
  ON notification_deliveries (user_id, notification_id, device_id);
CREATE INDEX ix_notification_deliveries_dedupe
  ON notification_deliveries (user_id, dedupe_key);
CREATE INDEX ix_notification_deliveries_sent
  ON notification_deliveries (user_id, created_at) WHERE status = 'sent';

ALTER TABLE notification_deliveries ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_deliveries FORCE ROW LEVEL SECURITY;
CREATE POLICY notification_deliveries_owner ON notification_deliveries
  USING (user_id = nullif(current_setting('memora.user_id', true), '')::uuid)
  WITH CHECK (user_id = nullif(current_setting('memora.user_id', true), '')::uuid);

CREATE FUNCTION memora_forbid_notification_delivery_mutation() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'notification_deliveries is append-only' USING ERRCODE = '55000';
END $$;

CREATE TRIGGER notification_deliveries_append_only
  BEFORE UPDATE OR DELETE ON notification_deliveries
  FOR EACH ROW EXECUTE FUNCTION memora_forbid_notification_delivery_mutation();

CREATE FUNCTION memora_notifications_delivery_exists(
  p_user_id uuid,
  p_dedupe_key text
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.notification_deliveries
    WHERE user_id = p_user_id
      AND dedupe_key = p_dedupe_key
  )
$$;

CREATE FUNCTION memora_notifications_reminders_sent(
  p_user_id uuid,
  p_timezone text,
  p_local_day date
)
RETURNS integer
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
  SELECT count(*)::integer
  FROM public.notification_deliveries
  WHERE user_id = p_user_id
    AND status = 'sent'
    AND category IN ('mission_ready', 'due_memories')
    AND (created_at AT TIME ZONE p_timezone)::date = p_local_day
$$;

CREATE FUNCTION memora_notifications_record_delivery(
  p_user_id uuid,
  p_notification_id text,
  p_category text,
  p_resource_type text,
  p_resource_id text,
  p_dedupe_key text,
  p_device_id uuid,
  p_status text,
  p_skip_reason text,
  p_provider_code text,
  p_provider_message_id text,
  p_created_at timestamptz DEFAULT now()
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_delivery_id uuid;
  v_context_user uuid := nullif(current_setting('memora.user_id', true), '')::uuid;
BEGIN
  IF v_context_user IS NULL OR v_context_user <> p_user_id THEN
    RAISE EXCEPTION 'memora.user_id must be set to the delivery owner';
  END IF;

  INSERT INTO public.notification_deliveries(
    user_id, notification_id, category, resource_type, resource_id,
    dedupe_key, device_id, status, skip_reason, provider_code,
    provider_message_id, created_at
  ) VALUES (
    p_user_id, p_notification_id, p_category, p_resource_type, p_resource_id,
    p_dedupe_key, p_device_id, p_status, p_skip_reason, p_provider_code,
    p_provider_message_id, p_created_at
  )
  ON CONFLICT (user_id, notification_id, device_id) DO NOTHING
  RETURNING id INTO v_delivery_id;

  RETURN v_delivery_id;
END $$;

REVOKE ALL ON FUNCTION memora_notifications_delivery_exists(uuid, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION memora_notifications_reminders_sent(uuid, text, date) FROM PUBLIC;
REVOKE ALL ON FUNCTION memora_notifications_record_delivery(uuid, text, text, text, text, text, uuid, text, text, text, text, timestamptz) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION memora_notifications_delivery_exists(uuid, text) TO memora_api, memora_worker;
GRANT EXECUTE ON FUNCTION memora_notifications_reminders_sent(uuid, text, date) TO memora_api, memora_worker;
GRANT EXECUTE ON FUNCTION memora_notifications_record_delivery(uuid, text, text, text, text, text, uuid, text, text, text, text, timestamptz) TO memora_api, memora_worker;

-- Default privileges from migration 0001 only cover that role's future
-- tables; grant this table's roles explicitly (worker stays function-only).
GRANT SELECT, INSERT ON notification_deliveries TO memora_api;
