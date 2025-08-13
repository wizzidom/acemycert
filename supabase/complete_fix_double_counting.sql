-- Complete fix for double counting issue after migration
-- This script will clean up and recalculate all user statistics correctly

-- Step 1: Temporarily disable the trigger to prevent further double counting
DROP TRIGGER IF EXISTS update_stats_after_quiz_completion ON quiz_history;

-- Step 2: Check for and remove any duplicate quiz history entries
-- (This removes duplicates based on quiz_id and user_id, keeping the earliest entry)
DELETE FROM quiz_history 
WHERE id IN (
    SELECT id FROM (
        SELECT id, 
               ROW_NUMBER() OVER (
                   PARTITION BY quiz_id, user_id, certification_id, completed_at 
                   ORDER BY created_at
               ) as rn
        FROM quiz_history
    ) t 
    WHERE rn > 1
);

-- Step 3: Clear all existing calculated stats (we'll recalculate from scratch)
UPDATE user_profiles 
SET 
    total_quizzes_completed = 0,
    total_questions_answered = 0,
    updated_at = NOW();

-- Clear certification progress
DELETE FROM user_certification_progress;

-- Step 4: Recalculate all user statistics from quiz history
-- Update user profiles with correct totals
UPDATE user_profiles 
SET 
    total_quizzes_completed = COALESCE(stats.quiz_count, 0),
    total_questions_answered = COALESCE(stats.question_count, 0),
    last_activity_date = COALESCE(stats.last_activity, user_profiles.last_activity_date),
    updated_at = NOW()
FROM (
    SELECT 
        user_id,
        COUNT(*) as quiz_count,
        SUM(total_questions) as question_count,
        MAX(completed_at) as last_activity
    FROM quiz_history 
    GROUP BY user_id
) stats
WHERE user_profiles.id = stats.user_id;

-- Step 5: Recalculate certification progress
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
    user_id,
    certification_id,
    SUM(total_questions) as questions_answered,
    SUM(correct_answers) as correct_answers,
    COUNT(*) as quizzes_completed,
    AVG(score_percentage) as average_score,
    MAX(score_percentage) as best_score,
    MAX(completed_at) as last_attempt
FROM quiz_history 
GROUP BY user_id, certification_id;

-- Step 6: Create an improved trigger that won't cause double counting
CREATE OR REPLACE FUNCTION update_user_stats_after_quiz()
RETURNS TRIGGER AS $$
BEGIN
    -- Only update if this is a new quiz (not a migration)
    -- We can detect this by checking if the quiz was just created
    IF (NEW.created_at >= NEW.completed_at - INTERVAL '1 hour') THEN
        -- Update user profile stats
        UPDATE user_profiles 
        SET 
            total_quizzes_completed = total_quizzes_completed + 1,
            total_questions_answered = total_questions_answered + NEW.total_questions,
            last_activity_date = NEW.completed_at,
            updated_at = NOW()
        WHERE id = NEW.user_id;
        
        -- Update or insert certification progress
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
        VALUES (
            NEW.user_id,
            NEW.certification_id,
            NEW.total_questions,
            NEW.correct_answers,
            1,
            NEW.score_percentage,
            NEW.score_percentage,
            NEW.completed_at
        )
        ON CONFLICT (user_id, certification_id) 
        DO UPDATE SET
            questions_answered = user_certification_progress.questions_answered + NEW.total_questions,
            correct_answers = user_certification_progress.correct_answers + NEW.correct_answers,
            quizzes_completed = user_certification_progress.quizzes_completed + 1,
            average_score = (
                (user_certification_progress.average_score * user_certification_progress.quizzes_completed + NEW.score_percentage) 
                / (user_certification_progress.quizzes_completed + 1)
            ),
            best_score = GREATEST(user_certification_progress.best_score, NEW.score_percentage),
            last_attempt = NEW.completed_at,
            updated_at = NOW();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 7: Re-enable the improved trigger
CREATE TRIGGER update_stats_after_quiz_completion
    AFTER INSERT ON quiz_history
    FOR EACH ROW EXECUTE FUNCTION update_user_stats_after_quiz();

-- Step 8: Verification queries
-- Check final user stats
SELECT 
    name,
    total_quizzes_completed,
    total_questions_answered,
    last_activity_date
FROM user_profiles;

-- Check certification progress
SELECT 
    up.name,
    ucp.certification_id,
    ucp.quizzes_completed,
    ucp.questions_answered,
    ucp.average_score,
    ucp.best_score
FROM user_certification_progress ucp
JOIN user_profiles up ON ucp.user_id = up.id;

-- Check for any remaining duplicates
SELECT 
    quiz_id,
    user_id,
    COUNT(*) as count
FROM quiz_history 
GROUP BY quiz_id, user_id
HAVING COUNT(*) > 1;

-- Final summary
SELECT 
    'Total Users' as metric,
    COUNT(*) as value
FROM user_profiles
UNION ALL
SELECT 
    'Total Quiz History Entries' as metric,
    COUNT(*) as value
FROM quiz_history
UNION ALL
SELECT 
    'Total Questions in Database' as metric,
    COUNT(*) as value
FROM questions
WHERE certification_id = 'isc2-cc';