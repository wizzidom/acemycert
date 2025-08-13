-- Debug script to check for double counting issues
-- Run this in Supabase SQL Editor to investigate

-- Check for duplicate quiz history entries
SELECT 
    quiz_id,
    user_id,
    certification_id,
    completed_at,
    COUNT(*) as duplicate_count
FROM quiz_history 
GROUP BY quiz_id, user_id, certification_id, completed_at
HAVING COUNT(*) > 1
ORDER BY completed_at DESC;

-- Check recent quiz history entries
SELECT 
    quiz_id,
    user_id,
    certification_name,
    total_questions,
    score_percentage,
    completed_at,
    created_at
FROM quiz_history 
ORDER BY created_at DESC 
LIMIT 10;

-- Check user profile stats
SELECT 
    id,
    name,
    total_quizzes_completed,
    total_questions_answered,
    last_activity_date
FROM user_profiles;

-- Check certification progress
SELECT 
    user_id,
    certification_id,
    questions_answered,
    quizzes_completed,
    average_score,
    last_attempt
FROM user_certification_progress;

-- Check if trigger is firing multiple times
-- Look for any duplicate triggers on quiz_history table
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'quiz_history';