# Memora Backend Schema and Data Model

**Document 4 of 6**  
**Status:** Canonical implementation specification  
**Version:** 1.0  
**Prepared:** 22 October 2026  
**Audience:** Backend, mobile, data, AI, security and quality-assurance engineers  
**Applies to:** Student-first Sri Lankan GCE Advanced Level Physics MVP  
**Related documents:** `./Memora_PRD.md`, `./Memora_TRD.md` and `./Memora_UI_UX_Design_Specification.md`

## 1 Purpose and authority

This document defines the durable PostgreSQL data model for the Memora MVP. It specifies entity ownership, identifiers, relationships, fields, constraints, lifecycle rules, indexes, row isolation, retention, migrations and verification gates. An implementation is conformant only when it preserves the invariants and contracts in this document.

The PRD remains authoritative for product behavior. The TRD remains authoritative for architecture, service boundaries and non-functional requirements. The UI/UX specification remains authoritative for presentation and interaction. This document is authoritative for stored data and database-enforced integrity. When another document describes a concept without a storage contract, this document supplies that contract without expanding product scope.

### 1.1 MVP database boundary

PostgreSQL is the transactional source of truth. pgvector stores authorized semantic embeddings beside relational records. Temporary source files and processing derivatives remain in temporary object storage; the database stores only their metadata, lifecycle state and verified deletion evidence. Queue messages carry opaque identifiers rather than document content. Reef state and similar UI summaries are projections that can be rebuilt from authoritative learning state and ledgers.

### 1.2 Non-goals

This document does not define API request bodies, complete OpenAPI schemas, UI state transitions, infrastructure-as-code, analytics warehouse models, provider-specific identity tables or a separate graph database. Those belong to later contracts or external managed systems.

## 2 Schema principles

### DBS-001 - Private data has an explicit owner

Every learner-owned row must contain `user_id` directly or be reachable through a mandatory foreign-key path to a row containing `user_id`. Authorization must not depend on a client-supplied owner identifier.

### DBS-002 - Academic content is versioned

Questions, concepts, claims, rubrics, curriculum mappings and policy-sensitive definitions must be immutable once referenced by learner evidence. An edit creates a new version and leaves historical references intact.

### DBS-003 - Evidence is append-only

Attempts, grading results, memory decisions, XP entries, consent records, privileged audit events and deletion proofs are never updated to rewrite history. Corrections append compensating or superseding records.

### DBS-004 - AI does not write authoritative state directly

Model output is stored as candidate evidence with model, prompt, schema and confidence metadata. Validated application services decide whether it can become committed knowledge, grading evidence or a generated question.

### DBS-005 - Temporary material stays temporary

Raw uploads and derivatives do not enter PostgreSQL. Temporary extraction rows expire after validated commit, terminal failure or verification timeout. Deletion is complete only when the deletion proof is recorded.

### DBS-006 - Game state is derived from learning state

XP and reward ownership use append-only ledgers. Reef condition is a rebuildable projection. Missing a review may change temporary reef condition but cannot remove XP, decorations or cosmetics.

### DBS-007 - Duplicate delivery is harmless

Every externally retried mutation and background job has a stable idempotency key or source-event uniqueness constraint. Repeating the same logical operation cannot create duplicate attempts, memory updates, rewards or jobs.

### DBS-008 - Time and versions are explicit

All stored timestamps use UTC `timestamptz`. User-local dates also store the timezone used to derive them. Curriculum, engine, policy, prompt, model, rubric and projection versions are retained wherever they affect a result.

## 3 Naming types and shared columns

### 3.1 Naming

- Tables and columns use `snake_case` and plural table names.
- Primary keys use `id`; foreign keys use `<entity>_id`.
- Stable public identifiers are UUIDs and are never derived from row order.
- Status values use lowercase snake-case text with database check constraints.
- Boolean names begin with `is_`, `has_` or `can_`.
- Timestamp columns end with `_at`; user-local calendar values end with `_date`.

### 3.2 Shared types

| Type | Database representation | Rule |
| --- | --- | --- |
| Identifier | `uuid` | Generated server-side; opaque to clients |
| Timestamp | `timestamptz` | UTC only |
| Calendar day | `date` plus timezone | Never inferred later from UTC alone |
| Confidence or probability | `numeric(6,5)` | Inclusive range 0 to 1 |
| Counters | `integer` | Non-negative unless explicitly documented |
| Version | `integer` | Starts at 1 and increases without reuse |
| Flexible validated payload | `jsonb` | Allowed only with a versioned application schema and database shape checks where practical |
| Semantic vector | `vector` | Dimension fixed by the approved embedding migration |
| Digest | `bytea` or lowercase hex text | Algorithm recorded or fixed by schema version |

### 3.3 Shared columns

Unless a table is explicitly append-only, it includes `id uuid primary key`, `created_at timestamptz not null`, `updated_at timestamptz not null`, and `row_version integer not null default 1`. Append-only tables include `id` and `created_at` but not `updated_at`. Soft deletion is used only where a workflow needs a reversible or staged state; it is not a substitute for the account-deletion workflow.

### 3.4 Constraint notation

| Marker | Meaning |
| --- | --- |
| PK | Primary key |
| FK | Foreign key |
| NN | Not null |
| UQ | Unique constraint |
| CHK | Check constraint |
| IDX | Supporting index |
| APPEND | Insert-only after commit |

## 4 Domain inventory

