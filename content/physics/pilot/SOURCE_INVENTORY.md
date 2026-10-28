# T24 Physics Source Inventory

**Status:** Stage 1 planning evidence. This file is not an approval record and does not grant reproduction rights.

**Inspection date:** 2026-10-28

**Scope:** the 25 PDFs in `content/physics/source_documents/`.

## 1. Method

- File sizes and SHA-256 hashes were read with `Get-FileHash -Algorithm SHA256`.
- Page counts and first-four-page text extraction used `pypdf`.
- Language, year and document type were checked by rendering page 1 with `pypdfium2` and inspecting the image; filenames alone were not trusted.
- The selected candidate pages were rendered for prompt/option legibility. Verbatim comparisons are kept in the ignored local review pack, not in tracked content.
- OCR was not used as an authority. The 2022 and 2025 papers have no usable text layer, and the 2022 paper carries third-party scan annotations.
- No Git command was run. Tracked status was checked by reading the local `.git/index` file directly and by reading `.gitignore` and `.git/info/exclude`.
- The full machine-readable record, including every 64-character hash, is `source_manifest.json`.

## 2. Summary

| Measure | Value |
| --- | --- |
| Files | 25 |
| Total bytes | 349,201,060 |
| Total size | 333.02 MiB |
| Past papers | 8 |
| Marking schemes | 8 |
| Syllabus | 1 |
| Practical handbook | 1 |
| NIE resource books | 7 |
| English-medium documents | 24 |
| Tamil-medium documents | 1 |
| Exam years present | 2017, 2018, 2019, 2020, 2021, 2022, 2024, 2025 |
| Exam years absent | 2023 |

The 2021 paper is the only non-English document. Its filename ends in `_English`, but its cover and questions are Tamil. This is a filename-metadata mismatch, not a translation issue.

## 3. Past papers and marking schemes

`Text layer` describes the first four pages only. `none` means no usable extraction, `partial` means incidental or limited extraction, and `present` means a usable text layer was found in that sample.

| # | File | Year | Type | Language | Pages | Bytes | Text layer | Notes |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| 1 | `AL_Physics_2017_Combined_Marking_Scheme_English.pdf` | 2017 | Marking scheme | English | 45 | 10,072,298 | partial | Page 2 is a marks-distribution summary, not an MCQ key. |
| 2 | `AL_Physics_2017_Combined_Paper_English.pdf` | 2017 | Paper | English | 25 | 1,554,636 | none | Image scan. |
| 3 | `AL_Physics_2018_Combined_Marking_Scheme_English.pdf` | 2018 | Marking scheme | English | 51 | 5,066,264 | none | Page 2 is blank in the scanned copy; no MCQ key. |
| 4 | `AL_Physics_2018_Combined_Paper_English.pdf` | 2018 | Paper | English | 27 | 1,700,493 | none | Image scan. |
| 5 | `AL_Physics_2019_Combined_Marking_Scheme_English.pdf` | 2019 | Marking scheme | English | 69 | 4,654,653 | none | Page 2 is blank in the scanned copy; no MCQ key. |
| 6 | `AL_Physics_2019_Combined_Paper_English.pdf` | 2019 | Paper | English | 29 | 2,051,306 | none | 12 incidental characters; no usable text layer. |
| 7 | `AL_Physics_2020_Combined_Marking_Scheme_English.pdf` | 2020 | Marking scheme | English | 62 | 5,825,186 | none | Page 2 is a marks-distribution summary, not an MCQ key. |
| 8 | `AL_Physics_2020_Combined_Paper_English.pdf` | 2020 | Paper | English | 13 | 3,578,965 | none | Page count is lower than the other combined papers; completeness is unverified. |
| 9 | `AL_Physics_2021_Combined_Marking_Scheme_English.pdf` | 2021 | Marking scheme | English | 59 | 4,299,004 | present | Page 2 is a marks-distribution summary, not an MCQ key. |
| 10 | `AL_Physics_2021_Combined_Paper_English.pdf` | 2021(2022) | Paper | **Tamil** | 28 | 1,387,450 | partial | **Filename says English; content is Tamil.** No English 2021 paper is present. Printed cover label is `2021(2022)`. |
| 11 | `AL_Physics_2022_Combined_Marking_Scheme_English.pdf` | 2022(2023) | Marking scheme | English | 39 | 30,958,716 | none | Page 2 is a question-to-marks table, not an MCQ key. Handwritten marks were not treated as a key. |
| 12 | `AL_Physics_2022_Combined_Paper_English.pdf` | 2022(2023) | Paper | English | 19 | 8,212,537 | none | Annotated CamScanner scan. Handwritten ticks/marks are not an official key. |
| 13 | `AL_Physics_2024_Combined_Marking_Scheme_English.pdf` | 2024 | Marking scheme | English | 48 | 5,308,110 | none | Page 2 is a marks-distribution summary, not an MCQ key. |
| 14 | `AL_Physics_2024_Combined_Paper_English.pdf` | 2024 | Paper | English | 27 | 2,123,887 | none | Image scan. |
| 15 | `AL_Physics_2025_Combined_Marking_Scheme_English.pdf` | 2025 | Marking scheme | English | 40 | 8,555,105 | none | Page 2 is a question-to-marks table, not an MCQ key. |
| 16 | `AL_Physics_2025_Combined_Paper_English.pdf` | 2025 | Paper | English | 17 | 9,600,159 | none | Image scan; Paper I is 50 questions over 10 pages. Rendered page 2 carries a `Past Papers Wiki` watermark. |

