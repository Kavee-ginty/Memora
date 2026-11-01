DROP INDEX IF EXISTS ix_question_concept_maps_mission_selection;
DROP INDEX IF EXISTS ix_mission_items_current;

ALTER TABLE attempts
DROP CONSTRAINT IF EXISTS ck_attempts_request_hash,
DROP COLUMN IF EXISTS request_hash;

ALTER TABLE missions
DROP CONSTRAINT IF EXISTS ck_missions_completion_state,
DROP CONSTRAINT IF EXISTS ck_missions_duration_bound,
DROP CONSTRAINT IF EXISTS ck_missions_item_bound,
DROP CONSTRAINT IF EXISTS ck_missions_completion_summary_object,
DROP COLUMN IF EXISTS completion_summary;
