REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM memora_api, memora_worker;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM memora_api, memora_worker;

GRANT USAGE ON SCHEMA public TO memora_api, memora_worker;

DO $$
DECLARE
  table_name text;
  status_column text;
BEGIN
  FOR table_name, status_column IN
    SELECT * FROM (VALUES
      ('subjects', 'status'),
      ('curriculum_versions', 'status'),
      ('learning_objectives', 'status'),
      ('concepts', 'status'),
      ('concept_versions', 'content_status'),
      ('knowledge_claims', 'status'),
      ('concept_edges', 'status'),
      ('questions', 'status'),
      ('question_versions', 'validation_status'),
      ('reward_definitions', 'status')
    ) AS published_tables(table_name, status_column)
  LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', table_name);
    EXECUTE format('ALTER TABLE %I FORCE ROW LEVEL SECURITY', table_name);
    EXECUTE format(
      'CREATE POLICY %I_published_read ON %I FOR SELECT USING (%I = ''approved'')',
      table_name,
      table_name,
      status_column
    );
  END LOOP;
END $$;

ALTER TABLE concept_aliases ENABLE ROW LEVEL SECURITY;
ALTER TABLE concept_aliases FORCE ROW LEVEL SECURITY;
CREATE POLICY concept_aliases_published_read ON concept_aliases FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM concept_versions
    WHERE concept_versions.id = concept_aliases.concept_version_id
      AND concept_versions.content_status = 'approved'
  )
);

ALTER TABLE concept_objective_maps ENABLE ROW LEVEL SECURITY;
ALTER TABLE concept_objective_maps FORCE ROW LEVEL SECURITY;
CREATE POLICY concept_objective_maps_published_read ON concept_objective_maps FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM concept_versions
    WHERE concept_versions.id = concept_objective_maps.concept_version_id
      AND concept_versions.content_status = 'approved'
  )
  AND EXISTS (
    SELECT 1 FROM learning_objectives
    WHERE learning_objectives.id = concept_objective_maps.learning_objective_id
      AND learning_objectives.status = 'approved'
  )
);

ALTER TABLE question_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE question_options FORCE ROW LEVEL SECURITY;
CREATE POLICY question_options_published_read ON question_options FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM question_versions
    WHERE question_versions.id = question_options.question_version_id
      AND question_versions.validation_status = 'approved'
  )
);

ALTER TABLE question_rubrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE question_rubrics FORCE ROW LEVEL SECURITY;
CREATE POLICY question_rubrics_published_read ON question_rubrics FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM question_versions
    WHERE question_versions.id = question_rubrics.question_version_id
      AND question_versions.validation_status = 'approved'
  )
);

ALTER TABLE question_concept_maps ENABLE ROW LEVEL SECURITY;
ALTER TABLE question_concept_maps FORCE ROW LEVEL SECURITY;
CREATE POLICY question_concept_maps_published_read ON question_concept_maps FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM question_versions
    WHERE question_versions.id = question_concept_maps.question_version_id
      AND question_versions.validation_status = 'approved'
  )
);

ALTER TABLE concept_embeddings ENABLE ROW LEVEL SECURITY;
ALTER TABLE concept_embeddings FORCE ROW LEVEL SECURITY;
CREATE POLICY concept_embeddings_published_read ON concept_embeddings FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM concept_versions
    WHERE concept_versions.id = concept_embeddings.concept_version_id
      AND concept_versions.content_status = 'approved'
  )
);

ALTER TABLE claim_embeddings ENABLE ROW LEVEL SECURITY;
ALTER TABLE claim_embeddings FORCE ROW LEVEL SECURITY;
CREATE POLICY claim_embeddings_published_read ON claim_embeddings FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM knowledge_claims
    WHERE knowledge_claims.id = claim_embeddings.knowledge_claim_id
      AND knowledge_claims.status = 'approved'
  )
);