### 3.1 Year-label anomaly

The 2021 paper cover reads `2021(2022)`. The 2022 paper cover reads `2022(2023)`. This inventory uses the first year as `exam_year` and preserves the printed label in `exam_label`.

### 3.2 Marking-scheme limitation

Page 2 of every marking scheme was rendered and inspected. The structure is not uniform across years:

| Year | Page-2 structure |
| --- | --- |
| 2017 | Marks-distribution summary, not an MCQ key. |
| 2018 | Blank in the scanned copy. |
| 2019 | Blank in the scanned copy. |
| 2020 | Marks-distribution summary, not an MCQ key. |
| 2021 | Marks-distribution summary, not an MCQ key. |
| 2022 | Paper I question-to-marks allocation table, not an MCQ key. |
| 2024 | Marks-distribution summary, not an MCQ key. |
| 2025 | Paper I question-to-marks allocation table, not an MCQ key. |

None of the inspected page-2 layouts is a 1-to-5 MCQ answer grid. **No official MCQ answer key was found in any marking scheme.** Do not generalize the 2022/2025 layout to other years, and do not describe a derived answer as an official key.

### 3.3 Scan-quality limitation

- The 2022 paper is a CamScanner scan with handwritten annotations and ticks.
- The 2025 paper is an image scan with no text layer; rendered page 2 carries a `Past Papers Wiki` watermark. The watermark provenance is unknown and is recorded in `source_manifest.json`.
- OCR on either paper would be a derived transcription, not an authoritative source. Any OCR output must be compared with the page image by a reviewer before use.

## 4. Reference documents and resource books

