# T24 Physics pilot questions

This file is generated from the sealed envelopes under `questions/`. Do not edit it by hand; regenerate it with `python -m memora.modules.questions.pilot_reports --root content/physics/pilot --write`.

The pilot uses **expert review plus official marking-scheme verification**. Each answer was derived and then matched to the printed Department of Examinations Paper I answer grid. The named reviewer approved the transcription, derivation, explanation, mapping, ambiguity and duplicate checks. Self-review items are marked as such and do not claim independence. See `REVIEW_RECORD.md`.

## Summary

| Pilot ID | Year / question | Official key | Primary concept | Verification |
| --- | --- | ---: | --- | --- |
| `PILOT-PHYS-2022-P1-Q01` | 2022 Q1 | 4 | `PHYS-MEC-MOMENTUM` | expert self-review; official key matched |
| `PILOT-PHYS-2022-P1-Q17` | 2022 Q17 | 4 | `PHYS-WAV-SHM` | expert self-review; official key matched |
| `PILOT-PHYS-2024-P1-Q01` | 2024 Q1 | 5 | `PHYS-MEA-DIMENSIONS` | expert self-review; official key matched |
| `PILOT-PHYS-2024-P1-Q04` | 2024 Q4 | 1 | `PHYS-MEC-NEWTON3` | expert self-review; official key matched |
| `PILOT-PHYS-2024-P1-Q05` | 2024 Q5 | 5 | `PHYS-MEC-MOMENTUM` | expert self-review; official key matched |
| `PILOT-PHYS-2025-P1-Q01` | 2025 Q1 | 5 | `PHYS-MEC-WORK` | expert self-review; official key matched |
| `PILOT-PHYS-2025-P1-Q03` | 2025 Q3 | 1 | `PHYS-WAV-SHM` | expert self-review; official key matched |
| `PILOT-PHYS-2025-P1-Q45` | 2025 Q45 | 5 | `PHYS-MEC-MOMENTUM` | expert self-review; official key matched |

**Counts:** 8 questions; 11 of 14 T08 concepts covered; 3 explicit gaps.

## Coverage gaps

- `PHYS-MEC-DISPLACEMENT` - Displacement: no selected pilot question maps to this T08 concept.
- `PHYS-MEC-VELOCITY` - Velocity: no selected pilot question maps to this T08 concept.
- `PHYS-MEC-NEWTON1` - Newton's First Law of Motion: no selected pilot question maps to this T08 concept.

## Questions

### PILOT-PHYS-2022-P1-Q01

**Source:** `AL_Physics_2022_Combined_Paper_English.pdf` p.1, Q1 (2022(2023)). Marking scheme: `AL_Physics_2022_Combined_Marking_Scheme_English.pdf` p.2.

**Official key:** 4  
**Derived key:** 4  
**Sealed content hash:** `88c6c0190e56546d8d3e5ec1dd2b4d57b7ba9c6d2a38c63720d63004c845edcd`  
**Review:** `expert_review` / `self_review` by the named reviewer; academic status `approved`. See `content/physics/pilot/REVIEW_RECORD.md#independence-declaration`.

**Prompt:**

> Which one of the following pairs of quantities consists of a vector and a scalar, respectively?

**Options:**

1. Mass, Velocity
2. Power, Speed
3. Work, Distance
4. Force, Potential Energy **(correct)**
5. Momentum, Torque

**Explanation:** Force is a vector and potential energy is a scalar. In the other pairs the order is either scalar-vector (Mass, Velocity), scalar-scalar (Power, Speed; Work, Distance), or vector-vector (Momentum, Torque).

**Derivation:** Check the requested order (vector, scalar): (1) mass scalar, velocity vector -> reversed; (2) power scalar, speed scalar -> both scalar; (3) work scalar, distance scalar -> both scalar; (4) force vector, potential energy scalar -> correct; (5) momentum vector, torque vector -> both vector. Option 4. The official key is 4.

**Concept mapping:**

- Linear Momentum (`PHYS-MEC-MOMENTUM`, primary, weight 1)
- Gravitational Potential Energy (`PHYS-MEC-GRAV-POT-ENERGY`, supporting, weight 0.7)

