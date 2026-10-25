CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE subjects (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), code text NOT NULL UNIQUE, name text NOT NULL,
 status text NOT NULL CHECK (status IN ('draft','approved','retired')), created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE curriculum_versions (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), subject_id uuid NOT NULL REFERENCES subjects(id), authority text NOT NULL,
 edition_code text NOT NULL, language_medium text NOT NULL, valid_from date, valid_to date,
 status text NOT NULL CHECK (status IN ('draft','approved','retired','superseded')),
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), row_version integer NOT NULL DEFAULT 1 CHECK (row_version > 0),
 UNIQUE(subject_id, edition_code, language_medium), CHECK (valid_to IS NULL OR valid_from IS NULL OR valid_to >= valid_from)
);
CREATE TABLE users (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), oidc_issuer text NOT NULL, oidc_subject text NOT NULL,
 status text NOT NULL CHECK (status IN ('active','suspended','deletion_pending','deleted')),
 default_timezone text NOT NULL, locale text NOT NULL, last_authenticated_at timestamptz, deleted_at timestamptz,
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), row_version integer NOT NULL DEFAULT 1 CHECK (row_version > 0),
 UNIQUE(oidc_issuer, oidc_subject), CHECK ((status = 'deleted') = (deleted_at IS NOT NULL))
);
CREATE TABLE user_profiles (
 user_id uuid PRIMARY KEY REFERENCES users(id), display_name text NOT NULL CHECK (char_length(display_name) BETWEEN 1 AND 100),
 onboarding_completed_at timestamptz, active_subject_id uuid REFERENCES subjects(id), curriculum_version_id uuid REFERENCES curriculum_versions(id),
 accessibility_preferences jsonb NOT NULL DEFAULT '{"schema_version":"1"}'::jsonb CHECK (jsonb_typeof(accessibility_preferences)='object'),
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), row_version integer NOT NULL DEFAULT 1 CHECK (row_version > 0),
 CHECK (onboarding_completed_at IS NULL OR curriculum_version_id IS NOT NULL)
);
CREATE TABLE consent_records (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid NOT NULL REFERENCES users(id),
 consent_type text NOT NULL CHECK (consent_type IN ('terms','privacy','material_processing','model_processing','notifications')),
 policy_version text NOT NULL, decision text NOT NULL CHECK (decision IN ('granted','declined','withdrawn')),
 decided_at timestamptz NOT NULL, evidence jsonb NOT NULL CHECK (jsonb_typeof(evidence)='object'), created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ix_consent_records_user ON consent_records(user_id, consent_type, decided_at DESC);
CREATE TABLE device_registrations (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid NOT NULL REFERENCES users(id), installation_id uuid NOT NULL,
 platform text NOT NULL CHECK (platform IN ('android','ios')), push_token_ciphertext bytea, token_fingerprint text UNIQUE,
 app_version text NOT NULL, last_seen_at timestamptz NOT NULL, revoked_at timestamptz,
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), row_version integer NOT NULL DEFAULT 1 CHECK (row_version > 0), UNIQUE(user_id, installation_id)
);
CREATE TABLE notification_preferences (
 user_id uuid PRIMARY KEY REFERENCES users(id), mission_enabled boolean NOT NULL DEFAULT true, reward_enabled boolean NOT NULL DEFAULT true,
 quiet_start_local time, quiet_end_local time, preferred_window_start_local time, preferred_window_end_local time,
 timezone text NOT NULL, lock_screen_detail text NOT NULL CHECK (lock_screen_detail IN ('minimal','subject','detailed')),
 max_daily_reminders smallint NOT NULL CHECK (max_daily_reminders >= 0),
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), row_version integer NOT NULL DEFAULT 1 CHECK (row_version > 0),
 CHECK ((quiet_start_local IS NULL) = (quiet_end_local IS NULL))
);

