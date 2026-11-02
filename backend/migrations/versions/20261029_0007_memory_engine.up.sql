-- T11 memory engine: worker-safe write surface, closed reason-code
-- allowlists and the delivery-dedupe index.
--
-- Migration 0004 removed memora_worker DML on user tables. Memory writes
-- therefore go through SECURITY DEFINER functions that the worker only
-- executes: a context reader (which also takes the per-concept advisory
-- lock that serialises concurrent decisions for one learner-concept pair),
-- an append-or-confirm event recorder, and an atomic decision applier
-- (decision row + learner-concept snapshot upsert + one outbox event).

CREATE INDEX ix_memory_events_delivery ON memory_events(source_type, source_id);

ALTER TABLE memory_decisions
  ADD CONSTRAINT ck_memory_decisions_reason_codes
  CHECK (
    cardinality(reason_codes) > 0
    AND reason_codes <@ ARRAY[
      'state_initialized',
      'exposure_recorded',
      'recall_success',
      'recall_lapse',
      'review_scheduled',
      'out_of_order_evidence',
      'first_review_bounded',
      'evidence_justified_schedule',
      'comeback_elapsed',
      'low_confidence_damped',
      'weak_prerequisite_recover',
      'interval_bounded'
    ]::text[]
  );

ALTER TABLE memory_decisions
  ADD CONSTRAINT ck_memory_decisions_template_keys
  CHECK (explanation_template_key IN (
    'memory.explanation.state_initialized',
    'memory.explanation.exposure_recorded',
    'memory.explanation.recall_success',
    'memory.explanation.recall_lapse',
    'memory.explanation.first_review_scheduled',
    'memory.explanation.comeback',
    'memory.explanation.low_confidence',
    'memory.explanation.weak_prerequisite'
  ));