**Provenance:** `SL-DOE-AL-PHYS-2022-P1 Q1; AL_Physics_2022_Combined_Marking_Scheme_English.pdf p.2`. Reproduction status: `unapproved`. Import status: `ready_for_import`; approved by Malshani Perera for batch `T24-PHYS-PILOT-2026-11`.

**Coverage note:** Covers vector/scalar classification using momentum and potential energy as examples.

### PILOT-PHYS-2022-P1-Q17

**Source:** `AL_Physics_2022_Combined_Paper_English.pdf` p.3, Q17 (2022(2023)). Marking scheme: `AL_Physics_2022_Combined_Marking_Scheme_English.pdf` p.2.

**Official key:** 4  
**Derived key:** 4  
**Sealed content hash:** `f0526870c2e27ed13aa2dc8044343d8a22033da567a533c0a76e7dae5a47a9e8`  
**Review:** `expert_review` / `self_review` by the named reviewer; academic status `approved`. See `content/physics/pilot/REVIEW_RECORD.md#independence-declaration`.

**Prompt:**

> The period of oscillation of a simple pendulum of length l is T. Suppose a simple pendulum of length 2l is hung from the ceiling of an elevator. What will be the period of oscillations of this pendulum if the elevator accelerates vertically upward at g/2?

**Options:**

1. T/(4√3)
2. T/(2√3)
3. T/√3
4. 2T/√3 **(correct)**
5. 4T/√3

**Explanation:** The period of a simple pendulum is T = 2π√(l/g). For length 2l the period is √2 T. In an elevator accelerating upward at g/2, the effective gravitational acceleration is g + g/2 = 3g/2, so the period becomes 2π√(2l/(3g/2)) = 2T/√3.

**Derivation:** Original period: T = 2π√(l/g). New length 2l: T0 = 2π√(2l/g) = √2 T. Effective gravity in an upward-accelerating elevator: g_eff = g + a = g + g/2 = 3g/2. New period: T' = 2π√(2l/(3g/2)) = 2π√(4l/(3g)) = (2/√3) 2π√(l/g) = 2T/√3. Option 4. The official key is 4.

**Concept mapping:**

- Simple Harmonic Motion (`PHYS-WAV-SHM`, primary, weight 1)
- Acceleration (`PHYS-MEC-ACCELERATION`, supporting, weight 0.5)
- Newton's Second Law of Motion (`PHYS-MEC-NEWTON2`, supporting, weight 0.3)

**Provenance:** `SL-DOE-AL-PHYS-2022-P1 Q17; AL_Physics_2022_Combined_Marking_Scheme_English.pdf p.2`. Reproduction status: `unapproved`. Import status: `ready_for_import`; approved by Malshani Perera for batch `T24-PHYS-PILOT-2026-11`.

**Coverage note:** Covers the simple-pendulum period and effective gravity in an accelerating frame.

### PILOT-PHYS-2024-P1-Q01

**Source:** `AL_Physics_2024_Combined_Paper_English.pdf` p.1, Q1 (2024). Marking scheme: `AL_Physics_2024_Combined_Marking_Scheme_English.pdf` p.5.

**Official key:** 5  
**Derived key:** 5  
**Sealed content hash:** `f4e89ffbbb74be8d8fa527823d6e87ebd998c65e75a38488d8d48ac34ef3e835`  
**Review:** `expert_review` / `self_review` by the named reviewer; academic status `approved`. See `content/physics/pilot/REVIEW_RECORD.md#independence-declaration`.

**Prompt:**

> Which of the following physical quantity has a unit but no dimensions?

**Options:**

1. Planck constant
2. Surface tension
3. Energy
4. Relative velocity
5. Sound intensity level **(correct)**

**Explanation:** Sound intensity level is a logarithmic ratio of two intensities. It is reported in decibels (dB), but it has no base dimensions. Planck constant (J s), surface tension (N m^-1) and energy (J) all have dimensions; relative velocity has dimensions of velocity and a unit.

**Derivation:** Check each option: Planck constant J s = kg m^2 s^-1 -> M L^2 T^-1; surface tension N m^-1 = kg s^-2 -> M T^-2; energy J = kg m^2 s^-2 -> M L^2 T^-2; relative velocity m s^-1 -> L T^-1. Sound intensity level is defined as 10 log10(I/I0), a ratio, so it has a unit label (dB) but no dimensions. The official key is 5.

