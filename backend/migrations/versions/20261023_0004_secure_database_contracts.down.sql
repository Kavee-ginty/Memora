REVOKE EXECUTE ON FUNCTION memora_resolve_user_id(text, text) FROM memora_api;
DROP FUNCTION memora_resolve_user_id(text, text);

REVOKE SELECT, INSERT, UPDATE ON
  idempotency_records, outbox_events, background_jobs
FROM memora_worker;

GRANT SELECT, INSERT, UPDATE, DELETE ON
  learning_updates, source_uploads, extraction_candidates,
  verification_requests, verification_decisions, private_knowledge_items,
  knowledge_commits, learner_concept_states, memory_events, memory_decisions,
  missions, mission_items, attempts, grading_results, question_reports,
  xp_ledger, streak_days, reward_grants, reef_projections, privacy_requests,
  deletion_proofs, idempotency_records, outbox_events, background_jobs
TO memora_worker;

DROP TRIGGER grading_results_protect_evidence ON grading_results;
DROP FUNCTION memora_protect_grading_result();
CREATE TRIGGER grading_results_append_only
BEFORE UPDATE OR DELETE ON grading_results
FOR EACH ROW EXECUTE FUNCTION memora_forbid_mutation();

ALTER TABLE outbox_events DROP CONSTRAINT ck_outbox_publication_timestamp;
