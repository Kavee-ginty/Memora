# T24 Pilot MCQ Candidates

**Status:** Stage 1 candidate record. None of these items is approved, imported or published.

**Scope:** eight text-only MCQs selected for a small pilot. Each item is a candidate for review, not a finished question-bank entry. Tracked text deliberately contains source references, topic summaries, derived answers and non-verbatim notes only. Verbatim prompts and options are kept in the ignored local review pack `local_review/PILOT_QUESTIONS_VERBATIM.md` for page-image comparison.

## 1. Status vocabulary

| Field | Meaning in this file |
| --- | --- |
| Derived answer | An answer calculated from the printed question by the analyst. It is not an official key. |
| Official key | A key published by the examining authority. None was found for these items. |
| Independent review | A second qualified person has checked the transcription, derivation, ambiguity and mapping. All eight are `pending`. |
| Reproduction approval | Permission to reproduce the question text or a close adaptation. All eight are `not approved`. |
| Principal | A real author or reviewer account. No principal is assigned in this file. |
| Publication | T12 `validation_status = approved`. All eight remain outside that state. |

No reviewer name, principal UUID, qualification or approval record has been invented.

## 2. Candidate summary

| Pilot ID | Paper / question | PDF page | Topic | Derived key | Mapping status | Review |
| --- | --- | --- | --- | --- | --- | --- |
| `PILOT-PHYS-2025-P1-Q01` | 2025 Paper I Q1 | 1 | Units of energy | (5) | complete: SI units + dimensions | pending |
| `PILOT-PHYS-2025-P1-Q02` | 2025 Paper I Q2 | 1 | Percentage error of a period | (3) | blocked: measurement uncertainty missing | pending |
| `PILOT-PHYS-2025-P1-Q05` | 2025 Paper I Q5 | 1 | Projectile statements | (3) | blocked: projectile motion missing | pending, ambiguity flag |
| `PILOT-PHYS-2025-P1-Q12` | 2025 Paper I Q12 | 2 | Static friction, four-wheel drive | (2) | blocked: friction missing | pending, ambiguity flag |
| `PILOT-PHYS-2025-P1-Q14` | 2025 Paper I Q14 | 2 | Independence of horizontal and vertical motion | (5) | blocked: projectile motion missing | pending |
| `PILOT-PHYS-2025-P1-Q45` | 2025 Paper I Q45 | 8 | Collisions and momentum | (5) | weak: momentum variable only; conservation/collision missing | pending |
| `PILOT-PHYS-2022-P1-Q01` | 2022 Paper I Q1 | 1 | Vector and scalar quantities | (4) | blocked: vector/scalar concept missing | pending, ambiguity flag |
| `PILOT-PHYS-2022-P1-Q17` | 2022 Paper I Q17 | 3 | Simple pendulum in an accelerating elevator | (4) | weak: general SHM only; pendulum/effective gravity missing | pending |

Only 2025 Q1 has a complete existing T08 primary/supporting mapping. **Seven of the eight candidates lack a complete mapping.** Six topic areas are absent from T08: measurement uncertainty, projectile motion, static friction, conservation of momentum/elastic collision, scalar/vector classification, and simple pendulum/effective gravity.

The source files, hashes and page counts are in `source_manifest.json`. The 2025 paper is an image scan with no text layer; rendered page 2 carries a `Past Papers Wiki` watermark. The 2022 paper is an annotated CamScanner scan. The local verbatim transcriptions must be checked against the page image by an independent reviewer. They are not tracked content.

## 3. Question records

### 3.1 `PILOT-PHYS-2025-P1-Q01`

**Source:** `AL_Physics_2025_Combined_Paper_English.pdf`, Paper I, question 1, PDF page 1.

**Proposed question code:** `phys-2025-p1-q01`

**Topic summary:** Identify which of five printed expressions is not an energy unit.

**Derived answer:** printed option (5).

