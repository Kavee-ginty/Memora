# T24 Verified Physics Pilot Content — Study Note

## 1. The Core Analogy: The "Diplomatic Envelope"

Think of introducing an exam question into Memora like processing a **passport through immigration control**:

- **The Question itself** is the traveler.
- **The T24 Review Envelope** is a secure, sealed diplomatic pouch carrying the traveler along with affidavits: author credentials, an independent reviewer's signature, verified calculation worksheets, and a copyright visa.
- **The Database (T12 Question Bank)** is the permanent registry of citizens.
- **The Golden Rule:** The border control guards (our automated JSON Schema and Python validators) inspect the envelope. If any stamp is missing, expired, or self-signed, the traveler stays locked in draft quarantine. Only once every verification is genuine is the envelope unsealed, the temporary review paperwork discarded, and the clean question admitted into the database.

---

## 2. Key Concepts Learned

### A. The Draft vs. Approved Boundary
A question in "draft" cannot masquerade as "expert verified".
- **Draft State:** `source_class = null`, `target_source_class = "expert_verified"`, `publication.approved_for_import = false`. Drafts cannot carry a reviewer ID or approval date before the review actually happens.
- **Approved State:** Requires real author and reviewer UUIDs, separate qualification references, verified answer derivation, and an approved rubric.

### B. Reviewer Independence
- **Rule:** A person cannot grade their own homework.
- **Implementation:** `author_principal != reviewer_principal`. If the author UUID equals the reviewer UUID, validation raises `pilot_reviewer_independence`.

### C. Cryptographic Content Hashing (SHA-256)
- **Concept:** How do we prove that a reviewer approved the *exact* wording currently in the system?
- **Implementation:** The prompt, options, explanation, and rubric are serialized and hashed with SHA-256 (e.g. `e3b0c442...`). If anyone changes even a single comma afterwards, the hash changes, mismatches `review.content_hash`, and blocks publication.

### D. Honest Curriculum Mapping vs. Invented Knowledge
- **Rule:** A question must link to an official curriculum concept (`concept_version_id`).
- **Lesson:** If a topic (like *projectile motion* or *static friction*) does not yet exist in the T08 knowledge graph, **never invent fake IDs or force an unnatural mapping**. Keep it explicitly marked as an unresolved gap with the exact missing topic documented.

### E. Copyright & Provenance Hygiene
- Past-paper scans (PDFs) and verbatim OCR text carry legal restrictions.
- They are kept in local-only folders excluded by `.gitignore` (`/content/physics/source_documents/` and `local_review/`) so they never accidentally leak into public Git history or production databases.

---

## 3. Technologies & Methods in Simple Terms

| Technology / Tool | What It Does | Simple Example in T24 |
|---|---|---|
| **JSON Schema (Draft 2020-12)** | A blueprint validator that checks data structure before code runs. | Ensures `question_type` is always `"mcq"`, and that an approved question has at least 1 primary concept mapping using conditional `if-then-else`. |
| **Pydantic (Python)** | Turns raw JSON into strongly-typed Python objects and catches invalid data at runtime. | `QuestionImportBundle.model_validate(question)` enforces strict field limits (e.g., forbidding extra fields with `extra="forbid"`). |
| **Negative Testing (Pytest)** | Writing tests designed specifically to ensure bad inputs fail for the right reasons. | Deliberately submitting `official_key_claimed = True` or mismatched option keys to verify that the gates reject them with exact error codes. |
| **Disposable Databases (PostgreSQL + Docker)** | Spinning up isolated, temporary test databases (`_test`) to verify migrations and security policies. | Running migrations, RLS (Row Level Security), and immutability tests on `memora_t24_test`, then dropping it cleanly without risking shared data. |

---

## 4. Summary Takeaway

> **"Never let missing evidence become silent approval."**  
> Software cannot create legal permissions or academic credentials out of thin air. The system's job is to build ironclad gates so that good content enters safely, and unverified content is impossible to publish accidentally.
