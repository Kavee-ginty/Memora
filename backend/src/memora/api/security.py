from fastapi.security import HTTPBearer

# OpenAPI credential and security-schema primitive.
# auto_error=False ensures FastAPI does not intercept unauthenticated requests with
# its default 403. T06 must provide the enforcing request-context dependency that
# validates OIDC access tokens and emits safe, shared 401 ErrorEnvelope responses.
bearer_auth = HTTPBearer(
    scheme_name="bearerAuth",
    description="Short-lived OIDC-issued access token.",
    auto_error=False,
)