| Domain | Authoritative tables | Ownership |
| --- | --- | --- |
| Identity and preferences | `users`, `user_profiles`, `consent_records`, `device_registrations`, `notification_preferences` | Private per user |
| Curriculum and graph | `subjects`, `curriculum_versions`, `learning_objectives`, `concepts`, `concept_versions`, `concept_aliases`, `knowledge_claims`, `concept_edges`, `concept_objective_maps` | Shared reviewed content |
| Ingestion | `learning_updates`, `source_uploads`, `extraction_candidates`, `verification_requests`, `verification_decisions`, `knowledge_commits` | Private per user |
| Questions | `questions`, `question_versions`, `question_options`, `question_rubrics`, `question_concept_maps`, `question_reports` | Shared reviewed or private generated evidence |
| Memory and missions | `learner_concept_states`, `memory_events`, `memory_decisions`, `missions`, `mission_items`, `attempts`, `grading_results` | Private per user |
| Engagement | `xp_ledger`, `streak_days`, `reward_definitions`, `reward_grants`, `reef_projections` | Private except reward definitions |
| Reliability and governance | `idempotency_records`, `outbox_events`, `background_jobs`, `audit_events`, `privacy_requests`, `deletion_proofs` | Operational or private by scope |

## 5 Relationship contract

| Parent | Child | Cardinality | Delete behavior |
| --- | --- | --- | --- |
| `users` | private learner tables | One to many | Account deletion workflow; never casual cascade from application code |
| `subjects` | `curriculum_versions` | One to many | Restrict while referenced |
| `curriculum_versions` | `learning_objectives` | One to many | Restrict; supersede with a new curriculum version |
| `concepts` | `concept_versions` | One to many | Restrict once published |
| `concept_versions` | aliases, claims, mappings and question maps | One to many | Restrict once referenced |
| `learning_updates` | uploads, candidates, verification and commits | One to many | Delete through retention workflow |
| `questions` | `question_versions` | One to many | Restrict once an attempt exists |
| `missions` | `mission_items` | One to many | Restrict after mission start |
| `mission_items` | `attempts` | One to many | Restrict; retries append attempts |
| `attempts` | `grading_results` and `memory_events` | One to one or one to many | Restrict and compensate |
| `memory_events` | `memory_decisions` and `xp_ledger` | One to many | Restrict; unique source constraints prevent duplicates |

## 6 Identity preferences and consent

### 6.1 users

The application user record contains the minimum identity link needed to authorize private data. Contact and recovery data remain with the managed OIDC provider unless the product explicitly requires a local copy.

| Column | Type | Rules |
| --- | --- | --- |
| `id` | uuid | PK |
| `oidc_issuer` | text | NN |
| `oidc_subject` | text | NN; UQ with issuer |
| `status` | text | NN; CHK `active`, `suspended`, `deletion_pending`, `deleted` |
| `default_timezone` | text | NN; valid IANA timezone |
| `locale` | text | NN; launch default may be configured |
| `last_authenticated_at` | timestamptz | Nullable |
| `deleted_at` | timestamptz | Nullable; present only after completed deletion |

Required constraint: `unique (oidc_issuer, oidc_subject)`.

### 6.2 user_profiles

| Column | Type | Rules |
| --- | --- | --- |
| `user_id` | uuid | PK and FK `users.id` |
| `display_name` | text | NN; length limited and normalized |
| `onboarding_completed_at` | timestamptz | Nullable |
| `active_subject_id` | uuid | FK `subjects.id`; Physics in the MVP |
| `curriculum_version_id` | uuid | FK `curriculum_versions.id`; NN after onboarding |
| `accessibility_preferences` | jsonb | NN default `{}`; versioned allowlisted keys only |

### 6.3 consent_records

Append-only proof of what the student accepted or declined.

| Column | Type | Rules |
| --- | --- | --- |
| `id` | uuid | PK; APPEND |
| `user_id` | uuid | FK; NN; IDX |
| `consent_type` | text | NN; CHK `terms`, `privacy`, `material_processing`, `model_processing`, `notifications` |
| `policy_version` | text | NN |
| `decision` | text | NN; CHK `granted`, `declined`, `withdrawn` |
| `decided_at` | timestamptz | NN |
| `evidence` | jsonb | NN; channel, locale and safe request metadata only |

Current consent is the latest valid record per `user_id` and `consent_type`; it is not stored as a mutable boolean.

### 6.4 device_registrations

| Column | Type | Rules |
| --- | --- | --- |
| `id` | uuid | PK |
| `user_id` | uuid | FK; NN; IDX |
| `installation_id` | uuid | NN; UQ per user |
| `platform` | text | NN; CHK `android`, `ios` |
| `push_token_ciphertext` | bytea | Nullable; encrypted application value |
| `token_fingerprint` | text | Nullable; UQ when present |
| `app_version` | text | NN |
| `last_seen_at` | timestamptz | NN |
| `revoked_at` | timestamptz | Nullable |

### 6.5 notification_preferences

| Column | Type | Rules |
| --- | --- | --- |
| `user_id` | uuid | PK and FK |
| `mission_enabled` | boolean | NN default true |
| `reward_enabled` | boolean | NN default true |
| `quiet_start_local` | time | Nullable only as pair with quiet end |
| `quiet_end_local` | time | Nullable only as pair with quiet start |
| `preferred_window_start_local` | time | Nullable |
| `preferred_window_end_local` | time | Nullable |
| `timezone` | text | NN; valid IANA timezone |
| `lock_screen_detail` | text | NN; CHK `minimal`, `subject`, `detailed` |
| `max_daily_reminders` | smallint | NN; CHK 0 to configured cap |

## 7 Curriculum and knowledge graph

### 7.1 subjects and curriculum_versions

| Table | Essential columns and constraints |
| --- | --- |
| `subjects` | `id`; `code` UQ; `name`; `status`; `created_at` |
| `curriculum_versions` | `id`; `subject_id` FK; `authority`; `edition_code`; `language_medium`; `valid_from`; `valid_to`; `status`; UQ `(subject_id, edition_code, language_medium)` |