**Concept mapping:**

- Dimensions of Physical Quantities (`PHYS-MEA-DIMENSIONS`, primary, weight 1)
- International System of Units (SI) (`PHYS-MEA-SI-UNITS`, supporting, weight 0.5)

**Provenance:** `SL-DOE-AL-PHYS-2024-P1 Q1; AL_Physics_2024_Combined_Marking_Scheme_English.pdf p.5`. Reproduction status: `unapproved`. Import status: `ready_for_import`; approved by Malshani Perera for batch `T24-PHYS-PILOT-2026-11`.

**Coverage note:** Covers dimensionless quantities and the distinction between a unit and a dimension; supports SI unit literacy.

### PILOT-PHYS-2024-P1-Q04

**Source:** `AL_Physics_2024_Combined_Paper_English.pdf` p.1, Q4 (2024). Marking scheme: `AL_Physics_2024_Combined_Marking_Scheme_English.pdf` p.5.

**Official key:** 1  
**Derived key:** 1  
**Sealed content hash:** `a9f113027d7e50b7d4b77d6eba2ba7821d846741a5a55436a1ac7eed014683b3`  
**Review:** `expert_review` / `self_review` by the named reviewer; academic status `approved`. See `content/physics/pilot/REVIEW_RECORD.md#independence-declaration`.

**Prompt:**

> Consider the following statements about a pair of action-reaction forces.
> (A) They are equal in magnitude but opposite in direction.
> (B) They act only on objects touching each other.
> (C) They act on the same object.
> Of the above statements,

**Options:**

1. only (A) is true. **(correct)**
2. only (A) and (B) are true.
3. only (A) and (C) are true.
4. only (B) and (C) are true.
5. all (A), (B) and (C) are true.

**Explanation:** Newton's third-law pair forces are equal in magnitude and opposite in direction, but they act on different bodies. They can act without contact, for example gravitational or magnetic forces. Statement B is false because contact is not required; C is false because action and reaction act on different objects. Only A is true.

**Derivation:** Newton's third law gives F_AB = -F_BA: equal magnitude and opposite direction (A true). Third-law pairs are interactions between two bodies and need not touch (B false). They never act on the same body (C false). Therefore only (A), option 1. The official key is 1.

**Concept mapping:**

- Newton's Third Law of Motion (`PHYS-MEC-NEWTON3`, primary, weight 1)
- Newton's Second Law of Motion (`PHYS-MEC-NEWTON2`, supporting, weight 0.3)

**Provenance:** `SL-DOE-AL-PHYS-2024-P1 Q4; AL_Physics_2024_Combined_Marking_Scheme_English.pdf p.5`. Reproduction status: `unapproved`. Import status: `ready_for_import`; approved by Malshani Perera for batch `T24-PHYS-PILOT-2026-11`.

**Coverage note:** Covers Newton's third law and distinguishes action-reaction pairs from balanced forces on one body.

### PILOT-PHYS-2024-P1-Q05

**Source:** `AL_Physics_2024_Combined_Paper_English.pdf` p.1, Q5 (2024). Marking scheme: `AL_Physics_2024_Combined_Marking_Scheme_English.pdf` p.5.

**Official key:** 5  
**Derived key:** 5  
**Sealed content hash:** `daddcd8e44eba36b773a1ec7002a7eb0e760cdca93e9088fe257398a297f880d`  
**Review:** `expert_review` / `self_review` by the named reviewer; academic status `approved`. See `content/physics/pilot/REVIEW_RECORD.md#independence-declaration`.

**Prompt:**

> A bullet hits a wooden block placed on a smooth horizontal surface and embeds within the block. Consider the following statements:
> (A) The law of conservation of linear momentum is valid for the collision.
> (B) The law of conservation of energy is valid for the collision.
> (C) A part of kinetic energy of the system is lost due to the collision.
> Of the above statements,

**Options:**

1. only (A) is true.
2. only (A) and (B) are true.
3. only (A) and (C) are true.
4. only (B) and (C) are true.
5. all (A), (B) and (C) are true. **(correct)**

