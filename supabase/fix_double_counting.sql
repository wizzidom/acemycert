-- Fix double counting issue
-- Run this AFTER running the debug script to identify the problem

-- Option 1: If there are duplicate quiz history entries, remove them
-- (Uncomment and modify as needed based on debug results)
/*
DELETE FROM quiz_history 
WHERE id IN (
    SELECT id FROM (
        SELECT id, 
               ROW_NUMBER() OVER (PARTITION BY quiz_id, user_id ORDER BY created_at) as rn
        FROM quiz_history
    ) t 
    WHERE rn > 1
);
*/

-- Option 2: Recalculate user stats from scratch
-- This will fix any incorrect counts in user_profiles

-- First, let's create a function to recalculate stats
CREATE OR REPLACE FUNCTION recalculate_user_stats(target_user_id UUID)
RETURNS VOID AS $$
BEGIN
    -- Recalculate and update user profile stats
    UPDATE user_profiles 
    SET 
        total_quizzes_completed = (
            SELECT COUNT(*) FROM quiz_history WHERE user_id = target_user_id
        ),
        total_questions_answered = (
            SELECT COALESCE(SUM(total_questions), 0) FROM quiz_history WHERE user_id = target_user_id
        ),
        updated_at = NOW()
    WHERE id = target_user_id;
    
    -- Recalculate certification progress
    INSERT INTO user_certification_progress (
        user_id, 
        certification_id, 
        questions_answered, 
        correct_answers, 
        quizzes_completed,
        average_score,
        best_score,
        last_attempt
    )
    SELECT 
        target_user_id,
        certification_id,
        SUM(total_questions) as questions_answered,
        SUM(correct_answers) as correct_answers,
        COUNT(*) as quizzes_completed,
        AVG(score_percentage) as average_score,
        MAX(score_percentage) as best_score,
        MAX(completed_at) as last_attempt
    FROM quiz_history 
    WHERE user_id = target_user_id
    GROUP BY certification_id
    ON CONFLICT (user_id, certification_id) 
    DO UPDATE SET
        questions_answered = EXCLUDED.questions_answered,
        correct_answers = EXCLUDED.correct_answers,
        quizzes_completed = EXCLUDED.quizzes_completed,
        average_score = EXCLUDED.average_score,
        best_score = EXCLUDED.best_score,
        last_attempt = EXCLUDED.last_attempt,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- Run the recalculation for all users
-- (Replace with specific user ID if needed)
DO $$
DECLARE
    user_record RECORD;
BEGIN
    FOR user_record IN SELECT id FROM user_profiles LOOP
        PERFORM recalculate_user_stats(user_record.id);
    END LOOP;
END $$;