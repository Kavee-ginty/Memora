-- Question bank integrity: immutable published/used content, publication
-- prerequisites and owner-scoped reads for pinned historical versions.

CREATE INDEX ix_question_reports_owner_history
ON question_reports(user_id, submitted_at DESC, id DESC);

CREATE INDEX ix_mission_items_question_version
ON mission_items(question_version_id, user_id);

ALTER TABLE question_reports
ADD CONSTRAINT ck_question_reports_resolution_time
CHECK ((status IN ('resolved', 'dismissed')) = (resolved_at IS NOT NULL));

CREATE FUNCTION memora_question_version_is_pinned(p_question_version_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.mission_items
    WHERE question_version_id = p_question_version_id
  )
$$;

REVOKE ALL ON FUNCTION memora_question_version_is_pinned(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION memora_question_version_is_pinned(uuid) TO memora_api, memora_worker;

CREATE FUNCTION memora_protect_question_identity() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    IF EXISTS (
      SELECT 1 FROM question_versions WHERE question_id = OLD.id
    ) THEN
      RAISE EXCEPTION 'question identity with versions is immutable'
        USING ERRCODE = '55000';
    END IF;
    RETURN OLD;
  END IF;

  IF NEW.id IS DISTINCT FROM OLD.id
    OR NEW.subject_id IS DISTINCT FROM OLD.subject_id
    OR NEW.question_code IS DISTINCT FROM OLD.question_code
    OR NEW.source_class IS DISTINCT FROM OLD.source_class
    OR NEW.created_at IS DISTINCT FROM OLD.created_at
  THEN
    RAISE EXCEPTION 'question identity is immutable'
      USING ERRCODE = '55000';
  END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER questions_protect_identity
BEFORE UPDATE OR DELETE ON questions
FOR EACH ROW EXECUTE FUNCTION memora_protect_question_identity();

CREATE FUNCTION memora_protect_used_question_version() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF memora_question_version_is_pinned(OLD.id) THEN
    RAISE EXCEPTION 'question version is immutable after use'
      USING ERRCODE = '55000';
  END IF;
  RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
END $$;

CREATE TRIGGER question_versions_used_immutable
BEFORE UPDATE OR DELETE ON question_versions
FOR EACH ROW
WHEN (OLD.validation_status = 'draft')
EXECUTE FUNCTION memora_protect_used_question_version();

CREATE FUNCTION memora_protect_question_child() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
  v_question_version_id uuid;
  v_validation_status text;
BEGIN
  IF TG_OP = 'DELETE' THEN
    v_question_version_id := OLD.question_version_id;
  ELSE
    v_question_version_id := NEW.question_version_id;
  END IF;

  IF TG_OP = 'UPDATE'
    AND NEW.question_version_id IS DISTINCT FROM OLD.question_version_id
  THEN
    RAISE EXCEPTION 'question content cannot move between versions'
      USING ERRCODE = '55000';
  END IF;

  SELECT validation_status INTO v_validation_status
  FROM question_versions
  WHERE id = v_question_version_id;

  -- A child row inserted by the same data-modifying statement cannot see its
  -- new parent. The deferred publication guard validates the completed set.
  IF TG_OP = 'INSERT' AND v_validation_status IS NULL THEN
    RETURN NEW;
  END IF;

  IF v_validation_status IS DISTINCT FROM 'draft'
    OR memora_question_version_is_pinned(v_question_version_id)
  THEN
    RAISE EXCEPTION 'question content is immutable after publication or use'
      USING ERRCODE = '55000';
  END IF;

  RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
END $$;

CREATE TRIGGER question_options_protect_content
BEFORE INSERT OR UPDATE OR DELETE ON question_options
FOR EACH ROW EXECUTE FUNCTION memora_protect_question_child();

CREATE TRIGGER question_rubrics_protect_content
BEFORE INSERT OR UPDATE OR DELETE ON question_rubrics
FOR EACH ROW EXECUTE FUNCTION memora_protect_question_child();

CREATE TRIGGER question_concept_maps_protect_content
BEFORE INSERT OR UPDATE OR DELETE ON question_concept_maps
FOR EACH ROW EXECUTE FUNCTION memora_protect_question_child();

CREATE FUNCTION memora_validate_question_publication() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
  v_question_status text;
  v_source_class text;
  v_author_principal uuid;
  v_reviewer_principal uuid;
  v_explanation text;
  v_question_type text;
  v_content_payload jsonb;
  v_model_key text;
  v_prompt_version text;
  v_grounding_evidence_ids uuid[];
  v_validator_version text;
  v_validation_score numeric;
  v_generation_trace_ref text;
  v_rubric_status text;
  v_evidence_ceiling numeric;
  v_rubric_payload jsonb;
  v_option_count integer;
  v_correct_option_count integer;
BEGIN
  IF NEW.validation_status <> 'approved' THEN
    RETURN NEW;
  END IF;

  SELECT q.status, q.source_class, q.author_principal, q.reviewer_principal,
         qv.explanation, qv.question_type, qv.content_payload,
         qv.model_key, qv.prompt_version, qv.grounding_evidence_ids,
         qv.validator_version, qv.validation_score, qv.generation_trace_ref
  INTO v_question_status, v_source_class, v_author_principal,
       v_reviewer_principal, v_explanation, v_question_type,
       v_content_payload, v_model_key, v_prompt_version,
       v_grounding_evidence_ids, v_validator_version, v_validation_score,
       v_generation_trace_ref
  FROM question_versions qv
  JOIN questions q ON q.id = qv.question_id
  WHERE qv.id = NEW.id;

  IF v_question_status IS DISTINCT FROM 'approved' THEN
    RAISE EXCEPTION 'an approved question version needs an approved question'
      USING ERRCODE = '23514';
  END IF;

  IF v_explanation IS NULL OR btrim(v_explanation) = '' THEN
    RAISE EXCEPTION 'an approved question version needs an explanation'
      USING ERRCODE = '23514';
  END IF;

  IF v_reviewer_principal IS NULL THEN
    RAISE EXCEPTION 'an approved question version needs a reviewer'
      USING ERRCODE = '23514';
  END IF;

  IF v_source_class <> 'ai_generated' AND v_author_principal IS NULL THEN
    RAISE EXCEPTION 'an approved question version needs an author'
      USING ERRCODE = '23514';
  END IF;

  IF v_source_class = 'ai_generated'
    AND (
      v_model_key IS NULL
      OR v_prompt_version IS NULL
      OR v_grounding_evidence_ids IS NULL
      OR cardinality(v_grounding_evidence_ids) = 0
      OR v_validator_version IS NULL
      OR v_validation_score IS NULL
      OR v_generation_trace_ref IS NULL
    )
  THEN
    RAISE EXCEPTION 'generated content needs grounding and validation evidence'
      USING ERRCODE = '23514';
  END IF;

  SELECT status, evidence_ceiling, rubric_payload
  INTO v_rubric_status, v_evidence_ceiling, v_rubric_payload
  FROM question_rubrics
  WHERE question_version_id = NEW.id;

  IF v_rubric_status IS DISTINCT FROM 'approved'
    OR v_evidence_ceiling IS NULL
    OR v_evidence_ceiling <= 0
  THEN
    RAISE EXCEPTION 'an approved question version needs an approved rubric'
      USING ERRCODE = '23514';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM question_concept_maps
    WHERE question_version_id = NEW.id
      AND mapping_role = 'primary'
      AND weight > 0
  ) THEN
    RAISE EXCEPTION 'an approved question version needs a primary concept mapping'
      USING ERRCODE = '23514';
  END IF;

  IF v_question_type IN ('mcq', 'diagram_interpretation') THEN
    SELECT count(*), count(*) FILTER (WHERE is_correct)
    INTO v_option_count, v_correct_option_count
    FROM question_options
    WHERE question_version_id = NEW.id;

    IF v_option_count < 2 OR v_option_count > 10 OR v_correct_option_count < 1 THEN
      RAISE EXCEPTION 'option-based questions need bounded options and a correct key'
        USING ERRCODE = '23514';
    END IF;

    IF v_content_payload->>'selection_mode' = 'single'
      AND v_correct_option_count <> 1
    THEN
      RAISE EXCEPTION 'single-choice questions need exactly one correct option'
        USING ERRCODE = '23514';
    END IF;
  END IF;

  IF v_question_type = 'numeric'
    AND v_rubric_payload->>'unit_rule' = 'required'
    AND COALESCE((v_content_payload->>'unit_affordance')::boolean, false) IS NOT TRUE
  THEN
    RAISE EXCEPTION 'a required-unit question needs a unit affordance'
      USING ERRCODE = '23514';
  END IF;

  RETURN NEW;