The MVP seed contains Physics and exactly one approved launch curriculum version: the National Institute of Education G.C.E. Advanced Level Physics syllabus implemented from 2017, English medium. A curriculum is retired or superseded, never overwritten.

### 7.2 learning_objectives

| Column | Type | Rules |
| --- | --- | --- |
| `id` | uuid | PK |
| `curriculum_version_id` | uuid | FK; NN; IDX |
| `objective_code` | text | NN; UQ within curriculum |
| `parent_objective_id` | uuid | Self FK; nullable |
| `title` | text | NN |
| `description` | text | NN |
| `sequence_no` | integer | NN; CHK non-negative |
| `status` | text | NN; CHK `draft`, `approved`, `retired` |

Cycles in objective parentage are prohibited by service validation and migration tests.

### 7.3 concepts and concept_versions

`concepts` supplies stable identity. `concept_versions` supplies immutable academic meaning.

| Table | Essential columns and constraints |
| --- | --- |
| `concepts` | `id`; `subject_id` FK; `stable_code` UQ within subject; `status`; timestamps |
| `concept_versions` | `id`; `concept_id` FK; `version_no`; `kind`; `title`; `definition`; `symbol_context`; `unit_context`; `content_status`; `reviewed_by`; `reviewed_at`; UQ `(concept_id, version_no)` |

Allowed `kind` values are `concept`, `principle`, `law`, `formula`, `variable`, `unit`, `method`, `diagram_skill` and `misconception`. Published rows are immutable.

### 7.4 concept_aliases

| Column | Type | Rules |
| --- | --- | --- |
| `id` | uuid | PK |
| `concept_version_id` | uuid | FK; NN; IDX |
| `alias_text` | text | NN |
| `normalized_alias` | text | NN |
| `language_code` | text | NN |
| `alias_type` | text | NN; CHK `term`, `symbol`, `abbreviation`, `spelling` |
| `is_preferred` | boolean | NN default false |

Duplicate normalized aliases are allowed across concepts but must not be auto-merged without disambiguation context.

### 7.5 knowledge_claims

| Column | Type | Rules |
| --- | --- | --- |
| `id` | uuid | PK |
| `concept_version_id` | uuid | FK; NN; IDX |
| `version_no` | integer | NN |
| `claim_type` | text | NN; CHK `definition`, `condition`, `formula`, `example`, `misconception`, `solution_step` |
| `statement` | text | NN |
| `structured_value` | jsonb | Nullable; validated by claim type |
| `status` | text | NN; CHK `draft`, `approved`, `disputed`, `retired` |
| `provenance_type` | text | NN |
| `provenance_ref` | text | NN |
| `reviewed_by` | uuid | Nullable reviewer principal |
| `reviewed_at` | timestamptz | Nullable |

Required constraint: version uniqueness must include a stable logical claim identifier; implementation may use `claim_group_id uuid` plus `version_no`.

### 7.6 concept_edges

| Column | Type | Rules |
| --- | --- | --- |
| `id` | uuid | PK |
| `from_concept_version_id` | uuid | FK; NN |
| `to_concept_version_id` | uuid | FK; NN |
| `edge_type` | text | NN; allowlisted ontology value |
| `confidence` | numeric(6,5) | NN; CHK 0 to 1 |
| `status` | text | NN; CHK `candidate`, `approved`, `rejected`, `retired` |
| `provenance_type` | text | NN |
| `provenance_ref` | text | NN |
| `valid_from` | timestamptz | NN |
| `valid_to` | timestamptz | Nullable |

The initial edge allowlist includes `prerequisite_of`, `applies_under`, `contradicts`, `example_of`, `misconception_about` and `related_to`. Self-edges are rejected except where an explicitly approved edge type permits them. Approved active duplicates are prohibited.

### 7.7 concept_objective_maps

Join table with `concept_version_id`, `learning_objective_id`, `mapping_type`, `coverage_weight` and provenance. The composite key is `(concept_version_id, learning_objective_id, mapping_type)`. `coverage_weight` is in 0 to 1.

### 7.8 Semantic embeddings

Embeddings use target-specific tables rather than an unconstrained polymorphic foreign key:

The MVP embedding model is a self-hosted NVIDIA Nemotron 3.5 Embed 1B deployment using its 2048-dimensional output. Each embedding column is therefore `vector(2048)`. The OpenRouter free endpoint is prohibited because its provider retains requests and may use them for training, which conflicts with private student-note ingestion. A model or dimension change requires a new reviewed migration and re-embedding workflow; vectors from different model keys are never compared.

- `concept_embeddings(concept_version_id, model_key, embedding, content_hash, created_at)`
- `claim_embeddings(knowledge_claim_id, model_key, embedding, content_hash, created_at)`
- `question_embeddings(question_version_id, model_key, embedding, content_hash, created_at)`

The primary key is the target ID plus `model_key`. A content-hash change requires a new embedding. Queries must include curriculum, status and authorization filters before ranking results.

## 8 Learning ingestion and temporary material

### 8.1 learning_updates

| Column | Type | Rules |
| --- | --- | --- |
| `id` | uuid | PK |
| `user_id` | uuid | FK; NN; IDX |
| `subject_id` | uuid | FK; NN |
| `curriculum_version_id` | uuid | FK; NN |
| `input_type` | text | NN; CHK `manual_text`, `pdf`, `image`, `mixed` |
| `manual_text_ciphertext` | bytea | Nullable; encrypted; cleared or retained under approved policy |
| `status` | text | NN; CHK `draft`, `uploading`, `processing`, `verification_required`, `committed`, `failed`, `expired`, `deleted` |
| `learned_at` | timestamptz | NN |
| `client_operation_id` | uuid | NN; UQ with user |
| `failure_code` | text | Nullable; safe code only |
| `expires_at` | timestamptz | Nullable; required before commit |

