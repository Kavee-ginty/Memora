DROP POLICY question_concept_maps_pinned_read ON question_concept_maps;
DROP POLICY question_rubrics_pinned_read ON question_rubrics;
DROP POLICY question_options_pinned_read ON question_options;
DROP POLICY questions_pinned_read ON questions;
DROP POLICY question_versions_pinned_read ON question_versions;

DROP TRIGGER question_reports_protect_provenance ON question_reports;
DROP FUNCTION memora_protect_question_report_provenance();

DROP TRIGGER question_versions_publication_guard ON question_versions;
DROP FUNCTION memora_validate_question_publication();

DROP TRIGGER question_concept_maps_protect_content ON question_concept_maps;
DROP TRIGGER question_rubrics_protect_content ON question_rubrics;
DROP TRIGGER question_options_protect_content ON question_options;
DROP FUNCTION memora_protect_question_child();

DROP TRIGGER question_versions_used_immutable ON question_versions;
DROP FUNCTION memora_protect_used_question_version();

DROP TRIGGER questions_protect_identity ON questions;
DROP FUNCTION memora_protect_question_identity();

DROP FUNCTION memora_question_version_is_pinned(uuid);

ALTER TABLE question_reports DROP CONSTRAINT ck_question_reports_resolution_time;
DROP INDEX ix_mission_items_question_version;
DROP INDEX ix_question_reports_owner_history;
