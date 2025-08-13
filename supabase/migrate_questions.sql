-- Migration script to populate ISC² CC questions from JSON data
-- This script should be run after the schema and seed data are in place

-- =============================================
-- ISC² CC DOMAIN 1 - SECURITY PRINCIPLES
-- =============================================

-- Note: You'll need to replace this with actual data from your JSON files
-- This is the structure for how the questions should be inserted

-- Example of how to insert questions (you'll need to adapt this for your actual JSON data):

/*
SELECT insert_question_with_answers(
    'isc2-cc',
    'security-principles',
    'Your question text here',
    'Your explanation here',
    '[
        {"text": "Answer option 1", "isCorrect": false},
        {"text": "Answer option 2", "isCorrect": true},
        {"text": "Answer option 3", "isCorrect": false},
        {"text": "Answer option 4", "isCorrect": false}
    ]'::JSONB
);
*/

-- =============================================
-- BATCH INSERT TEMPLATE
-- =============================================

-- Template for batch inserting questions from JSON structure
-- You can use this pattern to convert your JSON files

CREATE OR REPLACE FUNCTION migrate_domain_questions(
    domain_id TEXT,
    questions_json JSONB
)
RETURNS INTEGER AS $$
DECLARE
    question_item JSONB;
    question_count INTEGER := 0;
    answers_array JSONB;
BEGIN
    -- Loop through each question in the JSON
    FOR question_item IN SELECT * FROM jsonb_array_elements(questions_json)
    LOOP
        -- Convert answers to the expected format
        SELECT jsonb_agg(
            jsonb_build_object(
                'text', answer_item->>'text',
                'isCorrect', (answer_item->>'isCorrect')::BOOLEAN
            )
        ) INTO answers_array
        FROM jsonb_array_elements(question_item->'answers') AS answer_item;
        
        -- Insert the question with answers
        PERFORM insert_question_with_answers(
            'isc2-cc',
            domain_id,
            question_item->>'text',
            question_item->>'explanation',
            answers_array
        );
        
        question_count := question_count + 1;
    END LOOP;
    
    RETURN question_count;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- MANUAL QUESTION INSERTION
-- =============================================

-- Since we can't directly read JSON files in SQL, you'll need to:
-- 1. Convert your JSON files to SQL INSERT statements, or
-- 2. Use the Flutter migration script I'll create next, or
-- 3. Manually copy-paste the questions here

-- Example structure for Domain 1 questions:
-- (Replace with actual questions from your Domain 1 JSON file)

/*
-- Sample questions from Domain 1 - Security Principles
SELECT insert_question_with_answers(
    'isc2-cc',
    'security-principles',
    'What does the principle of least privilege mean?',
    'The principle of least privilege means that users should be given the minimum levels of access necessary to perform their job functions.',
    '[
        {"text": "Users should have access to all systems for convenience", "isCorrect": false},
        {"text": "Users should be given minimum access necessary for their job", "isCorrect": true},
        {"text": "Only administrators should have system access", "isCorrect": false},
        {"text": "All users should have the same level of access", "isCorrect": false}
    ]'::JSONB
);

SELECT insert_question_with_answers(
    'isc2-cc',
    'security-principles',
    'Which of the following is NOT part of the CIA triad?',
    'The CIA triad consists of Confidentiality, Integrity, and Availability. Non-repudiation is a separate security principle.',
    '[
        {"text": "Confidentiality", "isCorrect": false},
        {"text": "Integrity", "isCorrect": false},
        {"text": "Availability", "isCorrect": false},
        {"text": "Non-repudiation", "isCorrect": true}
    ]'::JSONB
);
*/

-- =============================================
-- VERIFICATION QUERIES
-- =============================================

-- Check question counts per domain
SELECT 
    s.name as section_name,
    COUNT(q.id) as question_count
FROM sections s
LEFT JOIN questions q ON s.id = q.section_id
WHERE s.certification_id = 'isc2-cc'
GROUP BY s.id, s.name
ORDER BY s.order_index;

-- Check total questions for ISC² CC
SELECT COUNT(*) as total_isc2_questions 
FROM questions 
WHERE certification_id = 'isc2-cc';

-- Check answers per question (should be 4 for most questions)
SELECT 
    q.text as question_text,
    COUNT(a.id) as answer_count,
    SUM(CASE WHEN a.is_correct THEN 1 ELSE 0 END) as correct_answers
FROM questions q
LEFT JOIN answers a ON q.id = a.question_id
WHERE q.certification_id = 'isc2-cc'
GROUP BY q.id, q.text
HAVING COUNT(a.id) != 4 OR SUM(CASE WHEN a.is_correct THEN 1 ELSE 0 END) != 1;

-- =============================================
-- CLEANUP FUNCTIONS
-- =============================================

-- Function to clear all questions for a certification (use with caution!)
CREATE OR REPLACE FUNCTION clear_certification_questions(cert_id TEXT)
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM answers 
    WHERE question_id IN (
        SELECT id FROM questions WHERE certification_id = cert_id
    );
    
    DELETE FROM questions WHERE certification_id = cert_id;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- NOTES FOR MANUAL MIGRATION
-- =============================================

/*
To complete the migration of your JSON questions to Supabase:

1. For each of your 5 JSON files (Domain 1-5), you need to:
   - Open the JSON file
   - Convert each question to a SELECT insert_question_with_answers() call
   - Use the correct section_id for each domain:
     * Domain 1: 'security-principles'
     * Domain 2: 'incident-response'  
     * Domain 3: 'access-controls'
     * Domain 4: 'network-security'
     * Domain 5: 'security-operations'

2. The JSON structure in your files should map to:
   - question.text -> question text
   - question.explanation -> explanation
   - question.answers[] -> answers array with text and isCorrect fields

3. After inserting all questions, run the verification queries to ensure:
   - Each domain has ~20 questions
   - Total ISC² CC questions = 100
   - Each question has exactly 4 answers
   - Each question has exactly 1 correct answer

4. Alternatively, use the Flutter migration script I'll create next to automate this process.
*/