REVOKE ALL ON FUNCTION memora_transfer_device_token(text) FROM memora_api;
DROP FUNCTION IF EXISTS memora_transfer_device_token(text);

ALTER TABLE user_profiles
  DROP CONSTRAINT IF EXISTS user_profiles_accessibility_schema_chk;

ALTER TABLE notification_preferences
  DROP CONSTRAINT IF EXISTS notification_preferences_daily_cap_chk,
  DROP CONSTRAINT IF EXISTS notification_preferences_preferred_window_pair_chk,
  DROP COLUMN IF EXISTS streak_enabled,
  DROP COLUMN IF EXISTS notifications_enabled;
