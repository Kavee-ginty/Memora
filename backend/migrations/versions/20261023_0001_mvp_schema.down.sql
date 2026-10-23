DO $$
DECLARE item record;
BEGIN
  FOR item IN
    SELECT tablename FROM pg_tables
    WHERE schemaname = 'public' AND tablename <> 'alembic_version'
  LOOP
    EXECUTE format('DROP TABLE public.%I CASCADE', item.tablename);
  END LOOP;
END $$;
DROP FUNCTION IF EXISTS memora_forbid_mutation();
DROP FUNCTION IF EXISTS memora_protect_published();
DROP FUNCTION IF EXISTS memora_reject_objective_cycle();
DROP FUNCTION IF EXISTS memora_prevent_upload_resurrection();