END $$;

CREATE CONSTRAINT TRIGGER question_versions_publication_guard
AFTER INSERT OR UPDATE ON question_versions
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION memora_validate_question_publication();

CREATE FUNCTION memora_protect_question_report_provenance() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;

  IF NEW.id IS DISTINCT FROM OLD.id
    OR NEW.user_id IS DISTINCT FROM OLD.user_id
    OR NEW.question_version_id IS DISTINCT FROM OLD.question_version_id
    OR NEW.attempt_id IS DISTINCT FROM OLD.attempt_id
    OR NEW.report_type IS DISTINCT FROM OLD.report_type
    OR NEW.description_ciphertext IS DISTINCT FROM OLD.description_ciphertext
    OR NEW.submitted_at IS DISTINCT FROM OLD.submitted_at
    OR NEW.created_at IS DISTINCT FROM OLD.created_at
  THEN
    RAISE EXCEPTION 'question report provenance is immutable'
      USING ERRCODE = '55000';
  END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER question_reports_protect_provenance
BEFORE UPDATE OR DELETE ON question_reports
FOR EACH ROW EXECUTE FUNCTION memora_protect_question_report_provenance();

-- A pinned version must stay readable even when it is no longer approved.
CREATE POLICY question_versions_pinned_read ON question_versions
FOR SELECT USING (
  EXISTS (
    SELECT 1
    FROM mission_items mi
    WHERE mi.question_version_id = question_versions.id
      AND mi.user_id = nullif(current_setting('memora.user_id', true), '')::uuid
  )
);

