-- Script to add new questions to Supabase
-- Use this template to add questions via Supabase SQL Editor

-- Method 1: Add a single question with answers
SELECT insert_question_with_answers(
    'isc2-cc',                    -- certification_id
    'security-principles',        -- section_id
    'What is the primary purpose of encryption?',  -- question text
    'Encryption is used to protect data confidentiality by converting readable data into an unreadable format that can only be decrypted with the proper key.',  -- explanation
    '[
        {"text": "To ensure data availability", "isCorrect": false},
        {"text": "To protect data confidentiality", "isCorrect": true},
        {"text": "To improve system performance", "isCorrect": false},
        {"text": "To reduce storage costs", "isCorrect": false}
    ]'::JSONB                     -- answers array
);

-- Method 2: Add multiple questions at once
SELECT insert_question_with_answers(
    'isc2-cc',
    'network-security',
    'Which protocol is used for secure web browsing?',
    'HTTPS (HTTP Secure) uses SSL/TLS encryption to secure web communications between browsers and servers.',
    '[
        {"text": "HTTP", "isCorrect": false},
        {"text": "HTTPS", "isCorrect": true},
        {"text": "FTP", "isCorrect": false},
        {"text": "SMTP", "isCorrect": false}
    ]'::JSONB
);

SELECT insert_question_with_answers(
    'isc2-cc',
    'access-controls',
    'What does the principle of least privilege mean?',
    'The principle of least privilege states that users should be granted the minimum level of access necessary to perform their job functions.',
    '[
        {"text": "Users should have maximum access for convenience", "isCorrect": false},
        {"text": "Users should have minimum necessary access", "isCorrect": true},
        {"text": "All users should have the same access level", "isCorrect": false},
        {"text": "Access should be granted based on seniority", "isCorrect": false}
    ]'::JSONB
);

-- Method 3: Add questions for new certifications
-- First, add the certification if it doesn't exist
INSERT INTO certifications (id, name, description, total_questions, is_active) 
VALUES (
    'comptia-network-plus',
    'CompTIA Network+',
    'Networking fundamentals certification covering network technologies, installation, and troubleshooting.',
    0,  -- Will be updated automatically
    true
) ON CONFLICT (id) DO NOTHING;

-- Add sections for the new certification
INSERT INTO sections (id, certification_id, name, description, question_count, order_index, is_active) 
VALUES 
    ('network-fundamentals', 'comptia-network-plus', 'Network Fundamentals', 'Basic networking concepts and protocols', 0, 1, true),
    ('network-implementations', 'comptia-network-plus', 'Network Implementations', 'Network infrastructure and implementations', 0, 2, true),
    ('network-operations', 'comptia-network-plus', 'Network Operations', 'Network monitoring and operations', 0, 3, true)
ON CONFLICT (id) DO NOTHING;

-- Add questions for the new certification
SELECT insert_question_with_answers(
    'comptia-network-plus',
    'network-fundamentals',
    'What is the default subnet mask for a Class C network?',
    'Class C networks use a default subnet mask of 255.255.255.0 (/24), which provides 254 host addresses per network.',
    '[
        {"text": "255.0.0.0", "isCorrect": false},
        {"text": "255.255.0.0", "isCorrect": false},
        {"text": "255.255.255.0", "isCorrect": true},
        {"text": "255.255.255.255", "isCorrect": false}
    ]'::JSONB
);

-- Method 4: Bulk insert from JSON structure (similar to your original data)
-- You can adapt this for your JSON format
DO $$
DECLARE
    question_data JSONB := '[
        {
            "question": "What is a firewall?",
            "explanation": "A firewall is a network security device that monitors and controls incoming and outgoing network traffic based on predetermined security rules.",
            "options": {
                "A": "A type of antivirus software",
                "B": "A network security device that controls traffic",
                "C": "A backup storage system",
                "D": "A password manager"
            },
            "answer": "B"
        },
        {
            "question": "What does VPN stand for?",
            "explanation": "VPN stands for Virtual Private Network, which creates a secure connection over a public network.",
            "options": {
                "A": "Virtual Private Network",
                "B": "Very Personal Network",
                "C": "Verified Public Network",
                "D": "Virtual Protected Network"
            },
            "answer": "A"
        }
    ]';
    question_item JSONB;
    options_obj JSONB;
    correct_answer TEXT;
    answers_array JSONB;
BEGIN
    FOR question_item IN SELECT * FROM jsonb_array_elements(question_data)
    LOOP
        -- Extract options and correct answer
        options_obj := question_item->'options';
        correct_answer := question_item->>'answer';
        
        -- Build answers array
        SELECT jsonb_agg(
            jsonb_build_object(
                'text', value,
                'isCorrect', key = correct_answer
            )
        ) INTO answers_array
        FROM jsonb_each_text(options_obj);
        
        -- Insert the question
        PERFORM insert_question_with_answers(
            'isc2-cc',
            'security-principles',
            question_item->>'question',
            question_item->>'explanation',
            answers_array
        );
    END LOOP;
END $$;

-- Verification queries
-- Check question counts per certification
SELECT 
    c.name as certification,
    COUNT(q.id) as question_count
FROM certifications c
LEFT JOIN questions q ON c.id = q.certification_id
GROUP BY c.id, c.name
ORDER BY c.name;

-- Check question counts per section
SELECT 
    c.name as certification,
    s.name as section,
    COUNT(q.id) as question_count
FROM certifications c
JOIN sections s ON c.id = s.certification_id
LEFT JOIN questions q ON s.id = q.section_id
GROUP BY c.id, c.name, s.id, s.name
ORDER BY c.name, s.order_index;