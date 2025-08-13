-- Cleanup script to run AFTER migration is complete
-- This removes the temporary migration policies

-- Remove temporary migration policies
DROP POLICY IF EXISTS "Allow authenticated users to insert questions during migration" ON questions;
DROP POLICY IF EXISTS "Allow authenticated users to insert answers during migration" ON answers;

-- If you disabled RLS completely, re-enable it:
-- ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE answers ENABLE ROW LEVEL SECURITY;

-- Verify the cleanup
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename IN ('questions', 'answers');