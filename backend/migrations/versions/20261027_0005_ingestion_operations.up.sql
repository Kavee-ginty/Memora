-- T09 ingestion operations: worker access, query indexes and deletion proof guard.

GRANT SELECT, INSERT, UPDATE ON background_jobs TO memora_api;

GRANT SELECT, UPDATE ON source_uploads TO memora_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON extraction_candidates TO memora_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON verification_requests TO memora_worker;
GRANT SELECT, INSERT ON deletion_proofs TO memora_worker;
GRANT SELECT ON privacy_requests TO memora_worker;

CREATE INDEX ix_learning_updates_owner_updated
  ON learning_updates(user_id, updated_at DESC);
CREATE INDEX ix_source_uploads_update
  ON source_uploads(learning_update_id, created_at);
CREATE INDEX ix_extraction_candidates_expiry
  ON extraction_candidates(status, expires_at);
CREATE INDEX ix_verification_requests_update
  ON verification_requests(learning_update_id, status);
CREATE INDEX ix_knowledge_commits_owner
  ON knowledge_commits(user_id, committed_at DESC);

-- A deleted source has exactly one proof for a given verification scope/provider.
CREATE UNIQUE INDEX uq_deletion_proofs_source_scope
  ON deletion_proofs(source_upload_id, scope, provider)
  WHERE source_upload_id IS NOT NULL;

-- The worker never reads or writes learning_updates directly. Table-level access
-- stays denied; these owner-checked functions return only the fields one job needs
-- and enforce the owner in the function body.
CREATE OR REPLACE FUNCTION memora_ingestion_context(p_update_id uuid, p_user_id uuid)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT jsonb_build_object(
    'update', jsonb_build_object(
      'id', lu.id, 'user_id', lu.user_id, 'subject_id', lu.subject_id,
      'input_type', lu.input_type, 'status', lu.status,
      'manual_text_ciphertext', encode(lu.manual_text_ciphertext, 'base64'),
      'curriculum_version_id', lu.curriculum_version_id
    ),
    'upload', (
      SELECT jsonb_build_object(
        'id', su.id, 'object_key', su.object_key,
        'declared_name', su.declared_name,
        'declared_media_type', su.declared_media_type,
        'byte_size', su.byte_size, 'content_sha256', su.content_sha256,
        'status', su.status
      )
      FROM source_uploads su
      WHERE su.learning_update_id = lu.id AND su.user_id = lu.user_id
        AND su.status IN ('processing','validated','uploaded')
      ORDER BY su.created_at
      LIMIT 1
    )
  )
  FROM learning_updates lu
  WHERE lu.id = p_update_id AND lu.user_id = p_user_id
$$;

CREATE OR REPLACE FUNCTION memora_ingestion_mark_update(
  p_update_id uuid, p_user_id uuid, p_status text, p_failure_code text
)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  UPDATE learning_updates
  SET status = p_status, failure_code = p_failure_code,
      updated_at = now(), row_version = row_version + 1
  WHERE id = p_update_id AND user_id = p_user_id AND status = 'processing'
  RETURNING true
$$;

REVOKE ALL ON FUNCTION memora_ingestion_context(uuid, uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION memora_ingestion_mark_update(uuid, uuid, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION memora_ingestion_context(uuid, uuid) TO memora_worker;
GRANT EXECUTE ON FUNCTION memora_ingestion_mark_update(uuid, uuid, text, text)
TO memora_worker;

-- Scheduled expiry is a reviewed security-definer operation so the worker does
-- not need broad table read access outside a single owner's job context.
CREATE OR REPLACE FUNCTION memora_expire_ingestion(p_now timestamptz)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  expired_updates integer := 0;
BEGIN
  UPDATE extraction_candidates
  SET status = 'expired', updated_at = now(), row_version = row_version + 1
  WHERE status IN ('candidate','needs_verification') AND expires_at < p_now;

  UPDATE verification_requests
  SET status = 'expired', updated_at = now(), row_version = row_version + 1
  WHERE status = 'pending' AND expires_at < p_now;

  UPDATE source_uploads
  SET status = 'expired', updated_at = now(), row_version = row_version + 1
  WHERE status IN ('authorized','uploaded','validated')
    AND expires_at < p_now;

  INSERT INTO background_jobs(
    job_type, owner_user_id, resource_type, resource_id,
    dedupe_key, status, max_attempts, available_at, payload
  )
  SELECT 'ingestion.delete_upload', user_id, 'source_upload', id,
         'delete_upload:' || id, 'queued', 5, now(), '{"schema_version":"1"}'::jsonb
  FROM source_uploads
  WHERE status = 'expired' AND deleted_at IS NULL
  ON CONFLICT (dedupe_key) DO NOTHING;

  UPDATE learning_updates
  SET status = 'expired', updated_at = now(), row_version = row_version + 1
  WHERE status IN ('draft','uploading','processing','verification_required','failed')
    AND expires_at < p_now;
  GET DIAGNOSTICS expired_updates = ROW_COUNT;

  RETURN expired_updates;
END $$;

REVOKE ALL ON FUNCTION memora_expire_ingestion(timestamptz) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION memora_expire_ingestion(timestamptz) TO memora_worker;
