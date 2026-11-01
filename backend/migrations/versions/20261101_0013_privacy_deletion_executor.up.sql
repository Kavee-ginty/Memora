CREATE OR REPLACE FUNCTION memora_forbid_mutation() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF current_setting('memora.privacy_deletion', true) = 'on'
     AND current_user NOT IN ('memora_api', 'memora_worker') THEN
    IF TG_OP = 'DELETE' THEN
      RETURN OLD;
    END IF;
    IF TG_OP = 'UPDATE'
       AND TG_TABLE_NAME = 'deletion_proofs'
       AND OLD.source_upload_id IS NOT NULL
       AND NEW.source_upload_id IS NULL
       AND (to_jsonb(NEW) - 'source_upload_id') = (to_jsonb(OLD) - 'source_upload_id') THEN
      RETURN NEW;
    END IF;
  END IF;
  RAISE EXCEPTION '% is append-only', TG_TABLE_NAME USING ERRCODE='55000';
END
$$;

CREATE OR REPLACE FUNCTION memora_protect_grading_result() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    IF current_setting('memora.privacy_deletion', true) = 'on'
       AND current_user NOT IN ('memora_api', 'memora_worker') THEN
      RETURN OLD;
    END IF;
    RAISE EXCEPTION 'grading_results is append-only' USING ERRCODE = '55000';
  END IF;

  IF (to_jsonb(NEW) - 'is_authoritative')
      IS DISTINCT FROM (to_jsonb(OLD) - 'is_authoritative')
    OR OLD.is_authoritative IS NOT TRUE
    OR NEW.is_authoritative IS NOT FALSE
  THEN
    RAISE EXCEPTION 'grading result evidence is immutable' USING ERRCODE = '55000';
  END IF;

  RETURN NEW;
END
$$;

ALTER TABLE deletion_proofs
  DROP CONSTRAINT deletion_proofs_source_upload_id_fkey,
  DROP CONSTRAINT deletion_proofs_check;

ALTER TABLE deletion_proofs
  ADD CONSTRAINT deletion_proofs_source_upload_id_fkey
    FOREIGN KEY (source_upload_id) REFERENCES source_uploads(id) ON DELETE SET NULL,
  ADD CONSTRAINT deletion_proofs_target_check
    CHECK (privacy_request_id IS NOT NULL OR source_upload_id IS NOT NULL OR target_fingerprint <> '');

ALTER TABLE privacy_requests
  ADD COLUMN export_archive_deleted_at timestamptz,
  ADD COLUMN requester_fingerprint text;

CREATE FUNCTION memora_resolve_privacy_request_user(
  p_request_id uuid,
  p_requester_fingerprint text
) RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT user_id
  FROM privacy_requests
  WHERE id = p_request_id
    AND requester_fingerprint = p_requester_fingerprint
$$;