CREATE TABLE learning_objectives (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), curriculum_version_id uuid NOT NULL REFERENCES curriculum_versions(id), objective_code text NOT NULL,
 parent_objective_id uuid REFERENCES learning_objectives(id), title text NOT NULL, description text NOT NULL, sequence_no integer NOT NULL CHECK (sequence_no >= 0),
 status text NOT NULL CHECK (status IN ('draft','approved','retired')), created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), row_version integer NOT NULL DEFAULT 1 CHECK (row_version > 0),
 UNIQUE(curriculum_version_id, objective_code), CHECK (parent_objective_id IS NULL OR parent_objective_id <> id)
);
CREATE TABLE concepts (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), subject_id uuid NOT NULL REFERENCES subjects(id), stable_code text NOT NULL,
 status text NOT NULL CHECK (status IN ('draft','approved','retired')), created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), row_version integer NOT NULL DEFAULT 1 CHECK (row_version > 0), UNIQUE(subject_id, stable_code)
);
CREATE TABLE concept_versions (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), concept_id uuid NOT NULL REFERENCES concepts(id), version_no integer NOT NULL CHECK (version_no > 0),
 kind text NOT NULL CHECK (kind IN ('concept','principle','law','formula','variable','unit','method','diagram_skill','misconception')),
 title text NOT NULL, definition text NOT NULL, symbol_context jsonb, unit_context jsonb,
 content_status text NOT NULL CHECK (content_status IN ('draft','approved','retired')), reviewed_by uuid, reviewed_at timestamptz,
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), row_version integer NOT NULL DEFAULT 1 CHECK (row_version > 0), UNIQUE(concept_id, version_no)
);
CREATE TABLE concept_aliases (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), concept_version_id uuid NOT NULL REFERENCES concept_versions(id), alias_text text NOT NULL,
 normalized_alias text NOT NULL, language_code text NOT NULL, alias_type text NOT NULL CHECK (alias_type IN ('term','symbol','abbreviation','spelling')),
 is_preferred boolean NOT NULL DEFAULT false, created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), row_version integer NOT NULL DEFAULT 1 CHECK (row_version > 0)
);
CREATE INDEX ix_concept_aliases_normalized ON concept_aliases(normalized_alias);
CREATE TABLE knowledge_claims (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), claim_group_id uuid NOT NULL, concept_version_id uuid NOT NULL REFERENCES concept_versions(id), version_no integer NOT NULL CHECK (version_no > 0),
 claim_type text NOT NULL CHECK (claim_type IN ('definition','condition','formula','example','misconception','solution_step')),
 statement text NOT NULL, structured_value jsonb, status text NOT NULL CHECK (status IN ('draft','approved','disputed','retired')),
 provenance_type text NOT NULL, provenance_ref text NOT NULL, reviewed_by uuid, reviewed_at timestamptz,
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), row_version integer NOT NULL DEFAULT 1 CHECK (row_version > 0), UNIQUE(claim_group_id, version_no)
);
CREATE TABLE concept_edges (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), from_concept_version_id uuid NOT NULL REFERENCES concept_versions(id), to_concept_version_id uuid NOT NULL REFERENCES concept_versions(id),
 edge_type text NOT NULL CHECK (edge_type IN ('prerequisite_of','applies_under','contradicts','example_of','misconception_about','related_to')),
 confidence numeric(6,5) NOT NULL CHECK (confidence BETWEEN 0 AND 1), status text NOT NULL CHECK (status IN ('candidate','approved','rejected','retired')),
 provenance_type text NOT NULL, provenance_ref text NOT NULL, valid_from timestamptz NOT NULL, valid_to timestamptz,
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), row_version integer NOT NULL DEFAULT 1 CHECK (row_version > 0),
 CHECK (from_concept_version_id <> to_concept_version_id), CHECK (valid_to IS NULL OR valid_to > valid_from)
);
CREATE UNIQUE INDEX uq_concept_edges_approved_active ON concept_edges(from_concept_version_id,to_concept_version_id,edge_type) WHERE status='approved' AND valid_to IS NULL;
CREATE INDEX ix_concept_edges_from ON concept_edges(from_concept_version_id, edge_type);
CREATE INDEX ix_concept_edges_to ON concept_edges(to_concept_version_id, edge_type);
CREATE TABLE concept_objective_maps (
 concept_version_id uuid NOT NULL REFERENCES concept_versions(id), learning_objective_id uuid NOT NULL REFERENCES learning_objectives(id), mapping_type text NOT NULL,
 coverage_weight numeric(6,5) NOT NULL CHECK (coverage_weight BETWEEN 0 AND 1), provenance_type text NOT NULL, provenance_ref text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(), PRIMARY KEY(concept_version_id,learning_objective_id,mapping_type)
);

