# T24 source inventory

## Scope

This inventory covers only the local source documents used to build the T24
Physics Paper I pilot. The PDFs live under `content/physics/source_documents/`,
which is gitignored. The hashes below identify the exact local copies used for
transcription and answer verification; they do not prove official publication,
completeness or reproduction permission.

All question text and answer keys were checked against the rendered PDF page,
not against OCR alone. The marking-scheme grids are printed in Sinhala, Tamil
and English headings but use numerals, so the answer cells were read directly
from the page image.

## Selected source files

| Document | Type | Year | Pages | Bytes | SHA-256 |
| --- | --- | --- | ---: | ---: | --- |
| `AL_Physics_Syllabus_2017.pdf` | Syllabus | 2017 | 72 | 587,437 | `a9e1db067f9998a182d9a915434a0b9c557f9413c7c1ecc5fc980710cf19fdb9` |
| `AL_Physics_2022_Combined_Paper_English.pdf` | Past paper | 2022(2023) | 19 | 8,212,537 | `931347c30d9c96068ae3df9e6d0db62f05c903f1a2abdb268a9a0e6bdb9956dc` |
| `AL_Physics_2022_Combined_Marking_Scheme_English.pdf` | Marking scheme | 2022(2023) | 39 | 30,958,716 | `52b42bcdf22ce9f6cc8c071d0cd6ba3c6f9082183d455d4fe43ef29143ee2ca7` |
| `AL_Physics_2024_Combined_Paper_English.pdf` | Past paper | 2024 | 27 | 2,123,887 | `1d628ae65f32d97ce495a244176a7aa2db31e2b1a57f698a6fe3b028772c18c2` |
| `AL_Physics_2024_Combined_Marking_Scheme_English.pdf` | Marking scheme | 2024 | 48 | 5,308,110 | `2e77a2fd58a9213ea0cf025a11a72babedef363b66126c9d7830c8dcec9394b2` |
| `AL_Physics_2025_Combined_Paper_English.pdf` | Past paper | 2025 | 17 | 9,600,159 | `6572aead08a0cc5fd9feed0db0a3e56fc2c125fca8fccb7e178a2c59729bae49` |
| `AL_Physics_2025_Combined_Marking_Scheme_English.pdf` | Marking scheme | 2025 | 40 | 8,555,105 | `39d58f8f5a272614b984f78156663e0fe1bb9afc0461013989e7e50df18fceb3` |

The machine-readable copy of this table, the selected-question index and the
selected answer keys is in `source_manifest.json`. The complete 50-entry answer
grids are in `official_answer_keys.json`.

## Official MCQ answer grids

| Year | Marking-scheme PDF page | Grid evidence | Pilot use |
| --- | ---: | --- | --- |
| 2022(2023) | 2 | 50 entries; five question/answer column pairs; footer reads `01 - Physics (Marking Scheme) G.C.E. (A/L) Examination 2022 (2023)` | Q1 = 4, Q17 = 4 |
| 2024 | 5 | 50 entries; five question/answer column pairs; footer reads `01 - Physics (Marking Scheme) G.C.E. (A/L) Examination - 2024` | Q1 = 5, Q4 = 1, Q5 = 5 |
| 2025 | 2 | 50 entries; five question/answer column pairs; question 15 is printed `02/04` | Q1 = 5, Q3 = 1, Q45 = 5 |

The 2025 question 15 cell is genuinely ambiguous in the published grid. It is
excluded from the pilot. The rest of the 2025 grid is unambiguous.

## Selected questions

| Pilot ID | Year | Question | Paper page | Marking-scheme page | Official key |
| --- | ---: | ---: | ---: | ---: | ---: |
| `PILOT-PHYS-2022-P1-Q01` | 2022 | 1 | 1 | 2 | 4 |
| `PILOT-PHYS-2022-P1-Q17` | 2022 | 17 | 3 | 2 | 4 |
| `PILOT-PHYS-2024-P1-Q01` | 2024 | 1 | 1 | 5 | 5 |
| `PILOT-PHYS-2024-P1-Q04` | 2024 | 4 | 1 | 5 | 1 |
| `PILOT-PHYS-2024-P1-Q05` | 2024 | 5 | 1 | 5 | 5 |
| `PILOT-PHYS-2025-P1-Q01` | 2025 | 1 | 1 | 2 | 5 |
| `PILOT-PHYS-2025-P1-Q03` | 2025 | 3 | 1 | 2 | 1 |
| `PILOT-PHYS-2025-P1-Q45` | 2025 | 45 | 8 | 2 | 5 |

The selected questions are text-only or can be made text-only without changing
the physics. `PILOT-PHYS-2024-P1-Q05` originally refers to a figure; the pilot
prompt states the same physical setup in words and records
`text_only_adaptation = true`. No diagram, table or graph is required by the
selected set.

## Why these years

- 2022, 2024 and 2025 are the only local Paper I pairs with a confirmed,
  readable official MCQ answer grid.
- They cover the T08 concepts used by the pilot: measurement units and
  dimensions, Newton's laws, momentum, energy, and simple harmonic motion.
- Every selected answer was both derived and matched to the printed official
  grid. The grid is the answer-key authority. The named teacher's self-review of
  transcription, derivation, explanation, mapping, ambiguity and adaptation is
  recorded in `REVIEW_RECORD.md`.
- 2021 was excluded because the local paper copy is Tamil-medium despite the
  `_English` filename and no English paper or usable MCQ grid was confirmed.
- 2023 is not present in the local inventory.
- Questions 2025 Q15 and any other grid cell with more than one printed answer
  are excluded.

## Verification method

1. Compute SHA-256 and page count for every selected file.
2. Render the marking-scheme page containing the MCQ grid and read the grid
   visually. Do not infer keys from ticks or handwriting on the question paper.
3. Render the question page and transcribe the prompt and all five options.
4. Derive the answer from physics independently.
5. Compare the derived option with the official grid. If they differ, do not
   publish the item; record the conflict.
6. Record the content hash of the sealed envelope.

## Limitations and risks

- Reproduction permission for the past-paper excerpts is not recorded. The
  envelopes use `reproduction_status = "unapproved"`. The pilot import approval
  permits internal use only; it does not grant redistribution rights. The
  excerpts are retained only for this internal pilot.
- The reviewer qualification reference `PostGraduate` is self-declared and lacks
  a degree title, awarding institution, year and subject specialisation. No
  certificate was independently verified in this task.
- The review is a self-review: the named author and reviewer are the same person.
  No independent second-person review is claimed.
- The 2022 paper is an annotated CamScanner scan. Handwritten ticks and notes
  are not evidence and were ignored.
- OCR of the marking-scheme grids is unreliable because the headings are
  multilingual. The grid images, not OCR text, are the source of record.
- The 2025 Q3 wording is ambiguous if "length of the spring" is read as the
  extension rather than the natural length. The official key selects the
  natural-length interpretation (`T/2`); the envelope records this in
  `review.ambiguity_note`.
- The source PDFs are not committed. CI can verify file identity only when the
  local PDFs are present.
