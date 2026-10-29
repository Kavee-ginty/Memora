ALTER TABLE notification_preferences
  ADD COLUMN notifications_enabled boolean NOT NULL DEFAULT false,
  ADD COLUMN streak_enabled boolean NOT NULL DEFAULT true,
  ADD CONSTRAINT notification_preferences_preferred_window_pair_chk
    CHECK ((preferred_window_start_local IS NULL) = (preferred_window_end_local IS NULL)),
  ADD CONSTRAINT notification_preferences_daily_cap_chk
    CHECK (max_daily_reminders <= 3);

ALTER TABLE user_profiles
  ADD CONSTRAINT user_profiles_accessibility_schema_chk
    CHECK (accessibility_preferences ->> 'schema_version' = '1');