CREATE TABLE questions (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), subject_id uuid NOT NULL REFERENCES subjects(id), question_code text NOT NULL,
 source_class text NOT NULL CHECK (source_class IN ('expert_verified','teacher_authored','ai_generated')),
 status text NOT NULL CHECK (status IN ('draft','approved','retired')), author_principal uuid, reviewer_principal uuid,
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), row_version integer NOT NULL DEFAULT 1 CHECK (row_version > 0), UNIQUE(subject_id,question_code)
);
CREATE TABLE question_versions (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), question_id uuid NOT NULL REFERENCES questions(id), version_no integer NOT NULL CHECK (version_no > 0),
 question_type text NOT NULL CHECK (question_type IN ('mcq','numeric','short_answer','diagram_interpretation')),
 prompt text NOT NULL, explanation text NOT NULL, content_payload jsonb NOT NULL CHECK (jsonb_typeof(content_payload)='object'), trust_label text NOT NULL,
 curriculum_version_id uuid NOT NULL REFERENCES curriculum_versions(id), validation_status text NOT NULL CHECK (validation_status IN ('draft','approved','rejected','retired')),
 model_key text, prompt_version text, grounding_evidence_ids uuid[], validator_version text, validation_score numeric(6,5) CHECK (validation_score BETWEEN 0 AND 1), generation_trace_ref text,
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), row_version integer NOT NULL DEFAULT 1 CHECK (row_version > 0), UNIQUE(question_id,version_no)
);
CREATE INDEX ix_question_versions_eligible ON question_versions(curriculum_version_id,validation_status,question_type);
CREATE TABLE question_options (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), question_version_id uuid NOT NULL REFERENCES question_versions(id), option_key text NOT NULL,
 display_text text NOT NULL, accessible_image_ref text, is_correct boolean NOT NULL, explanation text NOT NULL, display_order integer NOT NULL CHECK (display_order >= 0),
 created_at timestamptz NOT NULL DEFAULT now(), UNIQUE(question_version_id,option_key), UNIQUE(question_version_id,display_order)
);
CREATE TABLE question_rubrics (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), question_version_id uuid NOT NULL UNIQUE REFERENCES question_versions(id), rubric_type text NOT NULL,
 rubric_version integer NOT NULL CHECK (rubric_version > 0), rubric_payload jsonb NOT NULL CHECK (jsonb_typeof(rubric_payload)='object'),
 max_score numeric(8,3) NOT NULL CHECK (max_score > 0), evidence_ceiling numeric(6,5) NOT NULL CHECK (evidence_ceiling BETWEEN 0 AND 1),
 status text NOT NULL CHECK (status IN ('draft','approved','retired')), created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), row_version integer NOT NULL DEFAULT 1 CHECK (row_version > 0)
);
CREATE TABLE question_concept_maps (
 question_version_id uuid NOT NULL REFERENCES question_versions(id), concept_version_id uuid NOT NULL REFERENCES concept_versions(id), learning_objective_id uuid REFERENCES learning_objectives(id),
 mapping_role text NOT NULL CHECK (mapping_role IN ('primary','supporting','prerequisite','misconception')), weight numeric(6,5) NOT NULL CHECK (weight BETWEEN 0 AND 1),
 provenance_type text NOT NULL, provenance_ref text NOT NULL, created_at timestamptz NOT NULL DEFAULT now(), PRIMARY KEY(question_version_id,concept_version_id,mapping_role)
);
CREATE TABLE concept_embeddings (concept_version_id uuid NOT NULL REFERENCES concept_versions(id), model_key text NOT NULL, embedding vector(2048) NOT NULL, content_hash text NOT NULL, created_at timestamptz NOT NULL DEFAULT now(), PRIMARY KEY(concept_version_id,model_key));
CREATE TABLE claim_embeddings (knowledge_claim_id uuid NOT NULL REFERENCES knowledge_claims(id), model_key text NOT NULL, embedding vector(2048) NOT NULL, content_hash text NOT NULL, created_at timestamptz NOT NULL DEFAULT now(), PRIMARY KEY(knowledge_claim_id,model_key));
CREATE TABLE question_embeddings (question_version_id uuid NOT NULL REFERENCES question_versions(id), model_key text NOT NULL, embedding vector(2048) NOT NULL, content_hash text NOT NULL, created_at timestamptz NOT NULL DEFAULT now(), PRIMARY KEY(question_version_id,model_key));