CREATE POLICY questions_pinned_read ON questions
FOR SELECT USING (
  EXISTS (
    SELECT 1
    FROM mission_items mi
    JOIN question_versions qv ON qv.id = mi.question_version_id
    WHERE qv.question_id = questions.id
      AND mi.user_id = nullif(current_setting('memora.user_id', true), '')::uuid
  )
);

CREATE POLICY question_options_pinned_read ON question_options
FOR SELECT USING (
  EXISTS (
    SELECT 1
    FROM mission_items mi
    WHERE mi.question_version_id = question_options.question_version_id
      AND mi.user_id = nullif(current_setting('memora.user_id', true), '')::uuid
  )
);

CREATE POLICY question_rubrics_pinned_read ON question_rubrics
FOR SELECT USING (
  EXISTS (
    SELECT 1
    FROM mission_items mi
    WHERE mi.question_version_id = question_rubrics.question_version_id
      AND mi.user_id = nullif(current_setting('memora.user_id', true), '')::uuid
  )
);

CREATE POLICY question_concept_maps_pinned_read ON question_concept_maps
FOR SELECT USING (
  EXISTS (
    SELECT 1
    FROM mission_items mi
    WHERE mi.question_version_id = question_concept_maps.question_version_id
      AND mi.user_id = nullif(current_setting('memora.user_id', true), '')::uuid
  )
);