CREATE FUNCTION memora_memory_context(p_user_id uuid, p_concept_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_state jsonb;
BEGIN
  PERFORM pg_advisory_xact_lock(
    hashtextextended(p_user_id::text || ':' || p_concept_id::text, 11)
  );
  SELECT to_jsonb(lcs)
    - 'id'
    - 'user_id'
    - 'concept_id'
    - 'active_concept_version_id'
    - 'created_at'
    - 'updated_at'
    - 'row_version'
  INTO v_state
  FROM public.learner_concept_states lcs
  WHERE lcs.user_id = p_user_id
    AND lcs.concept_id = p_concept_id;
  RETURN v_state;
END $$;

CREATE FUNCTION memora_memory_record_event(
  p_user_id uuid,
  p_concept_id uuid,
  p_event_type text,
  p_source_type text,
  p_source_id uuid,
  p_observed_at timestamptz,
  p_score numeric,
  p_confidence numeric,
  p_is_eligible boolean,
  p_ineligibility_reason text,
  p_event_payload jsonb
)
RETURNS TABLE(event_id uuid, replayed boolean)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_event_id uuid;
BEGIN
  INSERT INTO public.memory_events(
    user_id, concept_id, event_type, source_type, source_id, observed_at,
    score, confidence, is_eligible, ineligibility_reason, event_payload
  ) VALUES (
    p_user_id, p_concept_id, p_event_type, p_source_type, p_source_id,
    p_observed_at, p_score, p_confidence, p_is_eligible,
    p_ineligibility_reason, p_event_payload
  )
  ON CONFLICT (event_type, source_type, source_id, concept_id) DO NOTHING
  RETURNING id INTO v_event_id;

  IF v_event_id IS NOT NULL THEN
    RETURN QUERY SELECT v_event_id, false;
    RETURN;
  END IF;

  SELECT e.id INTO v_event_id
  FROM public.memory_events e
  WHERE e.event_type = p_event_type
    AND e.source_type = p_source_type
    AND e.source_id = p_source_id
    AND e.concept_id = p_concept_id
    AND e.user_id = p_user_id;

  IF v_event_id IS NULL THEN
    RAISE EXCEPTION 'memory event identity collision across owners'
      USING ERRCODE = '23514';
  END IF;

  RETURN QUERY SELECT v_event_id, true;
END $$;

CREATE FUNCTION memora_memory_apply_decision(
  p_decision_id uuid,
  p_user_id uuid,
  p_concept_id uuid,
  p_active_concept_version_id uuid,
  p_trigger_event_id uuid,
  p_previous_state jsonb,
  p_result_state jsonb,
  p_retrievability_at_decision numeric,
  p_next_review_at timestamptz,
  p_reason_codes text[],
  p_explanation_template_key text,
  p_engine_version text,
  p_policy_version text,
  p_decided_at timestamptz,
  p_domain_event_key text,
  p_outbox_payload jsonb,
  p_correlation_id uuid
)
RETURNS TABLE(decision_id uuid, state_row_version integer, outbox_event_id uuid, replayed boolean)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_decision_id uuid;
  v_state_row_version integer;
  v_outbox_event_id uuid;
BEGIN
  SELECT d.id INTO v_decision_id
  FROM public.memory_decisions d
  WHERE d.trigger_event_id = p_trigger_event_id
    AND d.concept_id = p_concept_id
    AND d.engine_version = p_engine_version;

  IF v_decision_id IS NOT NULL THEN
    SELECT lcs.row_version INTO v_state_row_version
    FROM public.learner_concept_states lcs
    WHERE lcs.user_id = p_user_id AND lcs.concept_id = p_concept_id;
    RETURN QUERY SELECT v_decision_id, v_state_row_version, NULL::uuid, true;
    RETURN;
  END IF;

  INSERT INTO public.memory_decisions(
    id, user_id, concept_id, trigger_event_id, previous_state, result_state,
    retrievability_at_decision, next_review_at, reason_codes,
    explanation_template_key, engine_version, policy_version, decided_at
  ) VALUES (
    p_decision_id, p_user_id, p_concept_id, p_trigger_event_id,
    p_previous_state, p_result_state, p_retrievability_at_decision,
    p_next_review_at, p_reason_codes, p_explanation_template_key,
    p_engine_version, p_policy_version, p_decided_at
  )
  ON CONFLICT (trigger_event_id, concept_id, engine_version) DO NOTHING
  RETURNING id INTO v_decision_id;

  IF v_decision_id IS NULL THEN
    -- A concurrent transaction committed the same decision between the
    -- check and the insert; replay instead of writing a second outbox row.
    SELECT d.id INTO v_decision_id
    FROM public.memory_decisions d
    WHERE d.trigger_event_id = p_trigger_event_id
      AND d.concept_id = p_concept_id
      AND d.engine_version = p_engine_version;
    SELECT lcs.row_version INTO v_state_row_version
    FROM public.learner_concept_states lcs
    WHERE lcs.user_id = p_user_id AND lcs.concept_id = p_concept_id;
    RETURN QUERY SELECT v_decision_id, v_state_row_version, NULL::uuid, true;
    RETURN;
  END IF;

  INSERT INTO public.learner_concept_states(
    user_id, concept_id, active_concept_version_id,
    difficulty, stability_days, last_retrievability, evidence_confidence,
    first_exposed_at, last_reviewed_at, next_review_at,
    exposure_count, eligible_review_count, lapse_count, engine_version
  )
  VALUES (
    p_user_id, p_concept_id, p_active_concept_version_id,
    (p_result_state->>'difficulty')::numeric(8, 5),
    (p_result_state->>'stability_days')::numeric(12, 5),
    (p_result_state->>'last_retrievability')::numeric(6, 5),
    (p_result_state->>'evidence_confidence')::numeric(6, 5),
    (p_result_state->>'first_exposed_at')::timestamptz,
    (p_result_state->>'last_reviewed_at')::timestamptz,
    (p_result_state->>'next_review_at')::timestamptz,
    (p_result_state->>'exposure_count')::integer,
    (p_result_state->>'eligible_review_count')::integer,
    (p_result_state->>'lapse_count')::integer,
    p_result_state->>'engine_version'
  )
  ON CONFLICT (user_id, concept_id) DO UPDATE SET
    active_concept_version_id = EXCLUDED.active_concept_version_id,
    difficulty = EXCLUDED.difficulty,
    stability_days = EXCLUDED.stability_days,
    last_retrievability = EXCLUDED.last_retrievability,
    evidence_confidence = EXCLUDED.evidence_confidence,
    first_exposed_at = EXCLUDED.first_exposed_at,
    last_reviewed_at = EXCLUDED.last_reviewed_at,
    next_review_at = EXCLUDED.next_review_at,
    exposure_count = EXCLUDED.exposure_count,
    eligible_review_count = EXCLUDED.eligible_review_count,
    lapse_count = EXCLUDED.lapse_count,
    engine_version = EXCLUDED.engine_version,
    updated_at = now(),
    row_version = learner_concept_states.row_version + 1
  RETURNING row_version INTO v_state_row_version;

  INSERT INTO public.outbox_events(
    domain_event_key, aggregate_type, aggregate_id, event_type, event_version,
    payload, correlation_id, publication_status
  ) VALUES (
    p_domain_event_key,
    'memory_decision',
    v_decision_id,
    'memory.schedule_changed',
    1,
    p_outbox_payload,
    p_correlation_id,
    'pending'
  ) RETURNING id INTO v_outbox_event_id;

  RETURN QUERY SELECT v_decision_id, v_state_row_version, v_outbox_event_id, false;
END $$;

REVOKE ALL ON FUNCTION memora_memory_context(uuid, uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION memora_memory_record_event(
  uuid, uuid, text, text, uuid, timestamptz, numeric, numeric, boolean, text, jsonb
) FROM PUBLIC;
REVOKE ALL ON FUNCTION memora_memory_apply_decision(
  uuid, uuid, uuid, uuid, uuid, jsonb, jsonb, numeric, timestamptz, text[],
  text, text, text, timestamptz, text, jsonb, uuid
) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION memora_memory_context(uuid, uuid) TO memora_api, memora_worker;
GRANT EXECUTE ON FUNCTION memora_memory_record_event(
  uuid, uuid, text, text, uuid, timestamptz, numeric, numeric, boolean, text, jsonb
) TO memora_api, memora_worker;
GRANT EXECUTE ON FUNCTION memora_memory_apply_decision(
  uuid, uuid, uuid, uuid, uuid, jsonb, jsonb, numeric, timestamptz, text[],
  text, text, text, timestamptz, text, jsonb, uuid
) TO memora_api, memora_worker;