Multiple rows per user and day are allowed. No uniqueness constraint may collapse same-day updates.

### 8.2 source_uploads

| Column | Type | Rules |
| --- | --- | --- |
| `id` | uuid | PK |
| `learning_update_id` | uuid | FK; NN; IDX |
| `user_id` | uuid | FK; NN; must match update owner |
| `object_key` | text | NN; UQ; random and non-guessable |
| `declared_name` | text | NN; sanitized display value |
| `declared_media_type` | text | NN |
| `detected_media_type` | text | Nullable |
| `byte_size` | bigint | NN; CHK positive and within limit |
| `content_sha256` | text | Nullable; lowercase digest |
| `status` | text | NN; CHK `authorized`, `uploaded`, `validated`, `processing`, `deleting`, `deleted`, `rejected`, `expired` |
| `validation_result` | jsonb | NN default `{}`; safe scanner and decoder evidence |
| `expires_at` | timestamptz | NN |
| `deleted_at` | timestamptz | Nullable |

The database does not store file bytes, OCR images or page renders.

### 8.3 extraction_candidates

Temporary structured model evidence.

| Column | Type | Rules |
| --- | --- | --- |
| `id` | uuid | PK |
| `learning_update_id` | uuid | FK; NN; IDX |
| `candidate_type` | text | NN; CHK `concept`, `claim`, `edge`, `formula`, `variable`, `unit`, `diagram`, `example` |
| `candidate_payload` | jsonb | NN; schema-versioned |
| `source_locator` | jsonb | NN; page, region or text-range reference without raw binary |
| `confidence` | numeric(6,5) | NN |
| `model_key` | text | NN |
| `prompt_version` | text | NN |
| `schema_version` | text | NN |
| `status` | text | NN; CHK `candidate`, `needs_verification`, `accepted`, `rejected`, `committed`, `expired` |
| `expires_at` | timestamptz | NN |

Candidates cannot reference a different user's update. They cannot become graph rows except through a `knowledge_commit` transaction.

### 8.4 verification_requests and verification_decisions

| Table | Essential columns and constraints |
| --- | --- |
| `verification_requests` | `id`; `learning_update_id`; `candidate_id`; `reason_code`; `question_text`; `options jsonb`; `status`; `expires_at`; one active request per candidate |
| `verification_decisions` | `id`; `verification_request_id`; `user_id`; `decision`; `corrected_payload jsonb`; `decided_at`; APPEND; one accepted terminal decision per request |

Allowed decisions are `accept`, `correct`, `reject` and `skip`. A corrected payload is validated against the candidate schema before commit.

### 8.5 knowledge_commits

| Column | Type | Rules |
| --- | --- | --- |
| `id` | uuid | PK; APPEND |
| `learning_update_id` | uuid | FK; NN; UQ for successful commit version |
| `user_id` | uuid | FK; NN |
| `commit_version` | integer | NN |
| `candidate_snapshot_hash` | text | NN |
| `committed_counts` | jsonb | NN; concept, claim and edge counts |
| `transaction_id` | text | NN; operational correlation only |
| `committed_at` | timestamptz | NN |
| `outbox_event_id` | uuid | FK; NN |

Commit atomically writes retained private knowledge or mappings, exposure events and an outbox event. Source deletion is a later verified lifecycle step.

### 8.6 Private extracted knowledge

Content that cannot safely map to approved shared knowledge is stored in `private_knowledge_items` with `user_id`, `learning_update_id`, `item_type`, validated structured content, confidence, provenance and status. It may link to a shared `concept_version_id` only after deterministic acceptance or review. Private rows never become shared by changing an ownership flag; promotion creates reviewed shared records with independent provenance.

## 9 Questions rubrics and reports

### 9.1 questions and question_versions

| Table | Essential columns and constraints |
| --- | --- |
| `questions` | `id`; `subject_id`; stable `question_code`; `source_class`; `status`; author/reviewer principal; timestamps |
| `question_versions` | `id`; `question_id`; `version_no`; `question_type`; `prompt`; `explanation`; `content_payload jsonb`; `trust_label`; `curriculum_version_id`; `validation_status`; generation metadata; UQ `(question_id, version_no)` |

Allowed source classes are `expert_verified`, `teacher_authored` and `ai_generated`. Teacher content is future-facing and may exist only behind disabled workflow flags in the MVP. Allowed question types are `mcq`, `numeric`, `short_answer` and `diagram_interpretation`.

Published versions are immutable. AI-generated versions store `model_key`, `prompt_version`, grounding evidence IDs, validator version, validation score and generation trace reference. They never store hidden provider reasoning.

### 9.2 question_options

MCQ and option-based diagram questions use rows containing `question_version_id`, stable `option_key`, display text, optional accessible image reference, `is_correct`, explanation and `display_order`. Correctness is server-only and excluded from student payloads before submission. Unique constraints cover `(question_version_id, option_key)` and display order.

### 9.3 question_rubrics

| Column | Type | Rules |
| --- | --- | --- |
| `id` | uuid | PK |
| `question_version_id` | uuid | FK; NN; UQ |
| `rubric_type` | text | NN; matches question type |
| `rubric_version` | integer | NN |
| `rubric_payload` | jsonb | NN; validated typed schema |
| `max_score` | numeric(8,3) | NN; positive |
| `evidence_ceiling` | numeric(6,5) | NN; 0 to 1 |
| `status` | text | NN; CHK `draft`, `approved`, `retired` |

Numeric rubrics include expected quantity, unit rule, tolerance and significant figures. Short-answer rubrics contain required claims, acceptable variants, contradiction rules and confidence thresholds.

### 9.4 question_concept_maps

Join table with `question_version_id`, `concept_version_id`, `learning_objective_id`, `mapping_role`, `weight` and provenance. Roles include `primary`, `supporting`, `prerequisite` and `misconception`. At least one primary mapping is required before publication.