ALTER TABLE question_embeddings ENABLE ROW LEVEL SECURITY;
ALTER TABLE question_embeddings FORCE ROW LEVEL SECURITY;
CREATE POLICY question_embeddings_published_read ON question_embeddings FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM question_versions
    WHERE question_versions.id = question_embeddings.question_version_id
      AND question_versions.validation_status = 'approved'
  )
);

ALTER TABLE grading_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE grading_results FORCE ROW LEVEL SECURITY;
CREATE POLICY grading_results_owner ON grading_results USING (
  EXISTS (
    SELECT 1 FROM attempts
    WHERE attempts.id = grading_results.attempt_id
      AND attempts.user_id = nullif(current_setting('memora.user_id', true), '')::uuid
  )
) WITH CHECK (
  EXISTS (
    SELECT 1 FROM attempts
    WHERE attempts.id = grading_results.attempt_id
      AND attempts.user_id = nullif(current_setting('memora.user_id', true), '')::uuid
  )
);

ALTER TABLE deletion_proofs ENABLE ROW LEVEL SECURITY;
ALTER TABLE deletion_proofs FORCE ROW LEVEL SECURITY;
CREATE POLICY deletion_proofs_owner ON deletion_proofs USING (
  EXISTS (
    SELECT 1 FROM privacy_requests
    WHERE privacy_requests.id = deletion_proofs.privacy_request_id
      AND privacy_requests.user_id = nullif(current_setting('memora.user_id', true), '')::uuid
  )
  OR EXISTS (
    SELECT 1 FROM source_uploads
    WHERE source_uploads.id = deletion_proofs.source_upload_id
      AND source_uploads.user_id = nullif(current_setting('memora.user_id', true), '')::uuid
  )
) WITH CHECK (
  EXISTS (
    SELECT 1 FROM privacy_requests
    WHERE privacy_requests.id = deletion_proofs.privacy_request_id
      AND privacy_requests.user_id = nullif(current_setting('memora.user_id', true), '')::uuid
  )
  OR EXISTS (
    SELECT 1 FROM source_uploads
    WHERE source_uploads.id = deletion_proofs.source_upload_id
      AND source_uploads.user_id = nullif(current_setting('memora.user_id', true), '')::uuid
  )
);

ALTER TABLE idempotency_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE idempotency_records FORCE ROW LEVEL SECURITY;
CREATE POLICY idempotency_records_owner ON idempotency_records USING (
  user_id = nullif(current_setting('memora.user_id', true), '')::uuid
) WITH CHECK (
  user_id = nullif(current_setting('memora.user_id', true), '')::uuid
);

GRANT SELECT ON
  subjects, curriculum_versions, learning_objectives, concepts, concept_versions,
  concept_aliases, knowledge_claims, concept_edges, concept_objective_maps,
  questions, question_versions, question_options, question_rubrics,
  question_concept_maps, concept_embeddings, claim_embeddings,
  question_embeddings, reward_definitions
TO memora_api, memora_worker;

GRANT SELECT, INSERT, UPDATE, DELETE ON
  users, user_profiles, consent_records, device_registrations,
  notification_preferences, learning_updates, source_uploads,
  extraction_candidates, verification_requests, verification_decisions,
  private_knowledge_items, knowledge_commits, learner_concept_states,
  memory_events, memory_decisions, missions, mission_items, attempts,
  grading_results, question_reports, xp_ledger, streak_days, reward_grants,
  reef_projections, privacy_requests, deletion_proofs, idempotency_records
TO memora_api;

GRANT SELECT, INSERT, UPDATE, DELETE ON
  learning_updates, source_uploads, extraction_candidates,
  verification_requests, verification_decisions, private_knowledge_items,
  knowledge_commits, learner_concept_states, memory_events, memory_decisions,
  missions, mission_items, attempts, grading_results, question_reports,
  xp_ledger, streak_days, reward_grants, reef_projections, privacy_requests,
  deletion_proofs, idempotency_records, outbox_events, background_jobs
TO memora_worker;

GRANT INSERT ON outbox_events, background_jobs, audit_events TO memora_api;
GRANT INSERT ON audit_events TO memora_worker;
