ALTER TABLE xp_ledger
ADD COLUMN policy_version text NOT NULL DEFAULT 'xp-v1';

ALTER TABLE streak_days
ADD COLUMN policy_version text NOT NULL DEFAULT 'streak-v1';

CREATE TABLE reward_placements (
  reward_grant_id uuid PRIMARY KEY REFERENCES reward_grants(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id),
  subject_id uuid REFERENCES subjects(id),
  placement_slot text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  row_version integer NOT NULL DEFAULT 1 CHECK (row_version > 0),
  CHECK ((subject_id IS NULL) = (placement_slot IS NULL)),
  UNIQUE(reward_grant_id, user_id)
);

ALTER TABLE reward_placements ENABLE ROW LEVEL SECURITY;
ALTER TABLE reward_placements FORCE ROW LEVEL SECURITY;
CREATE POLICY reward_placements_owner ON reward_placements
  USING (user_id = nullif(current_setting('memora.user_id', true), '')::uuid)
  WITH CHECK (user_id = nullif(current_setting('memora.user_id', true), '')::uuid);

GRANT SELECT, INSERT, UPDATE, DELETE ON reward_placements TO memora_api;
REVOKE ALL ON reward_placements FROM memora_worker;

CREATE INDEX ix_xp_ledger_balance ON xp_ledger(user_id, earned_at DESC, id DESC);
CREATE INDEX ix_streak_days_recent ON streak_days(user_id, local_date DESC);
CREATE INDEX ix_reward_grants_inventory ON reward_grants(user_id, granted_at DESC, id DESC);
CREATE INDEX ix_reef_projections_projected ON reef_projections(user_id, projected_at DESC);
