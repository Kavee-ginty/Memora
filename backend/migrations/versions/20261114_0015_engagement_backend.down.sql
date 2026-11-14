DROP INDEX IF EXISTS ix_reef_projections_projected;
DROP INDEX IF EXISTS ix_reward_grants_inventory;
DROP INDEX IF EXISTS ix_streak_days_recent;
DROP INDEX IF EXISTS ix_xp_ledger_balance;

DROP TABLE IF EXISTS reward_placements;

ALTER TABLE streak_days DROP COLUMN IF EXISTS policy_version;
ALTER TABLE xp_ledger DROP COLUMN IF EXISTS policy_version;