**Derivation:** Four expressions reduce to the joule. The remaining expression reduces to the watt, which is power rather than energy. The item therefore turns on dimensional equivalence, not on a memorised list of unit names.

**Official key:** none found. The 2025 marking-scheme page 2 is a question-to-marks table, not an MCQ answer grid.

**Mapping proposal (not approved):**

| Concept | T08 code | Role | Proposed weight |
| --- | --- | --- | --- |
| International System of Units (SI) | `PHYS-MEA-SI-UNITS` | primary | 0.70 |
| Dimensions of Physical Quantities | `PHYS-MEA-DIMENSIONS` | supporting | 0.30 |

Both concepts and the objectives `LO-PHYS-01-01-UNITS` / `LO-PHYS-01-02-DIMS` exist in T08. This is the only candidate with a clean existing mapping. The proposed provenance type is `analyst_mapping`, not `pilot_review`.

**Rubric proposal:** exact, one correct option, `max_score = 1`. The evidence ceiling is a reviewer decision and is not set here.

**Review flags:**

- The wording "unit of energy" is broad enough to include a non-SI commercial energy unit.
- The item must not be reduced to a memorised list of units.
- No exact duplicate among the eight candidates.

---

### 3.2 `PILOT-PHYS-2025-P1-Q02`

**Source:** `AL_Physics_2025_Combined_Paper_English.pdf`, Paper I, question 2, PDF page 1.

**Proposed question code:** `phys-2025-p1-q02`

**Topic summary:** Percentage error in the period when a stopwatch times ten oscillations.

**Derived answer:** printed option (3).

**Derivation:** The measured total is 20.0 s for 10 oscillations, so the period is 2.0 s. Taking the least count 0.1 s as the timing uncertainty gives a relative error of `0.1 / 20.0 = 0.005`. Dividing by 10 does not change the relative error, so the period error is also 0.5%.

**Official key:** none found. The 2025 marking-scheme page 2 is a question-to-marks table, not an MCQ answer grid.

**Mapping proposal (not approved):** No T08 concept covers measurement uncertainty or percentage error. `PHYS-MEA-DIMENSIONS` covers dimensions and dimensional analysis, not error propagation. A new reviewed concept such as "measurement uncertainty and percentage error" is required under Measurement. No code or UUID is proposed here because it does not exist.

**Rubric proposal:** exact, one correct option, `max_score = 1`. The evidence ceiling is a reviewer decision and is not set here.

**Review flags:**

- The item assumes the least count is the only uncertainty and ignores reaction time and reading error. That is the standard A/L treatment, but the reviewer must confirm it.
- The relative-error argument for a time interval covering ten oscillations must be explicit in the student-facing explanation.
- **Mapping blocker:** a T12 `approved` import needs at least one primary concept mapping. This item cannot be published until the graph has an uncertainty concept.

---

### 3.3 `PILOT-PHYS-2025-P1-Q05`

**Source:** `AL_Physics_2025_Combined_Paper_English.pdf`, Paper I, question 5, PDF page 1.

**Proposed question code:** `phys-2025-p1-q05`

**Topic summary:** Statement analysis for projectile motion: kinetic energy, velocity at the apex, and acceleration.

**Derived answer:** printed option (3).

**Derivation:** The kinetic energy is not constant because the vertical velocity component changes. At the apex the vertical component is zero, but the horizontal component remains, so the velocity is not zero. With air resistance neglected, the acceleration is the constant gravitational acceleration. Only the third statement is true.

**Official key:** none found.

**Mapping proposal (not approved):** T08 has no projectile-motion concept. `PHYS-MEC-ACCELERATION` can support the constant-acceleration statement, but it does not cover projectile trajectories, independence of components or the velocity at the apex. A new reviewed concept such as "projectile motion" is required. The existing objective `LO-PHYS-02-01-KINEMATICS` is one-dimensional kinematics, so a new objective may also be required.

**Rubric proposal:** exact, one correct option, `max_score = 1`. The evidence ceiling is a reviewer decision and is not set here.

**Review flags:**