CREATE TABLE learning_updates (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid NOT NULL REFERENCES users(id), subject_id uuid NOT NULL REFERENCES subjects(id), curriculum_version_id uuid NOT NULL REFERENCES curriculum_versions(id),
 input_type text NOT NULL CHECK (input_type IN ('manual_text','pdf','image','mixed')), manual_text_ciphertext bytea,
 status text NOT NULL CHECK (status IN ('draft','uploading','processing','verification_required','committed','failed','expired','deleted')),
 learned_at timestamptz NOT NULL, client_operation_id uuid NOT NULL, failure_code text, expires_at timestamptz,
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), row_version integer NOT NULL DEFAULT 1 CHECK (row_version > 0),
 UNIQUE(user_id,client_operation_id), UNIQUE(id,user_id), CHECK (status='draft' OR expires_at IS NOT NULL OR status='committed')
);
CREATE TABLE source_uploads (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), learning_update_id uuid NOT NULL, user_id uuid NOT NULL REFERENCES users(id), object_key text NOT NULL UNIQUE,
 declared_name text NOT NULL, declared_media_type text NOT NULL, detected_media_type text, byte_size bigint NOT NULL CHECK (byte_size > 0),
 content_sha256 text CHECK (content_sha256 IS NULL OR content_sha256 ~ '^[0-9a-f]{64}$'),
 status text NOT NULL CHECK (status IN ('authorized','uploaded','validated','processing','deleting','deleted','rejected','expired')),
 validation_result jsonb NOT NULL DEFAULT '{"schema_version":"1"}'::jsonb CHECK (jsonb_typeof(validation_result)='object'), expires_at timestamptz NOT NULL, deleted_at timestamptz,
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), row_version integer NOT NULL DEFAULT 1 CHECK (row_version > 0),
 FOREIGN KEY(learning_update_id,user_id) REFERENCES learning_updates(id,user_id), UNIQUE(id,user_id), CHECK ((status='deleted') = (deleted_at IS NOT NULL))
);
CREATE INDEX ix_source_uploads_reconcile ON source_uploads(status,expires_at);
CREATE TABLE extraction_candidates (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), learning_update_id uuid NOT NULL, user_id uuid NOT NULL REFERENCES users(id),
 candidate_type text NOT NULL CHECK (candidate_type IN ('concept','claim','edge','formula','variable','unit','diagram','example')),
 candidate_payload jsonb NOT NULL CHECK (jsonb_typeof(candidate_payload)='object'), source_locator jsonb NOT NULL CHECK (jsonb_typeof(source_locator)='object'),
 confidence numeric(6,5) NOT NULL CHECK (confidence BETWEEN 0 AND 1), model_key text NOT NULL, prompt_version text NOT NULL, schema_version text NOT NULL,
 status text NOT NULL CHECK (status IN ('candidate','needs_verification','accepted','rejected','committed','expired')), expires_at timestamptz NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), row_version integer NOT NULL DEFAULT 1 CHECK (row_version > 0),
 FOREIGN KEY(learning_update_id,user_id) REFERENCES learning_updates(id,user_id), UNIQUE(id,user_id)
);
CREATE INDEX ix_extraction_candidates_update_status ON extraction_candidates(learning_update_id,status);
CREATE TABLE verification_requests (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), learning_update_id uuid NOT NULL, candidate_id uuid NOT NULL, user_id uuid NOT NULL REFERENCES users(id),
 reason_code text NOT NULL, question_text text NOT NULL, options jsonb NOT NULL CHECK (jsonb_typeof(options) IN ('array','object')),
 status text NOT NULL CHECK (status IN ('pending','answered','expired','cancelled')), expires_at timestamptz NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), row_version integer NOT NULL DEFAULT 1 CHECK (row_version > 0),
 FOREIGN KEY(learning_update_id,user_id) REFERENCES learning_updates(id,user_id), FOREIGN KEY(candidate_id,user_id) REFERENCES extraction_candidates(id,user_id), UNIQUE(id,user_id)
);
CREATE UNIQUE INDEX uq_verification_requests_active ON verification_requests(candidate_id) WHERE status='pending';
CREATE TABLE verification_decisions (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), verification_request_id uuid NOT NULL, user_id uuid NOT NULL REFERENCES users(id),
 decision text NOT NULL CHECK (decision IN ('accept','correct','reject','skip')), corrected_payload jsonb, decided_at timestamptz NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(), FOREIGN KEY(verification_request_id,user_id) REFERENCES verification_requests(id,user_id),
 CHECK ((decision='correct') = (corrected_payload IS NOT NULL))
);
CREATE UNIQUE INDEX uq_verification_decisions_terminal ON verification_decisions(verification_request_id) WHERE decision IN ('accept','correct','reject');
CREATE TABLE private_knowledge_items (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid NOT NULL REFERENCES users(id), learning_update_id uuid NOT NULL, item_type text NOT NULL,
 structured_content jsonb NOT NULL CHECK (jsonb_typeof(structured_content)='object'), schema_version text NOT NULL,
 confidence numeric(6,5) NOT NULL CHECK (confidence BETWEEN 0 AND 1), provenance jsonb NOT NULL CHECK (jsonb_typeof(provenance)='object'),
 status text NOT NULL CHECK (status IN ('active','disputed','retired','deleted')), concept_version_id uuid REFERENCES concept_versions(id),
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), row_version integer NOT NULL DEFAULT 1 CHECK (row_version > 0),
 FOREIGN KEY(learning_update_id,user_id) REFERENCES learning_updates(id,user_id)
);

CREATE TABLE outbox_events (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), domain_event_key text NOT NULL UNIQUE, aggregate_type text NOT NULL, aggregate_id uuid NOT NULL,
 event_type text NOT NULL, event_version integer NOT NULL CHECK (event_version > 0), payload jsonb NOT NULL CHECK (jsonb_typeof(payload)='object'),
 correlation_id uuid NOT NULL, publication_status text NOT NULL CHECK (publication_status IN ('pending','published','failed')),
 published_at timestamptz, created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ix_outbox_events_unpublished ON outbox_events(publication_status,created_at) WHERE publication_status <> 'published';