**Explanation:** Horizontal momentum is conserved because no external horizontal force acts on the bullet-block system. Total energy is conserved, but mechanical energy is not: some initial kinetic energy is converted into internal energy, deformation and sound. Therefore A, B and C are all true.

**Derivation:** During the embedded collision the surface is smooth and horizontal, so the net external horizontal force is zero: p_initial = p_final (A true). Total energy conservation always applies; the missing mechanical energy appears as internal energy, deformation and sound (B true). A perfectly inelastic collision loses kinetic energy, so C is true. All three, option 5. The official key is 5.

**Concept mapping:**

- Linear Momentum (`PHYS-MEC-MOMENTUM`, primary, weight 1)
- Kinetic Energy (`PHYS-MEC-KINETIC-ENERGY`, supporting, weight 0.7)
- Principle of Conservation of Mechanical Energy (`PHYS-MEC-CONSERV-ENERGY`, supporting, weight 0.5)

**Provenance:** `SL-DOE-AL-PHYS-2024-P1 Q5; AL_Physics_2024_Combined_Marking_Scheme_English.pdf p.5`. Reproduction status: `unapproved`. Import status: `ready_for_import`; approved by Malshani Perera for batch `T24-PHYS-PILOT-2026-11`.

**Coverage note:** Covers momentum conservation and energy accounting in a perfectly inelastic collision.

**Ambiguity note:** Statement B refers to total energy, not conservation of mechanical energy. The explanation makes this distinction explicit; the official key confirms all three statements.

### PILOT-PHYS-2025-P1-Q01

**Source:** `AL_Physics_2025_Combined_Paper_English.pdf` p.1, Q1 (2025). Marking scheme: `AL_Physics_2025_Combined_Marking_Scheme_English.pdf` p.2.

**Official key:** 5  
**Derived key:** 5  
**Sealed content hash:** `f21d837f269c83ef067e465d6552f64479f4f12a16763184a065a6b17fb6cc90`  
**Review:** `expert_review` / `self_review` by the named reviewer; academic status `approved`. See `content/physics/pilot/REVIEW_RECORD.md#independence-declaration`.

**Prompt:**

> Which one below does not represent the unit of energy?

**Options:**

1. kg m² s⁻²
2. W s
3. kW h
4. V A s
5. C V s⁻¹ **(correct)**

**Explanation:** The joule is kg m² s⁻². A watt-second (W s) and a kilowatt-hour (kW h) are energy units; V A s = W s is also energy. C V s⁻¹ = (C V) s⁻¹ = J s⁻¹ = W, which is power, not energy.

**Derivation:** 1 J = 1 kg m^2 s^-2. W s = J. kW h = 3.6 x 10^6 J. V A = W, so V A s = J. C V = J, so C V s^-1 = J s^-1 = W. Therefore option 5 is a unit of power, not energy. The official key is 5.

**Concept mapping:**

- Work Done by a Force (`PHYS-MEC-WORK`, primary, weight 1)
- International System of Units (SI) (`PHYS-MEA-SI-UNITS`, supporting, weight 0.6)
- Kinetic Energy (`PHYS-MEC-KINETIC-ENERGY`, supporting, weight 0.4)

**Provenance:** `SL-DOE-AL-PHYS-2025-P1 Q1; AL_Physics_2025_Combined_Marking_Scheme_English.pdf p.2`. Reproduction status: `unapproved`. Import status: `ready_for_import`; approved by Malshani Perera for batch `T24-PHYS-PILOT-2026-11`.

**Coverage note:** Covers energy-unit equivalences and links work, SI units and kinetic energy.

### PILOT-PHYS-2025-P1-Q03

**Source:** `AL_Physics_2025_Combined_Paper_English.pdf` p.1, Q3 (2025). Marking scheme: `AL_Physics_2025_Combined_Marking_Scheme_English.pdf` p.2.

**Official key:** 1  
**Derived key:** 1  
**Sealed content hash:** `2c308ce5a9e6918fc8260e12350c3f2068aa9c7d32313eb791364161c8ea91c5`  
**Review:** `expert_review` / `self_review` by the named reviewer; academic status `approved`. See `content/physics/pilot/REVIEW_RECORD.md#independence-declaration`.

**Prompt:**

> A spring-mass system oscillates with period T. If the length of the spring is halved and the mass is reduced to half of its initial mass, what will be the new period?

