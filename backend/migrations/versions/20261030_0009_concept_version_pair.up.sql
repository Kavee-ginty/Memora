-- T11 review fix: a learner-concept state must never pair one concept's
-- stable identity with another concept's version. The composite foreign key
-- makes the (version, concept) pair enforceable for every write path,
-- including the SECURITY DEFINER persistence function.

CREATE UNIQUE INDEX uq_concept_versions_id_concept
  ON concept_versions(id, concept_id);

ALTER TABLE learner_concept_states
  ADD CONSTRAINT fk_learner_concept_states_active_version
  FOREIGN KEY (active_concept_version_id, concept_id)
  REFERENCES concept_versions(id, concept_id);
