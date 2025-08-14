# Adding New Questions to Your Quiz Platform

This guide covers all the methods to add new questions to your Supabase database.

## 🎯 **Method 1: Direct SQL (Recommended for Bulk)**

### **Step 1: Use Supabase SQL Editor**
1. Go to your Supabase dashboard
2. Navigate to **SQL Editor**
3. Use the template from `supabase/add_new_questions.sql`

### **Step 2: Add Single Question**
```sql
SELECT insert_question_with_answers(
    'isc2-cc',                    -- certification_id
    'security-principles',        -- section_id
    'Your question text here',    -- question
    'Your explanation here',      -- explanation
    '[
        {"text": "Option A", "isCorrect": false},
        {"text": "Option B", "isCorrect": true},
        {"text": "Option C", "isCorrect": false},
        {"text": "Option D", "isCorrect": false}
    ]'::JSONB                     -- answers
);
```

### **Step 3: Verify Addition**
```sql
-- Check question count
SELECT COUNT(*) FROM questions WHERE certification_id = 'isc2-cc';

-- Check by section
SELECT s.name, COUNT(q.id) as question_count
FROM sections s
LEFT JOIN questions q ON s.id = q.section_id
WHERE s.certification_id = 'isc2-cc'
GROUP BY s.id, s.name;
```

## 🎯 **Method 2: JSON File + Import Script**

### **Step 1: Create JSON File**
Use the template in `data/new_questions_template.json`:

```json
[
  {
    "id": 1,
    "domain": "Security Principles",
    "question": "Your question here?",
    "options": {
      "A": "Option A text",
      "B": "Option B text",
      "C": "Option C text", 
      "D": "Option D text"
    },
    "answer": "B",
    "explanation": "Your explanation here."
  }
]
```

### **Step 2: Run Import Script**
```dart
// Use the import script in lib/scripts/import_questions.dart
final importer = QuestionImporter();
await importer.importQuestionsFromFile(
  'data/your_new_questions.json',
  'isc2-cc'
);
```

## 🎯 **Method 3: Admin Panel (Future)**

The admin panel (`lib/screens/admin/admin_question_screen.dart`) provides a UI for adding questions:

- Form-based question entry
- Dropdown selection for certification/section
- Radio buttons for correct answer selection
- Real-time validation

## 📊 **Available Certifications & Sections**

### **ISC² CC (isc2-cc)**
- `security-principles` - Security Principles
- `incident-response` - Business Continuity & Incident Response
- `access-controls` - Access Controls Concepts
- `network-security` - Network Security
- `security-operations` - Security Operations

### **CompTIA Security+ (comptia-security-plus)**
- `threats-attacks-vulnerabilities` - Threats, Attacks, and Vulnerabilities
- `architecture-design` - Architecture and Design
- `implementation` - Implementation
- `operations-incident-response` - Operations and Incident Response
- `governance-risk-compliance` - Governance, Risk, and Compliance

### **CompTIA Network+ (comptia-network-plus)**
- `network-fundamentals` - Network Fundamentals
- `network-implementations` - Network Implementations
- `network-operations` - Network Operations

## 🔧 **Adding New Certifications**

### **Step 1: Add Certification**
```sql
INSERT INTO certifications (id, name, description, total_questions, is_active) 
VALUES (
    'your-cert-id',
    'Your Certification Name',
    'Description of the certification',
    0,
    true
);
```

### **Step 2: Add Sections**
```sql
INSERT INTO sections (id, certification_id, name, description, question_count, order_index, is_active) 
VALUES 
    ('section-1', 'your-cert-id', 'Section 1 Name', 'Section description', 0, 1, true),
    ('section-2', 'your-cert-id', 'Section 2 Name', 'Section description', 0, 2, true);
```

### **Step 3: Add Questions**
Use any of the methods above with your new certification ID.

## 🚀 **Best Practices**

### **Question Quality**
- Clear, unambiguous question text
- Detailed explanations with reasoning
- Realistic distractors (wrong answers)
- Appropriate difficulty level

### **Data Consistency**
- Use consistent terminology
- Follow the same format for all questions
- Verify correct answers are actually correct
- Test questions before adding to production

### **Performance**
- Add questions in batches for better performance
- Use transactions for bulk operations
- Verify data integrity after imports

## 🔍 **Verification Queries**

### **Check Question Distribution**
```sql
SELECT 
    c.name as certification,
    s.name as section,
    COUNT(q.id) as questions,
    AVG(LENGTH(q.text)) as avg_question_length
FROM certifications c
JOIN sections s ON c.id = s.certification_id
LEFT JOIN questions q ON s.id = q.section_id
GROUP BY c.id, c.name, s.id, s.name
ORDER BY c.name, s.order_index;
```

### **Check Answer Distribution**
```sql
SELECT 
    q.text as question,
    COUNT(a.id) as answer_count,
    SUM(CASE WHEN a.is_correct THEN 1 ELSE 0 END) as correct_answers
FROM questions q
LEFT JOIN answers a ON q.id = a.question_id
GROUP BY q.id, q.text
HAVING COUNT(a.id) != 4 OR SUM(CASE WHEN a.is_correct THEN 1 ELSE 0 END) != 1;
```

## 📱 **App Integration**

After adding questions:

1. **No App Changes Needed**: Questions appear automatically
2. **Cache Refresh**: Users may need to refresh or restart app
3. **Real-time Updates**: New questions available immediately
4. **Statistics Update**: Question counts update automatically

## 🛠️ **Troubleshooting**

### **Common Issues**
- **Duplicate Questions**: Check for existing questions before adding
- **Missing Sections**: Ensure section exists before adding questions
- **Invalid JSON**: Validate JSON format before importing
- **Permission Errors**: Check RLS policies for question insertion

### **Debug Queries**
```sql
-- Find questions without answers
SELECT q.* FROM questions q
LEFT JOIN answers a ON q.id = a.question_id
WHERE a.id IS NULL;

-- Find questions with wrong answer count
SELECT q.text, COUNT(a.id) as answer_count
FROM questions q
LEFT JOIN answers a ON q.id = a.question_id
GROUP BY q.id, q.text
HAVING COUNT(a.id) != 4;
```

The platform is designed to handle new questions seamlessly - just add them to the database and they'll appear in the app automatically!