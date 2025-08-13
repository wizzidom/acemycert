-- Cybersecurity Quiz Platform - Data Seeding Script
-- This script populates the database with certifications, sections, and questions

-- =============================================
-- CERTIFICATIONS
-- =============================================

INSERT INTO certifications (id, name, description, total_questions, is_active) VALUES
('isc2-cc', 'ISC² CC', 'Certified in Cybersecurity - foundational cybersecurity knowledge and skills with real exam questions.', 100, true),
('comptia-security-plus', 'CompTIA Security+', 'Foundational cybersecurity certification covering network security, compliance, and operational security. (No questions available yet)', 0, true),
('comptia-a-plus', 'CompTIA A+', 'Entry-level IT certification covering hardware, networking, mobile devices, and troubleshooting. (No questions available yet)', 0, true);

-- =============================================
-- SECTIONS (ISC² CC DOMAINS)
-- =============================================

INSERT INTO sections (id, certification_id, name, description, question_count, order_index, is_active) VALUES
('security-principles', 'isc2-cc', 'Security Principles', 'Fundamental security concepts and principles', 20, 1, true),
('incident-response', 'isc2-cc', 'Business Continuity, Disaster Recovery & Incident Response Concepts', 'Incident response processes and business continuity', 20, 2, true),
('access-controls', 'isc2-cc', 'Access Controls Concepts', 'Access control concepts and implementation', 20, 3, true),
('network-security', 'isc2-cc', 'Network Security', 'Network security concepts and technologies', 20, 4, true),
('security-operations', 'isc2-cc', 'Security Operations', 'Security operations and data security', 20, 5, true);

-- CompTIA Security+ sections (no questions yet)
INSERT INTO sections (id, certification_id, name, description, question_count, order_index, is_active) VALUES
('threats-attacks-vulnerabilities', 'comptia-security-plus', 'Threats, Attacks, and Vulnerabilities', 'Understanding various security threats and attack vectors (No questions available)', 0, 1, true),
('architecture-design', 'comptia-security-plus', 'Architecture and Design', 'Secure network architecture and design principles (No questions available)', 0, 2, true),
('implementation', 'comptia-security-plus', 'Implementation', 'Implementing secure protocols and systems (No questions available)', 0, 3, true),
('operations-incident-response', 'comptia-security-plus', 'Operations and Incident Response', 'Security operations and incident response procedures (No questions available)', 0, 4, true),
('governance-risk-compliance', 'comptia-security-plus', 'Governance, Risk, and Compliance', 'Risk management and compliance frameworks (No questions available)', 0, 5, true);

-- CompTIA A+ sections (no questions yet)
INSERT INTO sections (id, certification_id, name, description, question_count, order_index, is_active) VALUES
('mobile-devices', 'comptia-a-plus', 'Mobile Devices', 'Mobile device hardware and configuration (No questions available)', 0, 1, true),
('networking', 'comptia-a-plus', 'Networking', 'Network protocols, devices, and troubleshooting (No questions available)', 0, 2, true),
('hardware', 'comptia-a-plus', 'Hardware', 'Computer hardware components and troubleshooting (No questions available)', 0, 3, true),
('virtualization-cloud', 'comptia-a-plus', 'Virtualization and Cloud Computing', 'Virtual machines and cloud services (No questions available)', 0, 4, true);