CREATE TABLE knowledge_commits (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), learning_update_id uuid NOT NULL, user_id uuid NOT NULL REFERENCES users(id), commit_version integer NOT NULL CHECK (commit_version > 0),
 candidate_snapshot_hash text NOT NULL, committed_counts jsonb NOT NULL CHECK (jsonb_typeof(committed_counts)='object'), transaction_id text NOT NULL,
 committed_at timestamptz NOT NULL, outbox_event_id uuid NOT NULL REFERENCES outbox_events(id), created_at timestamptz NOT NULL DEFAULT now(),
 FOREIGN KEY(learning_update_id,user_id) REFERENCES learning_updates(id,user_id), UNIQUE(learning_update_id,commit_version)
);

CREATE TABLE learner_concept_states (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid NOT NULL REFERENCES users(id), concept_id uuid NOT NULL REFERENCES concepts(id), active_concept_version_id uuid NOT NULL REFERENCES concept_versions(id),
 difficulty numeric(8,5) NOT NULL, stability_days numeric(12,5) NOT NULL CHECK (stability_days >= 0), last_retrievability numeric(6,5) NOT NULL CHECK (last_retrievability BETWEEN 0 AND 1),
 evidence_confidence numeric(6,5) NOT NULL CHECK (evidence_confidence BETWEEN 0 AND 1), first_exposed_at timestamptz NOT NULL, last_reviewed_at timestamptz, next_review_at timestamptz NOT NULL,
 exposure_count integer NOT NULL CHECK (exposure_count >= 0), eligible_review_count integer NOT NULL CHECK (eligible_review_count >= 0), lapse_count integer NOT NULL CHECK (lapse_count >= 0), engine_version text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), row_version integer NOT NULL DEFAULT 1 CHECK (row_version > 0), UNIQUE(user_id,concept_id)
);
CREATE INDEX ix_learner_concept_states_due ON learner_concept_states(user_id,next_review_at);
CREATE TABLE memory_events (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid NOT NULL REFERENCES users(id), concept_id uuid NOT NULL REFERENCES concepts(id),
 event_type text NOT NULL CHECK (event_type IN ('exposure','attempt','repair','regrade','invalidation','manual_review')), source_type text NOT NULL, source_id uuid NOT NULL,
 observed_at timestamptz NOT NULL, score numeric(6,5) CHECK (score BETWEEN 0 AND 1), confidence numeric(6,5) NOT NULL CHECK (confidence BETWEEN 0 AND 1),
 is_eligible boolean NOT NULL, ineligibility_reason text, event_payload jsonb NOT NULL CHECK (jsonb_typeof(event_payload)='object'), created_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(event_type,source_type,source_id,concept_id), UNIQUE(id,user_id)
);
CREATE INDEX ix_memory_events_history ON memory_events(user_id,concept_id,observed_at DESC);
CREATE TABLE memory_decisions (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid NOT NULL REFERENCES users(id), concept_id uuid NOT NULL REFERENCES concepts(id), trigger_event_id uuid NOT NULL,
 previous_state jsonb NOT NULL CHECK (jsonb_typeof(previous_state)='object'), result_state jsonb NOT NULL CHECK (jsonb_typeof(result_state)='object'),
 retrievability_at_decision numeric(6,5) NOT NULL CHECK (retrievability_at_decision BETWEEN 0 AND 1), next_review_at timestamptz NOT NULL,
 reason_codes text[] NOT NULL, explanation_template_key text NOT NULL, engine_version text NOT NULL, policy_version text NOT NULL, decided_at timestamptz NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(), FOREIGN KEY(trigger_event_id,user_id) REFERENCES memory_events(id,user_id), UNIQUE(trigger_event_id,concept_id,engine_version)
);