- **Ambiguity flag:** for a vertical launch the apex velocity would be zero. The item implicitly assumes a launch angle strictly between zero and 90 degrees. The reviewer must either add that condition or reject the item.
- **Mapping blocker:** no primary projectile concept exists in T08.
- Q14 is also projectile-related but tests independence of motion rather than statement analysis. They are not the same item.

---

### 3.4 `PILOT-PHYS-2025-P1-Q12`

**Source:** `AL_Physics_2025_Combined_Paper_English.pdf`, Paper I, question 12, PDF page 2.

**Proposed question code:** `phys-2025-p1-q12`

**Topic summary:** Minimum coefficient of static friction for a four-wheel-drive car accelerating uniformly from rest.

**Derived answer:** printed option (2).

**Derivation:** The final speed is 20 m/s, so the acceleration is `(20 - 0) / 5.0 = 4.0 m/s^2`. For a four-wheel-drive car the total horizontal driving force is static friction from the road, and the total normal reaction is `mg`. The limiting condition `mu mg >= ma` gives `mu = a/g = 4.0/10 = 0.4`.

**Official key:** none found.

**Mapping proposal (not approved):** T08 has no friction or static-friction concept. `PHYS-MEC-NEWTON2` can support the `F = ma` step, but the item is fundamentally about the friction limit. A new reviewed concept such as "static friction and the friction limit" is required. The existing objective `LO-PHYS-02-02-NEWTON-LAWS` is a partial fit.

**Rubric proposal:** exact, one correct option, `max_score = 1`. The evidence ceiling is a reviewer decision and is not set here.

**Review flags:**

- **Ambiguity flag:** the answer depends on the explicit four-wheel-drive condition. If only two wheels were driven, the available normal reaction would be smaller and the required coefficient would differ. The reviewer must confirm that the wording is sufficient.
- The paper states `g = 10 m s^-2`; the derivation must use that value.
- **Mapping blocker:** no primary friction concept exists in T08.

---

### 3.5 `PILOT-PHYS-2025-P1-Q14`

**Source:** `AL_Physics_2025_Combined_Paper_English.pdf`, Paper I, question 14, PDF page 2.

**Proposed question code:** `phys-2025-p1-q14`

**Topic summary:** Time of flight for one body dropped and one body thrown horizontally from the same height.

**Derived answer:** printed option (5).

**Derivation:** Both bodies have zero initial vertical velocity. With air resistance neglected, both have the same downward acceleration and fall the same vertical height, so the flight time is the same. The horizontal velocity does not affect the vertical motion.

**Official key:** none found.

**Mapping proposal (not approved):** T08 has no projectile or two-dimensional kinematics concept. `PHYS-MEC-ACCELERATION` supports the shared vertical acceleration, but it does not cover independence of horizontal and vertical motion. A new reviewed concept such as "independence of horizontal and vertical motion" is required.

**Rubric proposal:** exact, one correct option, `max_score = 1`. The evidence ceiling is a reviewer decision and is not set here.

**Review flags:**

- The item is text-only and has no diagram dependency.
- The phrase "time of flight" is used for both bodies; the reviewer should confirm that students will read it as the time to reach the ground.
- **Mapping blocker:** no primary projectile concept exists in T08.

---

### 3.6 `PILOT-PHYS-2025-P1-Q45`

**Source:** `AL_Physics_2025_Combined_Paper_English.pdf`, Paper I, question 45, PDF page 8.

**Proposed question code:** `phys-2025-p1-q45`

**Topic summary:** Ratio of post-collision speeds for a perfectly inelastic and a perfectly elastic collision with a heavier stationary block.

**Derived answer:** printed option (5).

**Derivation:** For the inelastic case, momentum conservation gives `V1 = v/4`. For the elastic case, the heavier block's speed is `V2 = 2mv/(m + 3m) = v/2`; the lighter block rebounds with speed `v/2`, confirming the direction. Therefore `V2/V1 = 2`.

**Official key:** none found.

