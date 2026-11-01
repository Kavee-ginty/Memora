REVOKE ALL ON FUNCTION memora_mark_export_archives_deleted(uuid[], timestamptz)
FROM memora_worker;
DROP FUNCTION memora_mark_export_archives_deleted(uuid[], timestamptz);

REVOKE ALL ON FUNCTION memora_expired_export_archives(timestamptz) FROM memora_worker;
DROP FUNCTION memora_expired_export_archives(timestamptz);

REVOKE ALL ON FUNCTION memora_finalize_privacy_reconciliation(uuid, timestamptz)
FROM memora_worker;
DROP FUNCTION memora_finalize_privacy_reconciliation(uuid, timestamptz);

REVOKE ALL ON FUNCTION memora_privacy_reconciliation_state() FROM memora_worker;
DROP FUNCTION memora_privacy_reconciliation_state();

REVOKE ALL ON FUNCTION memora_delete_learner_data(uuid) FROM memora_api, memora_worker;
DROP FUNCTION memora_delete_learner_data(uuid);

REVOKE ALL ON FUNCTION memora_resolve_privacy_request_user(uuid, text) FROM memora_api;
DROP FUNCTION memora_resolve_privacy_request_user(uuid, text);

ALTER TABLE privacy_requests
  DROP COLUMN export_archive_deleted_at,
  DROP COLUMN requester_fingerprint;

ALTER TABLE deletion_proofs
  DROP CONSTRAINT deletion_proofs_target_check,
  DROP CONSTRAINT deletion_proofs_source_upload_id_fkey;

ALTER TABLE deletion_proofs
  ADD CONSTRAINT deletion_proofs_source_upload_id_fkey
    FOREIGN KEY (source_upload_id) REFERENCES source_uploads(id),
  ADD CONSTRAINT deletion_proofs_check
    CHECK ((privacy_request_id IS NULL) <> (source_upload_id IS NULL));

CREATE OR REPLACE FUNCTION memora_forbid_mutation() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION '% is append-only', TG_TABLE_NAME USING ERRCODE='55000';
END
$$;

CREATE OR REPLACE FUNCTION memora_protect_grading_result() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
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
