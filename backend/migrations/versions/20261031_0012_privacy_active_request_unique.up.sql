CREATE UNIQUE INDEX IF NOT EXISTS ix_privacy_requests_active_user_type
  ON privacy_requests (user_id, request_type)
  WHERE status IN ('requested', 'verifying', 'processing');