**Mapping proposal (not approved):**

| Concept | T08 code | Role | Proposed weight |
| --- | --- | --- | --- |
| Linear Momentum | `PHYS-MEC-MOMENTUM` | primary | 0.50 |
| Newton's Third Law of Motion | `PHYS-MEC-NEWTON3` | supporting | 0.25 |
| Kinetic Energy | `PHYS-MEC-KINETIC-ENERGY` | supporting | 0.25 |

T08 has momentum as a `variable` concept, not a conservation-of-momentum principle, and has no elastic-collision concept. The mapping above is partial. A new reviewed principle such as "conservation of linear momentum" and a concept such as "elastic and inelastic collisions" are required before this item is a strong fit.

**Rubric proposal:** exact, one correct option, `max_score = 1`. The evidence ceiling is a reviewer decision and is not set here.

**Review flags:**

- The ratio is intended as a positive magnitude ratio; the reviewer must confirm that reading.
- The lighter block's rebound velocity is not asked for, but the explanation should state it to justify the elastic calculation.
- **Mapping weakness:** the primary T08 concept is a variable, not the conservation law that the item tests.

---

### 3.7 `PILOT-PHYS-2022-P1-Q01`

**Source:** `AL_Physics_2022_Combined_Paper_English.pdf`, Paper I, question 1, PDF page 1.

**Proposed question code:** `phys-2022-p1-q01`

**Topic summary:** Identify the pair in which the first quantity is a vector and the second is a scalar.

**Derived answer:** printed option (4).

**Derivation:** A vector has magnitude and direction; a scalar has magnitude only. Only one printed pair has the required vector-then-scalar order; the other pairs are scalar-scalar, scalar-vector or vector-vector. The item uses the A/L convention that torque is a vector.

**Official key:** none found. The 2022 marking-scheme page 2 is a question-to-marks table, not an MCQ key.

**Mapping proposal (not approved):** T08 has no vector/scalar classification concept. `PHYS-MEC-DISPLACEMENT`, `PHYS-MEC-VELOCITY` and `PHYS-MEC-MOMENTUM` are vector quantities, while `PHYS-MEC-WORK`, `PHYS-MEC-KINETIC-ENERGY` and `PHYS-MEC-GRAV-POT-ENERGY` are scalar quantities, but there is no concept that teaches the classification itself. A new reviewed concept such as "scalar and vector quantities" is required, probably under `LO-PHYS-02-01-KINEMATICS`.

**Rubric proposal:** exact, one correct option, `max_score = 1`. The evidence ceiling is a reviewer decision and is not set here.

**Review flags:**

- Torque is treated as a vector in the Sri Lankan A/L syllabus. The reviewer should confirm that the syllabus does not use a scalar sign convention in this context.
- The 2022 page carries handwritten annotations. The transcription must be checked against the clean printed text; the annotation is not evidence.
- **Mapping blocker:** no primary vector/scalar concept exists in T08.

---

### 3.8 `PILOT-PHYS-2022-P1-Q17`

**Source:** `AL_Physics_2022_Combined_Paper_English.pdf`, Paper I, question 17, PDF page 3.

**Proposed question code:** `phys-2022-p1-q17`

**Topic summary:** Period of a simple pendulum of doubled length in an elevator accelerating upward at `g/2`.

**Derived answer:** printed option (4).

**Derivation:** For a simple pendulum, `T = 2*pi*sqrt(l/g)`. The effective gravitational acceleration in the upward-accelerating elevator is `g' = g + g/2 = 3g/2`. With length `2l`, the new period is `T' = 2*pi*sqrt(2l / (3g/2)) = 2*pi*sqrt(4l/(3g)) = 2T/sqrt(3)`.

**Official key:** none found. The 2022 marking-scheme page 2 is a question-to-marks table, not an MCQ key.

**Mapping proposal (not approved):** `PHYS-WAV-SHM` is a partial fit: it covers simple harmonic motion and period, but T08 has no simple-pendulum concept and no effective-gravity concept. A new reviewed concept such as "simple pendulum and effective gravity" is required. The existing objective `LO-PHYS-03-01-SHM` is a partial fit.

