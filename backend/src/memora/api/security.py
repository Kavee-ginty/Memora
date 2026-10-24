from fastapi.security import HTTPBearer

bearer_auth = HTTPBearer(
    scheme_name="bearerAuth",
    description="Short-lived OIDC-issued access token.",
    auto_error=False,
)
