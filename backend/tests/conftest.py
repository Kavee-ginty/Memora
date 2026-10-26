import os

from memora.core.config import Settings

# Test collection and app imports must not read a developer .env file or
# inherit deployment credentials from the process environment.
for variable in (
    "MEMORA_ENVIRONMENT",
    "MEMORA_DATABASE_URL",
    "MEMORA_LOG_LEVEL",
    "MEMORA_SUPABASE_URL",
    "MEMORA_SUPABASE_PUBLISHABLE_KEY",
    "MEMORA_DEVICE_ENCRYPTION_KEY",
    "MEMORA_DEVICE_FINGERPRINT_KEY",
    "MEMORA_CONSENT_TERMS_VERSION",
    "MEMORA_CONSENT_PRIVACY_VERSION",
    "MEMORA_CONSENT_MATERIAL_PROCESSING_VERSION",
    "MEMORA_CONSENT_MODEL_PROCESSING_VERSION",
    "MEMORA_CONSENT_NOTIFICATIONS_VERSION",
):
    os.environ.pop(variable, None)

Settings.model_config["env_file"] = None