-- =============================================
-- SAMPLE QUESTIONS (You'll need to run the migration script to populate all questions)
-- =============================================

-- Note: The actual questions from your JSON files will be inserted via the migration script
-- This is just a sample to show the structure

-- Sample question for Domain 1 - Security Principles
DO $$
DECLARE
    question_id UUID;
    answer1_id UUID;
    answer2_id UUID;
    answer3_id UUID;
    answer4_id UUID;
BEGIN
    -- Insert sample question
    INSERT INTO questions (certification_id, section_id, text, explanation, difficulty_level)
    VALUES (
        'isc2-cc',
        'security-principles',
        'What is the primary goal of information security?',
        'The primary goal of information security is to protect the confidentiality, integrity, and availability (CIA triad) of information and information systems.',
        'easy'
    ) RETURNING id INTO question_id;

    -- Insert answers for the sample question
    INSERT INTO answers (question_id, text, is_correct, order_index) VALUES
    (question_id, 'To ensure confidentiality, integrity, and availability of information', true, 1),
    (question_id, 'To prevent all unauthorized access to systems', false, 2),
    (question_id, 'To implement the strongest possible encryption', false, 3),
    (question_id, 'To eliminate all security vulnerabilities', false, 4);
END $$;

-- =============================================
-- HELPER FUNCTIONS FOR DATA MIGRATION
-- =============================================

-- Function to insert a question with its answers
CREATE OR REPLACE FUNCTION insert_question_with_answers(
    p_certification_id TEXT,
    p_section_id TEXT,
    p_question_text TEXT,
    p_explanation TEXT,
    p_answers JSONB,
    p_difficulty TEXT DEFAULT 'medium'
)
RETURNS UUID AS $$
DECLARE
    question_id UUID;
    answer_item JSONB;
    answer_index INTEGER := 1;
BEGIN
    -- Insert the question
    INSERT INTO questions (certification_id, section_id, text, explanation, difficulty_level)
    VALUES (p_certification_id, p_section_id, p_question_text, p_explanation, p_difficulty)
    RETURNING id INTO question_id;
    
    -- Insert the answers
    FOR answer_item IN SELECT * FROM jsonb_array_elements(p_answers)
    LOOP
        INSERT INTO answers (question_id, text, is_correct, order_index)
        VALUES (
            question_id,
            answer_item->>'text',
            (answer_item->>'isCorrect')::BOOLEAN,
            answer_index
        );
        answer_index := answer_index + 1;
    END LOOP;
    
    RETURN question_id;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- VIEWS FOR EASY DATA ACCESS
-- =============================================

-- View for questions with their answers
CREATE OR REPLACE VIEW questions_with_answers AS
SELECT 
    q.id as question_id,
    q.certification_id,
    q.section_id,
    q.text as question_text,
    q.explanation,
    q.difficulty_level,
    json_agg(
        json_build_object(
            'id', a.id,
            'text', a.text,
            'isCorrect', a.is_correct,
            'orderIndex', a.order_index
        ) ORDER BY a.order_index
    ) as answers
FROM questions q
LEFT JOIN answers a ON q.id = a.question_id
WHERE q.is_active = true
GROUP BY q.id, q.certification_id, q.section_id, q.text, q.explanation, q.difficulty_level;

-- View for user statistics
CREATE OR REPLACE VIEW user_statistics AS
SELECT 
    up.id as user_id,
    up.name,
    up.email,
    up.current_streak,
    up.total_questions_answered,
    up.total_quizzes_completed,
    up.last_activity_date,
    COALESCE(AVG(qh.score_percentage), 0) as average_score,
    COALESCE(MAX(qh.score_percentage), 0) as best_score,
    COALESCE(SUM(qh.time_taken_seconds), 0) as total_study_time_seconds
FROM user_profiles up
LEFT JOIN quiz_history qh ON up.id = qh.user_id
GROUP BY up.id, up.name, up.email, up.current_streak, up.total_questions_answered, up.total_quizzes_completed, up.last_activity_date;

-- View for certification progress
CREATE OR REPLACE VIEW certification_progress_view AS
SELECT 
    ucp.*,
    c.name as certification_name,
    c.description as certification_description
FROM user_certification_progress ucp
JOIN certifications c ON ucp.certification_id = c.id;

-- =============================================
-- SAMPLE DATA VERIFICATION
-- =============================================

-- Check if data was inserted correctly
SELECT 'Certifications' as table_name, COUNT(*) as count FROM certifications
UNION ALL
SELECT 'Sections' as table_name, COUNT(*) as count FROM sections
UNION ALL
SELECT 'Questions' as table_name, COUNT(*) as count FROM questions
UNION ALL
SELECT 'Answers' as table_name, COUNT(*) as count FROM answers;