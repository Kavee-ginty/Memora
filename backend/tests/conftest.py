import os

from memora.core.config import Settings

# Test collection and app imports must not read a developer .env file or
# inherit deployment credentials from the process environment.
for variable in ("MEMORA_ENVIRONMENT", "MEMORA_DATABASE_URL", "MEMORA_LOG_LEVEL"):
    os.environ.pop(variable, None)

Settings.model_config["env_file"] = None
