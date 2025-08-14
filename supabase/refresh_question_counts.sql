-- Refresh Question Counts
-- Run this SQL to update section and certification question counts

-- Update question counts for each section
UPDATE sections 
SET question_count = (
    SELECT COUNT(*) 
    FROM questions 
    WHERE questions.section_id = sections.id
)
WHERE certification_id = 'isc2-cc';

-- Update total questions for the certification
UPDATE certifications 
SET total_questions = (
    SELECT COUNT(*) 
    FROM questions 
    WHERE questions.certification_id = 'isc2-cc'
)
WHERE id = 'isc2-cc';

-- Verify the updates
SELECT 
    s.name as section_name,
    s.question_count,
    (SELECT COUNT(*) FROM questions WHERE section_id = s.id) as actual_count
FROM sections s 
WHERE s.certification_id = 'isc2-cc'
ORDER BY s.order_index;

-- Check certification total
SELECT 
    name,
    total_questions,
    (SELECT COUNT(*) FROM questions WHERE certification_id = 'isc2-cc') as actual_total
FROM certifications 
WHERE id = 'isc2-cc';