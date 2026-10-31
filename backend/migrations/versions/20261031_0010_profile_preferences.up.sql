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

CREATE FUNCTION memora_transfer_device_token(p_fingerprint text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  current_user_id uuid := nullif(current_setting('memora.user_id', true), '')::uuid;
BEGIN
  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'memora.user_id is required';
  END IF;

  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(p_fingerprint, 0));

  UPDATE public.device_registrations
  SET push_token_ciphertext = NULL,
      token_fingerprint = NULL,
      revoked_at = COALESCE(revoked_at, pg_catalog.now()),
      updated_at = pg_catalog.now(),
      row_version = row_version + 1
  WHERE token_fingerprint = p_fingerprint;
END
$$;

REVOKE ALL ON FUNCTION memora_transfer_device_token(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION memora_transfer_device_token(text) TO memora_api;
