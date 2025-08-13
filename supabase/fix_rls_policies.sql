-- Fix RLS policies to allow question insertion during migration
-- Run this in your Supabase SQL Editor

-- Temporarily allow authenticated users to insert questions (for migration)
CREATE POLICY "Allow authenticated users to insert questions during migration" ON questions
    FOR INSERT TO authenticated
    WITH CHECK (true);

-- Temporarily allow authenticated users to insert answers (for migration)  
CREATE POLICY "Allow authenticated users to insert answers during migration" ON answers
    FOR INSERT TO authenticated
    WITH CHECK (true);

-- Alternative: If you want to completely disable RLS for questions and answers (simpler approach)
-- Uncomment the lines below if you prefer this approach:

-- ALTER TABLE questions DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE answers DISABLE ROW LEVEL SECURITY;

-- Note: After migration is complete, you can remove these policies or re-enable RLS
-- by running the cleanup script