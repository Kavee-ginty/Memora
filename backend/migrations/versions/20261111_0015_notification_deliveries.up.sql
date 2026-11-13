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
  device_id uuid REFERENCES device_registrations(id) ON DELETE SET NULL,
  status text NOT NULL CHECK (status IN ('sending', 'sent', 'failed', 'skipped')),
  skip_reason text CHECK (skip_reason IN (
    'already_delivered', 'category_disabled', 'expired', 'no_devices',
    'notifications_disabled', 'quiet_hours', 'reminder_cap_reached',
    'resource_unavailable', 'token_unreadable'
  )),
  provider_code text,
  provider_message_id text,
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK ((status = 'skipped') = (skip_reason IS NOT NULL)),
  CHECK (skip_reason IS NULL OR status = 'skipped'),
  CHECK (provider_code IS NULL OR status IN ('failed', 'sending')),
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

CREATE FUNCTION memora_protect_notification_delivery() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    -- The audited account-deletion purge (memora_delete_learner_data sets
    -- the privacy_deletion flag) is the only permitted delete.
    IF current_setting('memora.privacy_deletion', true) = 'on'
       AND current_user NOT IN ('memora_api', 'memora_worker') THEN
      -- Matches the 0013 forbid-mutation semantics: inside the SECURITY
      -- DEFINER executor, current_user is the function owner.
      RETURN OLD;
    END IF;
    RAISE EXCEPTION 'notification_deliveries is append-only' USING ERRCODE = '55000';
  END IF;
  -- The foreign key's ON DELETE SET NULL action nulls device_id when the
  -- referenced device registration is removed (account deletion); that
  -- system-initiated update touches no other column.
  IF NEW.device_id IS NULL
     AND OLD.device_id IS NOT NULL
     AND (to_jsonb(NEW) - 'device_id') = (to_jsonb(OLD) - 'device_id') THEN
    RETURN NEW;
  END IF;
  -- The only other permitted update is the two-phase completion of an
  -- in-flight send: sending -> sent/failed, touching nothing but the
  -- outcome fields (Schema §14.2: the external provider call happens
  -- outside the planning transaction, so the row is recorded first and
  -- completed after).
  IF OLD.status <> 'sending'
     OR NEW.status NOT IN ('sent', 'failed')
     OR (to_jsonb(NEW) - 'status' - 'provider_code' - 'provider_message_id')
        IS DISTINCT FROM (to_jsonb(OLD) - 'status' - 'provider_code' - 'provider_message_id')
  THEN
    RAISE EXCEPTION 'notification_deliveries is append-only' USING ERRCODE = '55000';
  END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER notification_deliveries_lifecycle
  BEFORE UPDATE OR DELETE ON notification_deliveries
  FOR EACH ROW EXECUTE FUNCTION memora_protect_notification_delivery();

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
    AND status IN ('sent', 'sending')
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

CREATE FUNCTION memora_notifications_expire_stale_sending(
  p_now timestamptz,
  p_stale_after interval
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_expired integer;
BEGIN
  UPDATE public.notification_deliveries
  SET status = 'failed',
      provider_code = 'send_outcome_unknown'
  WHERE status = 'sending'
    AND created_at < p_now - p_stale_after;
  GET DIAGNOSTICS v_expired = ROW_COUNT;
  RETURN v_expired;
END $$;

REVOKE ALL ON FUNCTION memora_notifications_expire_stale_sending(timestamptz, interval) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION memora_notifications_expire_stale_sending(timestamptz, interval) TO memora_api, memora_worker;

-- Default privileges from migration 0001 only cover that role's future
-- tables; grant this table's roles explicitly (worker keeps function-only
-- access for cross-user maintenance; UPDATE is required for the two-phase
-- completion under the owner context).
GRANT SELECT, INSERT, UPDATE ON notification_deliveries TO memora_api;


-- Account deletion (review finding 11 / retention decision): delivery rows
-- carry the recipient and resource identifiers, so they are purged with the
-- learner's data when the privacy deletion executor runs. The function is
-- replaced with its 0013 body plus this one purge statement; grants are
-- preserved by CREATE OR REPLACE.
CREATE OR REPLACE FUNCTION memora_delete_learner_data(p_user_id uuid) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  caller_role text := current_setting('role', true);
  scoped_user text := current_setting('memora.user_id', true);
BEGIN
  IF caller_role = 'memora_api' THEN
    IF scoped_user IS NULL
       OR scoped_user = ''
       OR scoped_user::uuid <> p_user_id
       OR NOT EXISTS (
         SELECT 1 FROM privacy_requests
         WHERE user_id = p_user_id
           AND request_type = 'delete'
           AND status = 'processing'
       ) THEN
      RAISE EXCEPTION 'privacy deletion user scope mismatch' USING ERRCODE = '42501';
    END IF;
  ELSIF caller_role = 'memora_worker' THEN
    IF NOT EXISTS (
      SELECT 1
      FROM users u
      LEFT JOIN privacy_requests pr
        ON pr.user_id = u.id
       AND pr.request_type = 'delete'
       AND pr.status = 'completed'
      WHERE u.id = p_user_id
        AND (u.status = 'deleted' OR pr.id IS NOT NULL)
    ) THEN
      RAISE EXCEPTION 'privacy reconciliation target is not deleted' USING ERRCODE = '42501';
    END IF;
  ELSE
    RAISE EXCEPTION 'privacy deletion executor is not available to role %', caller_role
      USING ERRCODE = '42501';
  END IF;

  PERFORM set_config('memora.privacy_deletion', 'on', true);

  DELETE FROM question_reports WHERE user_id = p_user_id;
  DELETE FROM grading_results
    WHERE attempt_id IN (SELECT id FROM attempts WHERE user_id = p_user_id);
  DELETE FROM attempts WHERE user_id = p_user_id;
  DELETE FROM mission_items WHERE user_id = p_user_id;
  DELETE FROM streak_days WHERE user_id = p_user_id;
  DELETE FROM missions WHERE user_id = p_user_id;
  DELETE FROM memory_decisions WHERE user_id = p_user_id;
  DELETE FROM memory_events WHERE user_id = p_user_id;
  DELETE FROM learner_concept_states WHERE user_id = p_user_id;
  DELETE FROM reward_grants WHERE user_id = p_user_id;
  DELETE FROM xp_ledger WHERE user_id = p_user_id;
  DELETE FROM reef_projections WHERE user_id = p_user_id;
  DELETE FROM verification_decisions WHERE user_id = p_user_id;
  DELETE FROM verification_requests WHERE user_id = p_user_id;
  DELETE FROM knowledge_commits WHERE user_id = p_user_id;
  DELETE FROM private_knowledge_items WHERE user_id = p_user_id;
  DELETE FROM extraction_candidates WHERE user_id = p_user_id;
  DELETE FROM source_uploads WHERE user_id = p_user_id;
  DELETE FROM learning_updates WHERE user_id = p_user_id;
  DELETE FROM device_registrations WHERE user_id = p_user_id;
  DELETE FROM notification_preferences WHERE user_id = p_user_id;
  DELETE FROM user_profiles WHERE user_id = p_user_id;
  DELETE FROM idempotency_records WHERE user_id = p_user_id;
  DELETE FROM notification_deliveries WHERE user_id = p_user_id;
END
$$;
