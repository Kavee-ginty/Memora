ALTER TABLE outbox_events
ADD CONSTRAINT ck_outbox_publication_timestamp
CHECK ((publication_status = 'published') = (published_at IS NOT NULL));

DROP TRIGGER grading_results_append_only ON grading_results;

CREATE FUNCTION memora_protect_grading_result() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    RAISE EXCEPTION 'grading_results is append-only' USING ERRCODE = '55000';
  END IF;

  IF (to_jsonb(NEW) - 'is_authoritative')
      IS DISTINCT FROM (to_jsonb(OLD) - 'is_authoritative')
    OR OLD.is_authoritative IS NOT TRUE
    OR NEW.is_authoritative IS NOT FALSE
  THEN
    RAISE EXCEPTION 'grading result evidence is immutable' USING ERRCODE = '55000';
  END IF;

  RETURN NEW;
END $$;

CREATE TRIGGER grading_results_protect_evidence
BEFORE UPDATE OR DELETE ON grading_results
FOR EACH ROW EXECUTE FUNCTION memora_protect_grading_result();

CREATE FUNCTION memora_resolve_user_id(p_oidc_issuer text, p_oidc_subject text)
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
  SELECT id
  FROM public.users
  WHERE oidc_issuer = p_oidc_issuer
    AND oidc_subject = p_oidc_subject
$$;

REVOKE ALL ON FUNCTION memora_resolve_user_id(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION memora_resolve_user_id(text, text) TO memora_api;

REVOKE SELECT, INSERT, UPDATE, DELETE ON
  learning_updates, source_uploads, extraction_candidates,
  verification_requests, verification_decisions, private_knowledge_items,
  knowledge_commits, learner_concept_states, memory_events, memory_decisions,
  missions, mission_items, attempts, grading_results, question_reports,
  xp_ledger, streak_days, reward_grants, reef_projections, privacy_requests,
  deletion_proofs, idempotency_records, outbox_events, background_jobs
FROM memora_worker;

GRANT SELECT, INSERT, UPDATE ON
  idempotency_records, outbox_events, background_jobs
TO memora_worker;