CREATE TABLE missions (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid NOT NULL REFERENCES users(id), subject_id uuid NOT NULL REFERENCES subjects(id), mission_date date NOT NULL, mission_timezone text NOT NULL,
 sequence_no smallint NOT NULL DEFAULT 1 CHECK (sequence_no > 0), status text NOT NULL CHECK (status IN ('planned','started','paused','completed','expired','abandoned')),
 engine_version text NOT NULL, candidate_snapshot_hash text NOT NULL, estimated_minutes smallint NOT NULL CHECK (estimated_minutes > 0), planned_item_count smallint NOT NULL CHECK (planned_item_count > 0),
 started_at timestamptz, completed_at timestamptz, expires_at timestamptz NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), row_version integer NOT NULL DEFAULT 1 CHECK (row_version > 0),
 UNIQUE(user_id,subject_id,mission_date,sequence_no), UNIQUE(id,user_id)
);
CREATE INDEX ix_missions_history ON missions(user_id,mission_date DESC);
CREATE TABLE mission_items (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), mission_id uuid NOT NULL, user_id uuid NOT NULL REFERENCES users(id), position smallint NOT NULL CHECK (position >= 0),
 mission_type text NOT NULL CHECK (mission_type IN ('protect','repair','recover','discover','challenge')), question_version_id uuid NOT NULL REFERENCES question_versions(id), primary_concept_id uuid NOT NULL REFERENCES concepts(id),
 selection_reason_codes text[] NOT NULL, priority_snapshot jsonb NOT NULL CHECK (jsonb_typeof(priority_snapshot)='object'),
 status text NOT NULL CHECK (status IN ('pending','presented','answered','skipped','cancelled')), presented_at timestamptz,
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), row_version integer NOT NULL DEFAULT 1 CHECK (row_version > 0),
 FOREIGN KEY(mission_id,user_id) REFERENCES missions(id,user_id), UNIQUE(mission_id,position), UNIQUE(id,user_id)
);
CREATE TABLE attempts (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid NOT NULL REFERENCES users(id), mission_item_id uuid NOT NULL, attempt_no smallint NOT NULL CHECK (attempt_no > 0),
 client_operation_id uuid NOT NULL, answer_payload jsonb NOT NULL CHECK (jsonb_typeof(answer_payload)='object'), submitted_at timestamptz NOT NULL,
 elapsed_ms integer CHECK (elapsed_ms >= 0), app_version text NOT NULL, is_offline_submission boolean NOT NULL DEFAULT false, created_at timestamptz NOT NULL DEFAULT now(),
 FOREIGN KEY(mission_item_id,user_id) REFERENCES mission_items(id,user_id), UNIQUE(mission_item_id,attempt_no), UNIQUE(user_id,client_operation_id), UNIQUE(id,user_id)
);
CREATE TABLE grading_results (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), attempt_id uuid NOT NULL REFERENCES attempts(id), result_version integer NOT NULL CHECK (result_version > 0),
 grader_type text NOT NULL CHECK (grader_type IN ('exact','numeric','rubric_model','human_review','invalidation')), score numeric(6,5) NOT NULL CHECK (score BETWEEN 0 AND 1),
 classification text NOT NULL CHECK (classification IN ('correct','partial','incorrect','misconception','ungradable','invalidated')), confidence numeric(6,5) NOT NULL CHECK (confidence BETWEEN 0 AND 1),
 rubric_id uuid NOT NULL REFERENCES question_rubrics(id), grader_version text NOT NULL, evidence_payload jsonb NOT NULL CHECK (jsonb_typeof(evidence_payload)='object'),
 is_authoritative boolean NOT NULL, graded_at timestamptz NOT NULL, created_at timestamptz NOT NULL DEFAULT now(), UNIQUE(attempt_id,result_version)
);
CREATE UNIQUE INDEX uq_grading_results_authoritative ON grading_results(attempt_id) WHERE is_authoritative;
CREATE TABLE question_reports (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid NOT NULL REFERENCES users(id), question_version_id uuid NOT NULL REFERENCES question_versions(id), attempt_id uuid,
 report_type text NOT NULL CHECK (report_type IN ('question_error','answer_error','explanation_error','grading_dispute','accessibility')),
 description_ciphertext bytea, status text NOT NULL CHECK (status IN ('submitted','triaged','under_review','resolved','dismissed')), resolution_code text,
 submitted_at timestamptz NOT NULL, resolved_at timestamptz,
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), row_version integer NOT NULL DEFAULT 1 CHECK (row_version > 0),
 FOREIGN KEY(attempt_id,user_id) REFERENCES attempts(id,user_id)
);