### 9.5 question_reports

| Column | Type | Rules |
| --- | --- | --- |
| `id` | uuid | PK |
| `user_id` | uuid | FK; NN |
| `question_version_id` | uuid | FK; NN |
| `attempt_id` | uuid | FK; nullable |
| `report_type` | text | NN; CHK `question_error`, `answer_error`, `explanation_error`, `grading_dispute`, `accessibility` |
| `description_ciphertext` | bytea | Nullable; encrypted free text |
| `status` | text | NN; CHK `submitted`, `triaged`, `under_review`, `resolved`, `dismissed` |
| `resolution_code` | text | Nullable |
| `submitted_at` | timestamptz | NN |
| `resolved_at` | timestamptz | Nullable |

A report never edits historical question content. Regrading appends a new result and a compensating memory event.

## 10 Learner memory model

### 10.1 learner_concept_states

One row exists per user and stable concept identity.

| Column | Type | Rules |
| --- | --- | --- |
| `id` | uuid | PK |
| `user_id` | uuid | FK; NN |
| `concept_id` | uuid | FK; NN |
| `active_concept_version_id` | uuid | FK; NN |
| `difficulty` | numeric(8,5) | NN; bounded by engine contract |
| `stability_days` | numeric(12,5) | NN; CHK non-negative |
| `last_retrievability` | numeric(6,5) | NN |
| `evidence_confidence` | numeric(6,5) | NN |
| `first_exposed_at` | timestamptz | NN |
| `last_reviewed_at` | timestamptz | Nullable |
| `next_review_at` | timestamptz | NN; IDX |
| `exposure_count` | integer | NN; non-negative |
| `eligible_review_count` | integer | NN; non-negative |
| `lapse_count` | integer | NN; non-negative |
| `engine_version` | text | NN |

Required constraint: `unique (user_id, concept_id)`. The row is a current snapshot; history resides in events and decisions.

### 10.2 memory_events

Append-only evidence eligible to influence memory.

| Column | Type | Rules |
| --- | --- | --- |
| `id` | uuid | PK; APPEND |
| `user_id` | uuid | FK; NN; IDX |
| `concept_id` | uuid | FK; NN; IDX |
| `event_type` | text | NN; CHK `exposure`, `attempt`, `repair`, `regrade`, `invalidation`, `manual_review` |
| `source_type` | text | NN |
| `source_id` | uuid | NN |
| `observed_at` | timestamptz | NN |
| `score` | numeric(6,5) | Nullable; 0 to 1 |
| `confidence` | numeric(6,5) | NN |
| `is_eligible` | boolean | NN |
| `ineligibility_reason` | text | Nullable |
| `event_payload` | jsonb | NN; normalized safe evidence |

Required uniqueness: `(event_type, source_type, source_id, concept_id)`. Invalidation appends a new event referencing the invalidated event; it does not delete it.

### 10.3 memory_decisions

| Column | Type | Rules |
| --- | --- | --- |
| `id` | uuid | PK; APPEND |
| `user_id` | uuid | FK; NN |
| `concept_id` | uuid | FK; NN |
| `trigger_event_id` | uuid | FK; NN |
| `previous_state` | jsonb | NN; schema-versioned snapshot |
| `result_state` | jsonb | NN; schema-versioned snapshot |
| `retrievability_at_decision` | numeric(6,5) | NN |
| `next_review_at` | timestamptz | NN |
| `reason_codes` | text[] | NN; allowlisted values |
| `explanation_template_key` | text | NN |
| `engine_version` | text | NN |
| `policy_version` | text | NN |
| `decided_at` | timestamptz | NN |

The same `trigger_event_id`, `concept_id` and engine application may produce only one authoritative decision.

## 11 Missions attempts and grading

### 11.1 missions

| Column | Type | Rules |
| --- | --- | --- |
| `id` | uuid | PK |
| `user_id` | uuid | FK; NN; IDX |
| `subject_id` | uuid | FK; NN |
| `mission_date` | date | NN; derived with `mission_timezone` |
| `mission_timezone` | text | NN |
| `sequence_no` | smallint | NN default 1 |
| `status` | text | NN; CHK `planned`, `started`, `paused`, `completed`, `expired`, `abandoned` |
| `engine_version` | text | NN |
| `candidate_snapshot_hash` | text | NN |
| `estimated_minutes` | smallint | NN; positive and bounded |
| `planned_item_count` | smallint | NN; positive and bounded |
| `started_at` | timestamptz | Nullable |
| `completed_at` | timestamptz | Nullable |
| `expires_at` | timestamptz | NN |

Required uniqueness: `(user_id, subject_id, mission_date, sequence_no)`. Candidate details remain server-side and are not exposed as hidden work.

### 11.2 mission_items

| Column | Type | Rules |
| --- | --- | --- |
| `id` | uuid | PK |
| `mission_id` | uuid | FK; NN; IDX |
| `position` | smallint | NN; UQ within mission |
| `mission_type` | text | NN; CHK `protect`, `repair`, `recover`, `discover`, `challenge` |
| `question_version_id` | uuid | FK; NN |
| `primary_concept_id` | uuid | FK; NN |
| `selection_reason_codes` | text[] | NN |
| `priority_snapshot` | jsonb | NN; internal and not returned directly |
| `status` | text | NN; CHK `pending`, `presented`, `answered`, `skipped`, `cancelled` |
| `presented_at` | timestamptz | Nullable |

Question references are fixed when the mission starts. Later academic edits cannot alter an active or historical mission item.

### 11.3 attempts

