REVOKE EXECUTE ON FUNCTION memora_expire_ingestion(timestamptz) FROM memora_worker;
DROP FUNCTION IF EXISTS memora_expire_ingestion(timestamptz);

DROP FUNCTION IF EXISTS memora_ingestion_mark_update(uuid, uuid, text, text);
DROP FUNCTION IF EXISTS memora_ingestion_context(uuid, uuid);

DROP INDEX IF EXISTS uq_deletion_proofs_source_scope;
DROP INDEX IF EXISTS ix_knowledge_commits_owner;
DROP INDEX IF EXISTS ix_verification_requests_update;
DROP INDEX IF EXISTS ix_extraction_candidates_expiry;
DROP INDEX IF EXISTS ix_source_uploads_update;
DROP INDEX IF EXISTS ix_learning_updates_owner_updated;

REVOKE SELECT, INSERT, UPDATE ON background_jobs FROM memora_api;
REVOKE SELECT ON privacy_requests FROM memora_worker;
REVOKE SELECT, INSERT ON deletion_proofs FROM memora_worker;
REVOKE SELECT, INSERT, UPDATE, DELETE ON verification_requests FROM memora_worker;
REVOKE SELECT, INSERT, UPDATE, DELETE ON extraction_candidates FROM memora_worker;
REVOKE SELECT, UPDATE ON source_uploads FROM memora_worker;