CREATE TABLE xp_ledger (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid NOT NULL REFERENCES users(id), amount integer NOT NULL CHECK (amount <> 0),
 entry_type text NOT NULL CHECK (entry_type IN ('earn','correction','reversal')), source_event_type text NOT NULL, source_event_id uuid NOT NULL,
 reason_code text NOT NULL, balance_after bigint NOT NULL CHECK (balance_after >= 0), earned_at timestamptz NOT NULL, created_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(user_id,source_event_type,source_event_id,entry_type)
);
CREATE TABLE streak_days (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid NOT NULL REFERENCES users(id), local_date date NOT NULL, timezone text NOT NULL,
 qualification_type text NOT NULL CHECK (qualification_type IN ('mission_completed','grace_used','comeback_completed')), mission_id uuid REFERENCES missions(id), grace_window_key text,
 created_at timestamptz NOT NULL DEFAULT now(), UNIQUE(user_id,local_date)
);
CREATE TABLE reward_definitions (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), reward_code text NOT NULL UNIQUE, reward_type text NOT NULL CHECK (reward_type IN ('decoration','mora_cosmetic')),
 title text NOT NULL, asset_key text NOT NULL, xp_threshold bigint NOT NULL CHECK (xp_threshold >= 0), status text NOT NULL CHECK (status IN ('draft','approved','retired')),
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), row_version integer NOT NULL DEFAULT 1 CHECK (row_version > 0)
);
CREATE TABLE reward_grants (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid NOT NULL REFERENCES users(id), reward_definition_id uuid NOT NULL REFERENCES reward_definitions(id),
 source_xp_ledger_id uuid NOT NULL REFERENCES xp_ledger(id), granted_at timestamptz NOT NULL, created_at timestamptz NOT NULL DEFAULT now(), UNIQUE(user_id,reward_definition_id)
);
CREATE TABLE reef_projections (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid NOT NULL REFERENCES users(id), subject_id uuid NOT NULL REFERENCES subjects(id),
 condition text NOT NULL CHECK (condition IN ('new','thriving','healthy','needs_care','dormant')), health_score numeric(6,5) NOT NULL CHECK (health_score BETWEEN 0 AND 1),
 due_memory_count integer NOT NULL CHECK (due_memory_count >= 0), prerequisite_risk numeric(6,5) NOT NULL CHECK (prerequisite_risk BETWEEN 0 AND 1),
 recent_evidence_score numeric(6,5) NOT NULL CHECK (recent_evidence_score BETWEEN 0 AND 1), projection_version text NOT NULL, source_watermark text NOT NULL, projected_at timestamptz NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), row_version integer NOT NULL DEFAULT 1 CHECK (row_version > 0), UNIQUE(user_id,subject_id)
);

CREATE TABLE idempotency_records (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid REFERENCES users(id), scope text NOT NULL, operation text NOT NULL, idempotency_key text NOT NULL,
 request_hash text NOT NULL, status text NOT NULL CHECK (status IN ('processing','completed','failed')), response_reference text, expires_at timestamptz NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), row_version integer NOT NULL DEFAULT 1 CHECK (row_version > 0), UNIQUE(scope,operation,idempotency_key)
);
CREATE TABLE background_jobs (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), job_type text NOT NULL, owner_user_id uuid REFERENCES users(id), resource_type text NOT NULL, resource_id uuid NOT NULL,
 dedupe_key text NOT NULL UNIQUE, status text NOT NULL CHECK (status IN ('queued','leased','retry_wait','succeeded','failed','dead_lettered','cancelled')),
 attempt_count integer NOT NULL DEFAULT 0 CHECK (attempt_count >= 0), max_attempts integer NOT NULL CHECK (max_attempts > 0), available_at timestamptz NOT NULL,
 lease_owner text, lease_expires_at timestamptz, last_error_code text, payload jsonb NOT NULL CHECK (jsonb_typeof(payload)='object'),
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), row_version integer NOT NULL DEFAULT 1 CHECK (row_version > 0)
);
CREATE INDEX ix_background_jobs_claim ON background_jobs(status,available_at) WHERE status IN ('queued','retry_wait');
CREATE TABLE audit_events (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), actor_type text NOT NULL, actor_id text NOT NULL, action text NOT NULL, resource_type text NOT NULL, resource_id uuid,
 authorization_context jsonb NOT NULL CHECK (jsonb_typeof(authorization_context)='object'), outcome text NOT NULL,
 request_id uuid, correlation_id uuid, safe_metadata jsonb NOT NULL CHECK (jsonb_typeof(safe_metadata)='object'), created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE privacy_requests (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid NOT NULL REFERENCES users(id), request_type text NOT NULL CHECK (request_type IN ('export','delete')),
 verified_at timestamptz, status text NOT NULL CHECK (status IN ('requested','verifying','processing','completed','failed','cancelled')),
 requested_at timestamptz NOT NULL, completed_at timestamptz, failure_code text, workflow_version text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), row_version integer NOT NULL DEFAULT 1 CHECK (row_version > 0)
);
CREATE TABLE deletion_proofs (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), privacy_request_id uuid REFERENCES privacy_requests(id), source_upload_id uuid REFERENCES source_uploads(id),
 scope text NOT NULL, provider text NOT NULL, target_fingerprint text NOT NULL, result text NOT NULL, verified_at timestamptz NOT NULL, reconciler_version text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(), CHECK ((privacy_request_id IS NULL) <> (source_upload_id IS NULL))
);