| Column | Type | Rules |
| --- | --- | --- |
| `id` | uuid | PK; APPEND |
| `user_id` | uuid | FK; NN |
| `mission_item_id` | uuid | FK; NN; IDX |
| `attempt_no` | smallint | NN; UQ within item |
| `client_operation_id` | uuid | NN; UQ with user |
| `answer_payload` | jsonb | NN; validated against question type |
| `submitted_at` | timestamptz | NN |
| `elapsed_ms` | integer | Nullable; non-negative; optional and not authoritative by default |
| `app_version` | text | NN |
| `is_offline_submission` | boolean | NN default false |

Sensitive free-text answers are excluded from logs and analytics. The authoritative record may be encrypted at the application level if the approved data classification requires it.

### 11.4 grading_results

| Column | Type | Rules |
| --- | --- | --- |
| `id` | uuid | PK; APPEND |
| `attempt_id` | uuid | FK; NN |
| `result_version` | integer | NN; UQ within attempt |
| `grader_type` | text | NN; CHK `exact`, `numeric`, `rubric_model`, `human_review`, `invalidation` |
| `score` | numeric(6,5) | NN |
| `classification` | text | NN; CHK `correct`, `partial`, `incorrect`, `misconception`, `ungradable`, `invalidated` |
| `confidence` | numeric(6,5) | NN |
| `rubric_id` | uuid | FK; NN |
| `grader_version` | text | NN |
| `evidence_payload` | jsonb | NN; structured claim matches and safe reasons |
| `is_authoritative` | boolean | NN |
| `graded_at` | timestamptz | NN |

Only one grading result per attempt may be authoritative at a time. A replacement result appends a new version and marks authority through a transactional constraint or pointer on the attempt; history remains intact.

## 12 Engagement and seabed projections

### 12.1 xp_ledger

| Column | Type | Rules |
| --- | --- | --- |
| `id` | uuid | PK; APPEND |
| `user_id` | uuid | FK; NN; IDX |
| `amount` | integer | NN; non-zero |
| `entry_type` | text | NN; CHK `earn`, `correction`, `reversal` |
| `source_event_type` | text | NN |
| `source_event_id` | uuid | NN |
| `reason_code` | text | NN |
| `balance_after` | bigint | NN; CHK non-negative |
| `earned_at` | timestamptz | NN |

Required uniqueness: `(user_id, source_event_type, source_event_id, entry_type)`. Uploads and app opens are never eligible sources.

### 12.2 streak_days

One row per user-local day containing `user_id`, `local_date`, `timezone`, `qualification_type`, `mission_id`, `grace_window_key`, and `created_at`. Qualification types are `mission_completed`, `grace_used` and `comeback_completed`. Unique `(user_id, local_date)`. The rolling seven-day grace rule is calculated by policy, not a mutable counter supplied by the client.

### 12.3 reward_definitions and reward_grants

| Table | Essential columns and constraints |
| --- | --- |
| `reward_definitions` | `id`; stable `reward_code`; type `decoration` or `mora_cosmetic`; title; asset key; XP threshold; status |
| `reward_grants` | `id`; `user_id`; `reward_definition_id`; `source_xp_ledger_id`; `granted_at`; UQ `(user_id, reward_definition_id)`; APPEND |

Reward grants are permanent. A compensating XP entry cannot delete a granted reward unless fraud or administrative correction policy explicitly requires an audited exceptional workflow.

### 12.4 reef_projections

| Column | Type | Rules |
| --- | --- | --- |
| `id` | uuid | PK |
| `user_id` | uuid | FK; NN |
| `subject_id` | uuid | FK; NN |
| `condition` | text | NN; CHK `new`, `thriving`, `healthy`, `needs_care`, `dormant` |
| `health_score` | numeric(6,5) | NN |
| `due_memory_count` | integer | NN; non-negative |
| `prerequisite_risk` | numeric(6,5) | NN |
| `recent_evidence_score` | numeric(6,5) | NN |
| `projection_version` | text | NN |
| `source_watermark` | text | NN; identifies processed authoritative state |
| `projected_at` | timestamptz | NN |

Required uniqueness: `(user_id, subject_id)`. A new or untested reef is neutral. Projection rebuild must produce the same result for the same inputs and version.

## 13 Reliability operations and governance

### 13.1 idempotency_records

Stores `user_id` or service scope, endpoint or operation name, idempotency key, request hash, status, response reference, expiry and timestamps. Unique `(scope, operation, idempotency_key)`. Reuse with a different request hash is rejected.

### 13.2 outbox_events

Append-only rows containing aggregate type and ID, event type, event version, payload containing identifiers and safe facts, correlation ID, creation time, publication status and published time. Unique domain-event key prevents repeated publication. Outbox rows are written in the same transaction as the authoritative change.

### 13.3 background_jobs

| Column | Type | Rules |
| --- | --- | --- |
| `id` | uuid | PK |
| `job_type` | text | NN; allowlisted class |
| `owner_user_id` | uuid | Nullable; FK |
| `resource_type` | text | NN |
| `resource_id` | uuid | NN |
| `dedupe_key` | text | NN; UQ for active/logical job |
| `status` | text | NN; CHK `queued`, `leased`, `retry_wait`, `succeeded`, `failed`, `dead_lettered`, `cancelled` |
| `attempt_count` | integer | NN; non-negative |
| `max_attempts` | integer | NN; positive |
| `available_at` | timestamptz | NN; IDX |
| `lease_owner` | text | Nullable |
| `lease_expires_at` | timestamptz | Nullable |
| `last_error_code` | text | Nullable; safe code only |
| `payload` | jsonb | NN; IDs and bounded parameters only |

Document text, answers, tokens and secrets are prohibited in job payloads.

### 13.4 audit_events

Append-only events for consent, exports, deletion, access changes, privileged reviews and policy changes. Required fields are actor type and ID, action, resource type and ID, authorization context, outcome, request/correlation IDs, safe metadata and timestamp. Audit metadata must not contain student note text, answer text, tokens or model prompts.

