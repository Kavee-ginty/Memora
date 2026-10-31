from __future__ import annotations

WORKFLOW_VERSION = "v1"
RECONCILER_VERSION = "v1"
EXPORT_DOWNLOAD_TTL_SECONDS = 86400  # 24 hours

SCOPE_DATABASE = "database_learner_state"
SCOPE_UPLOADS = "temporary_uploads"
SCOPE_AUTH_PROVIDER = "auth_provider"

ALL_DELETION_SCOPES = (
    SCOPE_DATABASE,
    SCOPE_UPLOADS,
    SCOPE_AUTH_PROVIDER,
)

LEGAL_RETENTION_EXCEPTIONS = [
    "Security and consent audit records retained under tamper-resistant policy",
    "Immutable academic attempt and memory ledger history retained without learner identity",
]

ALLOWED_CANCELLATION_REASONS = {
    "user_requested",
    "accidental_request",
    "changed_mind",
    "retention_needed",
    "other",
}