| # | File | Year / edition | Type | Language | Pages | Bytes | Text layer | Notes |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| 17 | `AL_Physics_Syllabus_2017.pdf` | Implemented from 2017 | Syllabus | English | 72 | 587,437 | present | NIE G.C.E. A/L Physics syllabus. |
| 18 | `Physics_Practical_Handbook.pdf` | Effective from 2017 | Practical handbook | English | 113 | 4,101,088 | present | English practical handbook. |
| 19 | `Physics_Unit_01-02.pdf` | © 2020 NIE | Resource book | English | 125 | 44,395,209 | none | Units 1-2. Image scan. |
| 20 | `Physics_Unit_03.pdf` | © 2020 NIE | Resource book | English | 113 | 28,971,920 | present | Unit 3. |
| 21 | `Physics_Unit_04.pdf` | © 2020 NIE | Resource book | English | 92 | 19,344,713 | none | Unit 4. Image scan. |
| 22 | `Physics_Unit_05-08.pdf` | © 2020 NIE | Resource book | English | 132 | 30,186,008 | none | Units 5-8. Image scan. |
| 23 | `Physics_Unit_09.pdf` | © 2020 NIE | Resource book | English | 158 | 57,561,237 | none | Unit 9. Image scan. |
| 24 | `Physics_Unit_10.pdf` | © 2020 NIE | Resource book | English | 53 | 17,855,951 | none | Unit 10. Image scan. |
| 25 | `Physics_Unit_11.pdf` | © 2020 NIE | Resource book | English | 99 | 41,248,728 | none | Unit 11. Image scan. |

The resource-book covers show NIE copyright 2020. The inventory does not claim an edition number or print run because that metadata was not verified.

## 5. Full SHA-256 manifest

The same values are stored in `source_manifest.json`.

```text
cea3078947472c47594fc44a905e55cd9a40ff61150daedbd176780c766d2245  AL_Physics_2017_Combined_Marking_Scheme_English.pdf
1aa7e412b8257741e1cb57bbf4ac15d7da3821ede6e42a789595d62158944011  AL_Physics_2017_Combined_Paper_English.pdf
d0f374fb538c904cc2715b45a61afa2110cd59bb92f1cca1ab9df31a181e89da  AL_Physics_2018_Combined_Marking_Scheme_English.pdf
e4707b42dc5b94a0429a546ec529a8f14c773c0daeb8d847e7a4e2edf6d57342  AL_Physics_2018_Combined_Paper_English.pdf
c1e31b80d6b8f68e8b554af2129e89c36fba0e55c7eb7ac3ddfa808b5675a774  AL_Physics_2019_Combined_Marking_Scheme_English.pdf
f28c874c9972db431789425fe1705776d33e22bc2582a694cf77c20dc55ddca4  AL_Physics_2019_Combined_Paper_English.pdf
bf1d0a7bec1c3fc0ed182cf18134c01bbaf1df07ee7783bd4bf58ecd378bc038  AL_Physics_2020_Combined_Marking_Scheme_English.pdf
d97672ee7e7a29dbfb728cb61aa4ca3036c7facfa83c3eea90400c6ddd9447d8  AL_Physics_2020_Combined_Paper_English.pdf
eaf5741c90ac04d39a4c867c8ed7bb56db12778398f154a85aa8ee6473291db3  AL_Physics_2021_Combined_Marking_Scheme_English.pdf
fe2203071eec6f6927523e1b16f5b392037bdab7f84850040e732bc63ff8f430  AL_Physics_2021_Combined_Paper_English.pdf
52b42bcdf22ce9f6cc8c071d0cd6ba3c6f9082183d455d4fe43ef29143ee2ca7  AL_Physics_2022_Combined_Marking_Scheme_English.pdf
931347c30d9c96068ae3df9e6d0db62f05c903f1a2abdb268a9a0e6bdb9956dc  AL_Physics_2022_Combined_Paper_English.pdf
2e77a2fd58a9213ea0cf025a11a72babedef363b66126c9d7830c8dcec9394b2  AL_Physics_2024_Combined_Marking_Scheme_English.pdf
1d628ae65f32d97ce495a244176a7aa2db31e2b1a57f698a6fe3b028772c18c2  AL_Physics_2024_Combined_Paper_English.pdf
39d58f8f5a272614b984f78156663e0fe1bb9afc0461013989e7e50df18fceb3  AL_Physics_2025_Combined_Marking_Scheme_English.pdf
6572aead08a0cc5fd9feed0db0a3e56fc2c125fca8fccb7e178a2c59729bae49  AL_Physics_2025_Combined_Paper_English.pdf
a9e1db067f9998a182d9a915434a0b9c557f9413c7c1ecc5fc980710cf19fdb9  AL_Physics_Syllabus_2017.pdf
6dbe4a6471645f1fd29a4cb4ff807d227cff90f479d850a96dabd1c350a53e5b  Physics_Practical_Handbook.pdf
fb5c0d45b9df04ffed852bb02796c093d80bbbfcd958c04acc704cab3c4c10d3  Physics_Unit_01-02.pdf
e8062d45819be02c4a1c520d7b5897d0e593fa954864adb63b9ccd51740e5ee1  Physics_Unit_03.pdf
b7c481e4762e10f0d784ea103f54f9eada164becbdb436e760de8ea14d169a23  Physics_Unit_04.pdf
52f712ac3bba5b09d61bc9f6f568868fe331dee1cdc5b7c32f91521318b6a324  Physics_Unit_05-08.pdf
f75fcbcd5a1cc530cba836baac79b4a0e070dfd3de1343a36cf6e179fef408b3  Physics_Unit_09.pdf
6f1c15de2824a3b3f984726e8acfb21c26dd7739497c0dd8b4781ef4b1351dab  Physics_Unit_10.pdf
597c90ecff7012bac0fd40ac1fd5e8274c7ed065423b3ae829f5da5d9d590ffa  Physics_Unit_11.pdf
```