**Rubric proposal:** exact, one correct option, `max_score = 1`. The evidence ceiling is a reviewer decision and is not set here.

**Review flags:**

- The item assumes the pendulum is at rest relative to the elevator and that the elevator's acceleration is constant. The reviewer should confirm that this is implicit in the wording.
- The symbol `g` is used both for gravitational acceleration and inside the elevator acceleration `g/2`; the explanation must distinguish them.
- **Mapping weakness:** the only existing T08 concept is general SHM, not the pendulum/effective-gravity application.

## 4. Cross-candidate checks

### 4.1 Exact duplicates

The ignored local review pack contains the verbatim comparisons. The Stage 1 observation is that no two prompts are identical and no two candidates share an identical option set. This is an exact-text check only; near-duplicate and semantic duplicate clearance remain pending.

### 4.2 Ambiguity

| Candidate | Flag | Required action |
| --- | --- | --- |
| 2025 Q2 | Least-count-only uncertainty assumption | Reviewer confirms the assumed error model. |
| 2025 Q5 | Vertical-launch edge case makes the apex statement true | Add a launch-angle condition or reject the item. |
| 2025 Q12 | Four-wheel-drive condition drives the answer | Reviewer confirms the wording and normal-reaction assumption. |
| 2022 Q1 | Torque treated as a vector | Reviewer confirms the syllabus convention. |
| 2022 Q17 | Elevator frame and constant acceleration assumed | Reviewer confirms the implicit assumptions. |

The other three items have no flagged ambiguity at this stage, but all remain pending independent review.

### 4.3 Coverage

T08 covers Units 1-3 only, and Unit 2 only partially. The candidate set covers:

- measurement units and dimensions (2025 Q1);
- measurement uncertainty (2025 Q2, missing concept);
- one-dimensional kinematics and Newtonian mechanics (2025 Q12, partial);
- projectile motion (2025 Q5 and Q14, missing concept);
- momentum and collisions (2025 Q45, partial);
- vector/scalar classification (2022 Q1, missing concept);
- simple harmonic motion and the simple pendulum (2022 Q17, partial).

The pilot does not cover waves, electricity, magnetism, thermal physics, modern physics or the full mechanics syllabus. This is an explicit coverage gap, not a claim of curriculum coverage.

### 4.4 Candidate-specific blocking gaps

1. A measurement-uncertainty concept and objective for 2025 Q2.
2. A projectile-motion concept and suitable objective for 2025 Q5 and Q14.
3. A static-friction concept for 2025 Q12.
4. A conservation-of-momentum principle and an elastic/inelastic collision concept for 2025 Q45.
5. A scalar/vector concept for 2022 Q1.
6. A simple-pendulum/effective-gravity concept for 2022 Q17.
7. A question-level source provenance record. T12 has no such field; see `T08_T12_CONTRACT_GAPS.md`.
8. A qualified reviewer and a review record with a real principal, qualification reference and date.
9. A reproduction decision for every past-paper item. Until then, only the ignored local review pack may hold verbatim text.

## 5. Excluded items

| Item | Reason |
| --- | --- |
| 2022 Paper I Q2 | Held back for ambiguity review; not part of the candidate set. |
| 2025 Paper I Q3 | Held back for ambiguity review of the spring-length/spring-constant wording. |
| Diagram-dependent items, including 2022 Q6, 2025 Q11 and 2025 Q41 | Deferred. The pilot is text-only; diagram accessibility and alt-text review are not yet designed. |

## 6. What this file does not claim

- It does not claim that any derived answer is the official answer.
- It does not claim that any item has been independently verified.
- It does not claim that any reviewer, author or principal exists.
- It does not claim reproduction or licence approval.
- It does not claim curriculum coverage beyond the eight listed items.
- It does not claim that any item is ready for T12 `approved` import.
