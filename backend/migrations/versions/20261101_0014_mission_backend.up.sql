ALTER TABLE missions
ADD COLUMN completion_summary jsonb;

UPDATE missions m
SET completed_at = COALESCE(m.completed_at, m.updated_at, m.created_at),
    completion_summary = jsonb_build_object(
      'mission_id', m.id,
      'status', 'completed',
      'protected_count', 0,
      'repaired_count', 0,
      'skipped_count', (
        SELECT count(*) FROM mission_items i
        WHERE i.mission_id = m.id AND i.status = 'skipped'
      ),
      'completed_at', COALESCE(m.completed_at, m.updated_at, m.created_at),
      'engagement_status', 'pending',
      'next_suggested_action', 'home'
    )
WHERE m.status = 'completed';

ALTER TABLE missions
ADD CONSTRAINT ck_missions_completion_summary_object
  CHECK (completion_summary IS NULL OR jsonb_typeof(completion_summary) = 'object'),
ADD CONSTRAINT ck_missions_item_bound CHECK (planned_item_count <= 7),
ADD CONSTRAINT ck_missions_duration_bound CHECK (estimated_minutes <= 7),
ADD CONSTRAINT ck_missions_completion_state CHECK (
  (status = 'completed') = (completed_at IS NOT NULL AND completion_summary IS NOT NULL)
);

ALTER TABLE attempts
ADD COLUMN request_hash text,
ADD CONSTRAINT ck_attempts_request_hash CHECK (
  request_hash IS NULL OR request_hash ~ '^[0-9a-f]{64}$'
);

CREATE INDEX ix_mission_items_current
ON mission_items(mission_id, position)
WHERE status IN ('pending', 'presented');

CREATE INDEX ix_question_concept_maps_mission_selection
ON question_concept_maps(concept_version_id, mapping_role, question_version_id);