REVOKE ALL ON FUNCTION memora_resolve_privacy_request_user(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION memora_resolve_privacy_request_user(uuid, text) TO memora_api;

CREATE FUNCTION memora_delete_learner_data(p_user_id uuid) RETURNS void
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
END
$$;

REVOKE ALL ON FUNCTION memora_delete_learner_data(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION memora_delete_learner_data(uuid) TO memora_api, memora_worker;

CREATE FUNCTION memora_privacy_reconciliation_state()
RETURNS TABLE(
  user_id uuid,
  oidc_subject text,
  learner_rows_exist boolean,
  upload_keys text[],
  export_request_ids uuid[]
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT
    u.id,
    u.oidc_subject,
    EXISTS (SELECT 1 FROM question_reports t WHERE t.user_id = u.id)
      OR EXISTS (SELECT 1 FROM learner_concept_states t WHERE t.user_id = u.id)
      OR EXISTS (SELECT 1 FROM private_knowledge_items t WHERE t.user_id = u.id)
      OR EXISTS (SELECT 1 FROM attempts t WHERE t.user_id = u.id)
      OR EXISTS (SELECT 1 FROM missions t WHERE t.user_id = u.id)
      OR EXISTS (SELECT 1 FROM mission_items t WHERE t.user_id = u.id)
      OR EXISTS (SELECT 1 FROM memory_events t WHERE t.user_id = u.id)
      OR EXISTS (SELECT 1 FROM memory_decisions t WHERE t.user_id = u.id)
      OR EXISTS (SELECT 1 FROM xp_ledger t WHERE t.user_id = u.id)
      OR EXISTS (SELECT 1 FROM streak_days t WHERE t.user_id = u.id)
      OR EXISTS (SELECT 1 FROM reward_grants t WHERE t.user_id = u.id)
      OR EXISTS (SELECT 1 FROM reef_projections t WHERE t.user_id = u.id)
      OR EXISTS (SELECT 1 FROM learning_updates t WHERE t.user_id = u.id)
      OR EXISTS (SELECT 1 FROM source_uploads t WHERE t.user_id = u.id)
      OR EXISTS (SELECT 1 FROM extraction_candidates t WHERE t.user_id = u.id)
      OR EXISTS (SELECT 1 FROM verification_requests t WHERE t.user_id = u.id)
      OR EXISTS (SELECT 1 FROM verification_decisions t WHERE t.user_id = u.id)
      OR EXISTS (SELECT 1 FROM knowledge_commits t WHERE t.user_id = u.id)
      OR EXISTS (SELECT 1 FROM device_registrations t WHERE t.user_id = u.id)
      OR EXISTS (SELECT 1 FROM notification_preferences t WHERE t.user_id = u.id)
      OR EXISTS (SELECT 1 FROM user_profiles t WHERE t.user_id = u.id)
      OR EXISTS (SELECT 1 FROM idempotency_records t WHERE t.user_id = u.id),
    ARRAY(
      SELECT su.object_key FROM source_uploads su WHERE su.user_id = u.id
    ),
    ARRAY(
      SELECT pr.id FROM privacy_requests pr
      WHERE pr.user_id = u.id
        AND pr.request_type = 'export'
        AND pr.export_archive_deleted_at IS NULL
    )
  FROM users u
  WHERE u.status = 'deleted'
     OR EXISTS (
       SELECT 1 FROM privacy_requests pr
       WHERE pr.user_id = u.id
         AND pr.request_type = 'delete'
         AND pr.status = 'completed'
     )
$$;

REVOKE ALL ON FUNCTION memora_privacy_reconciliation_state() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION memora_privacy_reconciliation_state() TO memora_worker;

CREATE FUNCTION memora_finalize_privacy_reconciliation(
  p_user_id uuid,
  p_now timestamptz
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF current_setting('role', true) <> 'memora_worker' THEN
    RAISE EXCEPTION 'privacy reconciliation is worker-only' USING ERRCODE = '42501';
  END IF;

  PERFORM memora_delete_learner_data(p_user_id);

  UPDATE privacy_requests
  SET export_archive_deleted_at = p_now
  WHERE user_id = p_user_id AND request_type = 'export';

  UPDATE users
  SET oidc_subject = 'deleted:' || id::text,
      status = 'deleted',
      deleted_at = coalesce(deleted_at, p_now),
      updated_at = p_now,
      row_version = row_version + 1
  WHERE id = p_user_id;
END
$$;

REVOKE ALL ON FUNCTION memora_finalize_privacy_reconciliation(uuid, timestamptz) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION memora_finalize_privacy_reconciliation(uuid, timestamptz)
TO memora_worker;

CREATE FUNCTION memora_expired_export_archives(p_expires_before timestamptz)
RETURNS TABLE(request_id uuid)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT id
  FROM privacy_requests
  WHERE request_type = 'export'
    AND status = 'completed'
    AND export_archive_deleted_at IS NULL
    AND completed_at <= p_expires_before
  FOR UPDATE SKIP LOCKED
$$;

REVOKE ALL ON FUNCTION memora_expired_export_archives(timestamptz) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION memora_expired_export_archives(timestamptz) TO memora_worker;

CREATE FUNCTION memora_mark_export_archives_deleted(
  p_request_ids uuid[],
  p_now timestamptz
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF current_setting('role', true) <> 'memora_worker' THEN
    RAISE EXCEPTION 'export archive reconciliation is worker-only' USING ERRCODE = '42501';
  END IF;

  UPDATE privacy_requests
  SET export_archive_deleted_at = p_now
  WHERE id = ANY(p_request_ids)
    AND request_type = 'export'
    AND status = 'completed';
END
$$;

REVOKE ALL ON FUNCTION memora_mark_export_archives_deleted(uuid[], timestamptz) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION memora_mark_export_archives_deleted(uuid[], timestamptz)
TO memora_worker;
