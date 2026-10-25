REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM memora_api, memora_worker;

DROP POLICY IF EXISTS grading_results_owner ON grading_results;
ALTER TABLE grading_results DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS deletion_proofs_owner ON deletion_proofs;
ALTER TABLE deletion_proofs DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS idempotency_records_owner ON idempotency_records;
ALTER TABLE idempotency_records DISABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS concept_aliases_published_read ON concept_aliases;
ALTER TABLE concept_aliases DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS concept_objective_maps_published_read ON concept_objective_maps;
ALTER TABLE concept_objective_maps DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS question_options_published_read ON question_options;
ALTER TABLE question_options DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS question_rubrics_published_read ON question_rubrics;
ALTER TABLE question_rubrics DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS question_concept_maps_published_read ON question_concept_maps;
ALTER TABLE question_concept_maps DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS concept_embeddings_published_read ON concept_embeddings;
ALTER TABLE concept_embeddings DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS claim_embeddings_published_read ON claim_embeddings;
ALTER TABLE claim_embeddings DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS question_embeddings_published_read ON question_embeddings;
ALTER TABLE question_embeddings DISABLE ROW LEVEL SECURITY;

DO $$
DECLARE
  table_name text;
BEGIN
  FOREACH table_name IN ARRAY ARRAY[
    'subjects', 'curriculum_versions', 'learning_objectives', 'concepts',
    'concept_versions', 'knowledge_claims', 'concept_edges', 'questions',
    'question_versions', 'reward_definitions'
  ]
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I_published_read ON %I', table_name, table_name);
    EXECUTE format('ALTER TABLE %I DISABLE ROW LEVEL SECURITY', table_name);
  END LOOP;
END $$;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO memora_api, memora_worker;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO memora_api, memora_worker;