## 6. Metadata unknowns

The following are not established by the documents inspected:

1. Licence, copyright status and permission to reproduce, adapt or redistribute any paper, marking scheme, syllabus or resource book.
2. ISBN, ISSN, print run, publisher address and exact publication date.
3. Author, editor and contributor names.
4. Whether each combined paper PDF contains every page of both Paper I and Paper II. The 2020 paper is only 13 pages, which is materially shorter than the other combined papers.
5. The location of an official MCQ answer key. None was found.
6. Scanner, OCR and annotation provenance, especially for the 2022 CamScanner file.
7. Whether an English-medium 2021 paper exists outside this inventory.
8. The exact edition of the seven NIE resource books beyond the visible © 2020 notice.

## 7. Repository handling and ignore rules

### 7.1 Tracked and ignored status

- Root `.gitignore` now contains the T24 source-PDF rule `/content/physics/source_documents/` in the working tree.
- Root `.gitignore` also contains the local review-pack rule `/content/physics/pilot/local_review/`.
- `.git/info/exclude` contains only comments and the default template.
- No nested `.gitignore` exists under `content/physics/`.
- The local `.git/index` was inspected read-only during Stage 1. It contained zero occurrences of `source_documents` and zero occurrences of `.pdf` at that time.

**Conclusion:** the 25 PDFs are not tracked, and the working-tree ignore rule prevents a broad `git add` from staging them. The local verbatim review pack is also ignored. This describes the working tree; it is not a substitute for `git status` or a remote check.

### 7.2 Rule scope

The source-document rule ignores the whole directory, including future non-PDF extracts. If later work needs tracked extracted text inside that directory, narrow the rule to `/content/physics/source_documents/**/*.pdf` or move the tracked artifacts to `content/physics/pilot/`.

The local review pack is deliberately not a tracked artifact. Verbatim prompts and options stay there until a real reproduction approval exists.

## 8. Candidate-page verification

The eight candidate questions were visually checked against these page images:

| Candidate | Paper | PDF page | Page-image observation |
| --- | --- | --- | --- |
| 2025 Q1, Q2, Q5 | 2025 Paper I | 1 | Question text and five options legible. |
| 2025 Q12, Q14 | 2025 Paper I | 2 | Question text and five options legible. |
| 2025 Q45 | 2025 Paper I | 8 | Question text and five options legible. |
| 2022 Q1 | 2022 Paper I | 1 | Question text and five options legible. |
| 2022 Q17 | 2022 Paper I | 3 | Question text and five options legible. |

These page references are to the PDF, not to a printed page number. `PILOT_QUESTIONS.md` contains the source references and non-verbatim candidate notes; the local ignored review pack contains the verbatim comparisons for reviewer use.
