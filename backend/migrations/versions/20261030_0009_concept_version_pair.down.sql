-- Remove the concept/version pairing constraint.

ALTER TABLE learner_concept_states
  DROP CONSTRAINT IF EXISTS fk_learner_concept_states_active_version;

DROP INDEX IF EXISTS uq_concept_versions_id_concept;