### 13.5 privacy_requests and deletion_proofs

| Table | Essential columns and constraints |
| --- | --- |
| `privacy_requests` | `id`; `user_id`; request type `export` or `delete`; verified time; status; requested/completed times; failure code; workflow version |
| `deletion_proofs` | `id`; `privacy_request_id` or `source_upload_id`; scope; provider; target fingerprint; result; verified_at; reconciler version; APPEND |

An account is marked `deleted` only after required deletion scopes are proven or an approved legal/security retention exception is recorded. Proofs store identifiers and results, not deleted content.

## 14 Database constraints and transaction boundaries

### 14.1 Required database invariants

- Private child rows must match the parent's `user_id`. Enforce with composite foreign keys where practical and service assertions plus database tests elsewhere.
- A mission item references one immutable question version.
- An attempt references one mission item and user owner.
- An eligible attempt cannot generate more than one authoritative memory event per mapped concept.
- One source event cannot produce duplicate XP or reward grants.
- A successful learning update commit cannot reference expired or rejected candidates.
- Published academic rows cannot be updated in place.
- A deleted source upload cannot return to an available state.
- Confidence and probability values remain between zero and one.
- Counters, XP balances, sizes and durations remain within documented non-negative bounds.

### 14.2 Transaction boundaries

| Operation | Atomic writes |
| --- | --- |
| Knowledge commit | Accepted candidates, retained mappings/private knowledge, exposure events, update status and outbox event |
| Answer submission | Attempt insertion and answer-received outbox event; grading may follow asynchronously |
| Deterministic grading | Grading result, memory event and grading outbox event |
| Memory update | Memory decision, current learner-concept snapshot and schedule-change outbox event |
| Mission completion | Item states, mission state and one completion event; XP/streak consumers remain idempotent |
| Reward grant | Reward row and associated projection event |
| Privacy state change | Request state, audit event and workflow job |

External provider calls never occur while a database transaction remains open.

## 15 Index strategy

Create indexes from measured query contracts, beginning with:

| Table | Index | Purpose |
| --- | --- | --- |
| `learner_concept_states` | `(user_id, next_review_at)` where due/active | Daily Mission candidate selection |
| `learner_concept_states` | `(user_id, concept_id)` UQ | Independent learner memory |
| `missions` | `(user_id, mission_date desc)` | Home and history |
| `mission_items` | `(mission_id, position)` UQ | Stable mission order |
| `attempts` | `(user_id, client_operation_id)` UQ | Idempotent submission |
| `memory_events` | `(user_id, concept_id, observed_at desc)` | Evidence history |
| `concept_edges` | `(from_concept_version_id, edge_type)` and `(to_concept_version_id, edge_type)` | Bounded graph traversal |
| `concept_aliases` | normalized alias search index | Candidate matching |
| `source_uploads` | `(status, expires_at)` | Deletion and expiry reconciliation |
| `extraction_candidates` | `(learning_update_id, status)` | Verification and commit |
| `background_jobs` | `(status, available_at)` partial active | Worker claiming |
| `outbox_events` | `(publication_status, created_at)` partial unpublished | Publisher polling |
| `question_versions` | `(curriculum_version_id, validation_status, question_type)` | Eligible question selection |
| embedding tables | vector index scoped by approved model | Semantic retrieval after benchmark selection |

Do not add UUID-only ordering assumptions. Vector index type and parameters require production-like recall and latency benchmarks.

## 16 Row isolation and access rules

### 16.1 Application authorization

The service derives `user_id` from the validated OIDC token and passes it through typed repository methods. Student endpoints never accept an owner ID as authority. Reviewer and administrator operations use separate roles, step-up authentication and audit logging.

### 16.2 Row-level security

RLS is defense in depth for direct user-owned tables including learning updates, uploads, private knowledge, verification, learner states, missions, attempts, reports, ledgers, rewards and privacy requests. Policies compare `user_id` with a transaction-local authenticated principal set only by the API connection wrapper. Worker roles use narrowly scoped policies or security-definer functions reviewed by security.

Shared academic tables are readable when published. Draft, disputed and retired content requires reviewer authorization. No generic service role may bypass all policies in normal request handling.

### 16.3 Field protection

- Free-text reports, retained manual learning text and any approved sensitive answer fields use application-level encryption where required by the final data classification.
- Push tokens are encrypted and fingerprinted for deduplication.
- Searchable sensitive plaintext is not introduced without privacy and security review.
- Secrets, access tokens, raw provider responses and hidden model reasoning are never stored in business tables.

## 17 Retention deletion and restoration

| Data class | Retention rule | Deletion behavior |
| --- | --- | --- |
| Temporary upload bytes | Short bounded processing/verification window | Verified object and derivative deletion with proof |
| Extraction candidates | Until commit, terminal failure or verification expiry | Delete or irreversibly minimize after retained result is committed |
| Learning evidence | Account lifetime unless corrected or legally constrained | Removed through verified account deletion |
| Shared reviewed content | Version history under academic governance | Retire; do not erase referenced versions |
| Operational jobs/outbox | Bounded operational retention | Purge after reconciliation and audit requirements |
| Security audit | Approved tamper-resistant retention | Legal/security schedule; exception documented |
| Analytics | Minimized and de-identified where possible | Retention-limited; delete direct-user links with account workflow |

Backups intentionally exclude temporary object storage. Database restoration must re-run expiry, deletion and projection reconcilers before restored services accept traffic.

## 18 Migration and seed-data rules

### 18.1 Migration rules