**Options:**

1. T/2 **(correct)**
2. T/√2
3. T
4. √2 T
5. 2T

**Explanation:** For a spring of stiffness k, T = 2π√(m/k). Halving the natural length doubles the stiffness, and halving the mass gives T' = 2π√((m/2)/(2k)) = T/2.

**Derivation:** Let the original spring have natural length L, stiffness k and mass m: T = 2π√(m/k). A spring of the same material and coil geometry cut to L/2 has k' = 2k because stiffness is inversely proportional to natural length. With m' = m/2, T' = 2π√(m'/k') = 2π√((m/2)/(2k)) = 2π√(m/(4k)) = (1/2) 2π√(m/k) = T/2. Option 1. The official key is 1.

**Concept mapping:**

- Simple Harmonic Motion (`PHYS-WAV-SHM`, primary, weight 1)
- Acceleration (`PHYS-MEC-ACCELERATION`, supporting, weight 0.3)

**Provenance:** `SL-DOE-AL-PHYS-2025-P1 Q3; AL_Physics_2025_Combined_Marking_Scheme_English.pdf p.2`. Reproduction status: `unapproved`. Import status: `ready_for_import`; approved by Malshani Perera for batch `T24-PHYS-PILOT-2026-11`.

**Coverage note:** Covers the spring-mass period and its dependence on mass and stiffness.

**Ambiguity note:** The phrase 'length of the spring' could be read as the extension or amplitude rather than the natural length. The official key 1 selects the natural-length interpretation, under which halving the length doubles the stiffness. The verbatim prompt is retained and this residual wording risk is recorded rather than rewritten.

### PILOT-PHYS-2025-P1-Q45

**Source:** `AL_Physics_2025_Combined_Paper_English.pdf` p.8, Q45 (2025). Marking scheme: `AL_Physics_2025_Combined_Marking_Scheme_English.pdf` p.2.

**Official key:** 5  
**Derived key:** 5  
**Sealed content hash:** `6ba2ea48f2c41e3cf22fb6e46dda47aa19bd3ed2af37822d6c4ace55c49b2261`  
**Review:** `expert_review` / `self_review` by the named reviewer; academic status `approved`. See `content/physics/pilot/REVIEW_RECORD.md#independence-declaration`.

**Prompt:**

> A block of mass m moving with velocity v on a frictionless horizontal surface collides with a heavier block of mass 3m at rest on the surface. If the two blocks stick together after the collision, they move with velocity V₁. If instead the collision is perfectly elastic, the lighter block bounces back in the opposite direction and the heavier block moves with velocity V₂. What is the ratio of V₂/V₁?

**Options:**

1. 1/4
2. 1/2
3. 1
4. 3/2
5. 2 **(correct)**

**Explanation:** For the perfectly inelastic collision, V₁ = mv/(m+3m) = v/4. For the elastic collision, momentum and relative speed give V₂ = 2mv/(m+3m) = v/2. Therefore V₂/V₁ = (v/2)/(v/4) = 2.

**Derivation:** Inelastic: mv = 4m V1 -> V1 = v/4. Elastic: mv = m v1' + 3m V2 and the relative speed reverses, so v = V2 - v1'. Substitute v1' = V2 - v: m(V2 - v) + 3m V2 = mv -> 4V2 = 2v -> V2 = v/2. Ratio V2/V1 = (v/2)/(v/4) = 2. Option 5. The official key is 5.

**Concept mapping:**

- Linear Momentum (`PHYS-MEC-MOMENTUM`, primary, weight 1)
- Kinetic Energy (`PHYS-MEC-KINETIC-ENERGY`, supporting, weight 0.8)
- Principle of Conservation of Mechanical Energy (`PHYS-MEC-CONSERV-ENERGY`, supporting, weight 0.4)

**Provenance:** `SL-DOE-AL-PHYS-2025-P1 Q45; AL_Physics_2025_Combined_Marking_Scheme_English.pdf p.2`. Reproduction status: `unapproved`. Import status: `ready_for_import`; approved by Malshani Perera for batch `T24-PHYS-PILOT-2026-11`.

**Coverage note:** Covers one-dimensional collisions and compares perfectly inelastic and perfectly elastic outcomes.