CREATE FUNCTION memora_forbid_mutation() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN RAISE EXCEPTION '% is append-only', TG_TABLE_NAME USING ERRCODE='55000'; END $$;
DO $$ DECLARE t text; BEGIN FOREACH t IN ARRAY ARRAY['consent_records','verification_decisions','knowledge_commits','memory_events','memory_decisions','attempts','grading_results','xp_ledger','streak_days','reward_grants','outbox_events','audit_events','deletion_proofs'] LOOP EXECUTE format('CREATE TRIGGER %I_append_only BEFORE UPDATE OR DELETE ON %I FOR EACH ROW EXECUTE FUNCTION memora_forbid_mutation()',t,t); END LOOP; END $$;
CREATE FUNCTION memora_protect_published() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN IF OLD.status IN ('approved','disputed','retired') OR OLD.content_status IN ('approved','retired') OR OLD.validation_status IN ('approved','rejected','retired') THEN RAISE EXCEPTION '% published row is immutable', TG_TABLE_NAME USING ERRCODE='55000'; END IF; RETURN NEW; END $$;
CREATE TRIGGER concept_versions_immutable BEFORE UPDATE OR DELETE ON concept_versions FOR EACH ROW WHEN (OLD.content_status IN ('approved','retired')) EXECUTE FUNCTION memora_forbid_mutation();
CREATE TRIGGER question_versions_immutable BEFORE UPDATE OR DELETE ON question_versions FOR EACH ROW WHEN (OLD.validation_status IN ('approved','rejected','retired')) EXECUTE FUNCTION memora_forbid_mutation();
CREATE TRIGGER knowledge_claims_immutable BEFORE UPDATE OR DELETE ON knowledge_claims FOR EACH ROW WHEN (OLD.status IN ('approved','disputed','retired')) EXECUTE FUNCTION memora_forbid_mutation();

CREATE FUNCTION memora_reject_objective_cycle() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
 IF NEW.parent_objective_id IS NULL THEN RETURN NEW; END IF;
 IF EXISTS (
   WITH RECURSIVE ancestors(id,parent_objective_id) AS (
     SELECT id,parent_objective_id FROM learning_objectives WHERE id=NEW.parent_objective_id
     UNION ALL
     SELECT o.id,o.parent_objective_id FROM learning_objectives o JOIN ancestors a ON o.id=a.parent_objective_id
   ) SELECT 1 FROM ancestors WHERE id=NEW.id
 ) THEN RAISE EXCEPTION 'learning objective cycle' USING ERRCODE='23514'; END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER learning_objectives_no_cycle BEFORE INSERT OR UPDATE OF parent_objective_id ON learning_objectives FOR EACH ROW EXECUTE FUNCTION memora_reject_objective_cycle();

CREATE FUNCTION memora_prevent_upload_resurrection() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
 IF OLD.status='deleted' AND NEW.status <> 'deleted' THEN RAISE EXCEPTION 'deleted upload cannot become available' USING ERRCODE='23514'; END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER source_uploads_no_resurrection BEFORE UPDATE ON source_uploads FOR EACH ROW EXECUTE FUNCTION memora_prevent_upload_resurrection();

DO $$ DECLARE t text; BEGIN FOREACH t IN ARRAY ARRAY['user_profiles','consent_records','device_registrations','notification_preferences','learning_updates','source_uploads','extraction_candidates','verification_requests','verification_decisions','private_knowledge_items','knowledge_commits','learner_concept_states','memory_events','memory_decisions','missions','mission_items','attempts','question_reports','xp_ledger','streak_days','reward_grants','reef_projections','privacy_requests'] LOOP
 EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY',t);
 EXECUTE format('ALTER TABLE %I FORCE ROW LEVEL SECURITY',t);
 EXECUTE format('CREATE POLICY %I_owner ON %I USING (user_id = nullif(current_setting(''memora.user_id'', true), '''')::uuid) WITH CHECK (user_id = nullif(current_setting(''memora.user_id'', true), '''')::uuid)',t,t);
END LOOP; END $$;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE users FORCE ROW LEVEL SECURITY;
CREATE POLICY users_owner ON users USING (id = nullif(current_setting('memora.user_id', true), '')::uuid) WITH CHECK (id = nullif(current_setting('memora.user_id', true), '')::uuid);

DO $$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='memora_api') THEN CREATE ROLE memora_api NOLOGIN; END IF;
 IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='memora_worker') THEN CREATE ROLE memora_worker NOLOGIN; END IF;
END $$;
GRANT USAGE ON SCHEMA public TO memora_api, memora_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO memora_api, memora_worker;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO memora_api, memora_worker;

INSERT INTO subjects(id,code,name,status) VALUES ('10000000-0000-0000-0000-000000000001','physics','Physics','approved') ON CONFLICT (code) DO NOTHING;
INSERT INTO curriculum_versions(id,subject_id,authority,edition_code,language_medium,valid_from,status)
VALUES ('20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','National Institute of Education, Sri Lanka','GCE-AL-PHYSICS-2017','en','2017-01-01','approved')
ON CONFLICT (subject_id,edition_code,language_medium) DO NOTHING;