- Every schema change is a reviewed, ordered forward migration.
- Destructive changes use expand-migrate-contract: add compatible structure, backfill in bounded batches, deploy readers, then remove old structure later.
- Migrations do not make network calls or invoke models.
- Large index creation uses non-blocking PostgreSQL techniques where supported and is separated from transactional DDL when required.
- Backfills are restartable, observable and idempotent.
- Every migration has a roll-forward recovery plan; rollback is used only when data safety is proven.
- Application code remains compatible with the previous schema during rolling deployment.

### 18.2 Required seed data

Seed data is version-controlled and environment-safe. The MVP requires:

- Physics subject definition.
- The approved NIE G.C.E. Advanced Level Physics curriculum implemented from 2017, English medium.
- Mission types and reason-code allowlists.
- Graph edge-type allowlist.
- Question type and source-class allowlists.
- Initial memory-engine and policy version records.
- Reward definitions and XP thresholds approved by product.
- Safe system roles without production user accounts or secrets.

## 19 Data contracts for JSONB

Every JSONB column has a named schema version. Unknown required fields fail closed; unknown optional fields follow explicit forward-compatibility rules. JSONB is not used to avoid relational modeling for identifiers, ownership, status, money, timestamps or common query fields.

| Payload | Required schema properties |
| --- | --- |
| Candidate payload | candidate type, normalized fields, units/conditions where relevant, confidence evidence |
| Question content | type-specific prompt media, constants and response configuration |
| Rubric payload | deterministic numeric rules or bounded claim criteria |
| Answer payload | question-version ID and type-specific response only |
| Memory snapshots | all state values, engine schema version and input watermark |
| Accessibility preferences | allowlisted preference keys and preference schema version |
| Job payload | resource identifiers, operation version and bounded retry parameters |

JSON schemas live in the backend repository and generate or validate corresponding Flutter DTOs where the payload crosses the API boundary.

## 20 Observability and analytics boundaries

Database and application telemetry may record table or operation class, duration, row count, safe status code, request ID and correlation ID. It must not record source text, answers, push tokens, access tokens, encrypted ciphertext, question keys or raw model prompts.

Product analytics uses a versioned event catalog outside the transactional schema. Business events originate from the outbox. Analytics consumers receive the minimum approved properties and a pseudonymous identifier when user linkage is necessary. Analytics is never the source of truth for XP, streaks, mission completion or memory decisions.

## 21 Verification requirements

### 21.1 Database tests

- Foreign-key, uniqueness, check and immutability tests for every domain.
- Negative cross-user read and write tests with RLS enabled.
- Migration tests from the oldest supported deployed schema to current.
- Recursive graph tests for direction, depth and cycle bounds.
- Vector retrieval tests proving curriculum and ownership filters cannot be bypassed.
- Concurrency tests for answer submission, grading, memory update, XP and reward grants.
- Property tests for confidence bounds, counters and replay determinism.
- Retention tests for expired candidates, uploads and deletion proofs.

### 21.2 Required scenario

The schema passes when one student can create two same-day updates, verify an uncertain candidate, commit overlapping knowledge without duplicate obligations, delete the temporary source, receive a mission mixing a new concept and weak prerequisite, submit deterministic and bounded-model answers, create one memory update and one XP entry per eligible event, update the neutral/new Physics reef, report an item, change preferences, and complete export or account deletion without accessing another student's rows.

## 22 Requirement traceability

| Product requirement | Primary schema areas |
| --- | --- |
| PRD 001-004 account and preferences | `users`, profiles, consent, devices and notification preferences |
| PRD 005-010 learning ingestion | learning updates, uploads, candidates, verification, commits and private knowledge |
| PRD 011-016 memory and missions | learner states, memory events/decisions, missions and mission items |
| PRD 017-022 questions and feedback | question versions, rubrics, mappings, attempts, grading and reports |
| PRD 023-030 progress and game | missions, XP ledger, streak days, rewards and reef projection |
| PRD 031-035 privacy and account control | preferences, consent, privacy requests, jobs, audit and deletion proofs |
| TRD sections 7-9 | relational graph, pgvector, learner state and decision history |
| TRD sections 11-16 | upload lifecycle, grading, engagement, authorization, governance and reliability |

## 23 Implementation order

1. Create extensions, shared types/check helpers and identity tables.
2. Create curriculum, concept, graph and academic-version tables.
3. Create ingestion lifecycle and temporary candidate tables.
4. Create questions, versions, rubrics and mappings.
5. Create learner memory, missions, attempts and grading tables.
6. Create ledgers, rewards and reef projection.
7. Create idempotency, outbox, jobs, audit and privacy workflow tables.
8. Apply RLS, indexes and immutable-row protections.
9. Load reviewed seed data.
10. Run schema, authorization, concurrency, migration and end-to-end tests.

## 24 Definition of done

Document 4 is implemented when:

- Every table and constraint required for the MVP has a reviewed migration.
- Ownership and RLS tests prove cross-user isolation.
- Published academic content and append-only evidence cannot be silently rewritten.
- Duplicate requests and jobs cannot duplicate learning evidence or rewards.
- Upload expiry and deletion proof workflows are testable end to end.
- Mission, grading, memory and reef projections are reproducible from authoritative rows.
- All JSONB payloads have versioned schemas and validators.
- Required indexes meet pilot query targets under production-like data.
- Backup restoration re-applies retention and projection reconciliation.
- PRD and TRD traceability tests pass.

## 25 Open decisions inherited from earlier documents

These values must be resolved before production data is created, but they do not change the model shape:

- Final OIDC provider and locally retained profile fields.
- Exact retention periods by data class.
- Vector-index strategy after production-like recall and latency benchmarks. Embeddings use self-hosted NVIDIA Nemotron 3.5 Embed 1B at 2048 dimensions.
- Initial memory parameters and evidence-confidence thresholds.
- Minimum verified-question coverage and reviewer identity source.
- Age, consent and cross-border processing rules from the legal review.

