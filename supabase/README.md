# Supabase Migration Guide

This guide will help you migrate your Cybersecurity Quiz Platform from local storage (Hive) to Supabase.

## Prerequisites

1. **Supabase Account**: Create a free account at [supabase.com](https://supabase.com)
2. **Supabase Project**: Create a new project in your Supabase dashboard
3. **Flutter Dependencies**: Ensure `supabase_flutter` is added to your `pubspec.yaml`

## Step 1: Set Up Supabase Project

### 1.1 Create Project
1. Go to [supabase.com](https://supabase.com) and sign in
2. Click "New Project"
3. Choose your organization
4. Enter project name: `cybersecurity-quiz-platform`
5. Enter a strong database password
6. Select a region close to your users
7. Click "Create new project"

### 1.2 Get Project Credentials
1. Go to Project Settings → API
2. Copy your:
   - **Project URL** (e.g., `https://your-project.supabase.co`)
   - **Anon Public Key** (starts with `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`)

### 1.3 Update Flutter Constants
Update `lib/core/constants.dart` with your Supabase credentials:

```dart
class AppConstants {
  // ... existing constants ...
  
  // Supabase Configuration
  static const String supabaseUrl = 'https://jxlxgvfxxbjlypngrdbm.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp4bHhndmZ4eGJqbHlwbmdyZGJtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUwNzc2NTMsImV4cCI6MjA3MDY1MzY1M30.pX7LLZ6NNaWnsBeyNkLu6NNfSgcf3wDE5GgcaAy5twE';
}
```

## Step 2: Set Up Database Schema

### 2.1 Run Schema Script
1. Go to your Supabase dashboard
2. Navigate to SQL Editor
3. Copy the contents of `supabase/schema.sql`
4. Paste and run the script
5. Verify all tables were created successfully

### 2.2 Run Seed Data Script
1. In SQL Editor, create a new query
2. Copy the contents of `supabase/seed_data.sql`
3. Paste and run the script
4. Verify certifications and sections were created

## Step 3: Migrate Questions Data

You have two options for migrating your JSON question data:

### Option A: Automated Migration (Recommended)

1. **Enable Supabase in Flutter**:
   ```dart
   // In main.dart, uncomment and update:
   await Supabase.initialize(
     url: AppConstants.supabaseUrl,
     anonKey: AppConstants.supabaseAnonKey,
   );
   ```

2. **Run Migration Script**:
   ```dart
   // Add this to your app temporarily (e.g., in a debug button)
   import 'package:your_app/scripts/migrate_to_supabase.dart';
   
   // Run migration
   await runSupabaseMigration();
   ```

3. **Verify Migration**:
   - Check Supabase dashboard → Table Editor
   - Verify `questions` table has ~100 entries
   - Verify `answers` table has ~400 entries
   - Check each section has ~20 questions

### Option B: Manual Migration

1. **Convert JSON to SQL**:
   - Open each JSON file in `data/ISC2's CC/`
   - For each question, create an INSERT statement using the template in `migrate_questions.sql`
   - Use the correct `section_id` for each domain

2. **Run SQL Inserts**:
   - Copy your generated INSERT statements
   - Run them in Supabase SQL Editor

## Step 4: Migrate Quiz History

The automated migration script will also migrate your existing quiz history from Hive to Supabase.

### Manual Verification
After migration, check in Supabase dashboard:
- `quiz_history` table should contain your completed quizzes
- `user_profiles` table should have user statistics
- `user_certification_progress` table should show progress per certification

## Step 5: Update Flutter Code

### 5.1 Switch to Supabase Services
Update `main.dart` to use Supabase services:

```dart
// Replace MockAuthService with SupabaseAuthService
Provider<AuthService>(
  create: (_) => SupabaseAuthService(), // Changed from MockAuthService
),
```

### 5.2 Update Repository
The app will automatically use Supabase repositories once the migration is complete.

## Step 6: Test the Migration

### 6.1 Authentication
1. Try signing up with a new account
2. Verify user profile is created in Supabase
3. Test login/logout functionality

### 6.2 Quiz Functionality
1. Start a quiz and verify questions load from Supabase
2. Complete a quiz and check if results are saved
3. Verify quiz history appears correctly
4. Check profile statistics are updated

### 6.3 Data Consistency
1. Compare question counts with original JSON files
2. Verify all quiz history was migrated
3. Check user statistics are accurate

## Troubleshooting

### Common Issues

**1. Authentication Errors**
- Verify Supabase URL and anon key are correct
- Check if RLS policies are properly configured
- Ensure user profiles are created on signup

**2. Question Loading Issues**
- Verify questions were inserted correctly
- Check if `is_active` flag is set to `true`
- Ensure section IDs match between questions and sections

**3. Quiz History Not Saving**
- Check RLS policies allow users to insert their own data
- Verify foreign key relationships are correct
- Check if user profile exists before saving quiz history

**4. Migration Script Errors**
- Ensure all JSON files are accessible
- Check if Supabase connection is working
- Verify database schema is set up correctly

### Verification Queries

Run these in Supabase SQL Editor to verify migration:

```sql
-- Check question counts per section
SELECT 
    s.name as section_name,
    COUNT(q.id) as question_count
FROM sections s
LEFT JOIN questions q ON s.id = q.section_id
WHERE s.certification_id = 'isc2-cc'
GROUP BY s.id, s.name
ORDER BY s.order_index;

-- Check total ISC² CC questions
SELECT COUNT(*) as total_questions 
FROM questions 
WHERE certification_id = 'isc2-cc';

-- Check quiz history
SELECT 
    COUNT(*) as total_quizzes,
    AVG(score_percentage) as avg_score,
    MAX(score_percentage) as best_score
FROM quiz_history;

-- Check user profiles
SELECT 
    name,
    total_quizzes_completed,
    total_questions_answered,
    current_streak
FROM user_profiles;
```

## Security Considerations

1. **Row Level Security**: All tables have RLS enabled
2. **User Data Isolation**: Users can only access their own data
3. **Public Data**: Questions and certifications are publicly readable
4. **API Keys**: Keep your anon key secure, don't commit to version control

## Performance Optimization

1. **Indexes**: All necessary indexes are created by the schema
2. **Views**: Use the provided views for complex queries
3. **Caching**: Consider implementing client-side caching for questions
4. **Pagination**: Implement pagination for large quiz history lists

## Backup and Recovery

1. **Regular Backups**: Enable automatic backups in Supabase dashboard
2. **Export Data**: Use Supabase CLI to export data periodically
3. **Version Control**: Keep your schema and migration scripts in version control

## Next Steps

After successful migration:

1. **Remove Hive Dependencies**: Clean up Hive-related code
2. **Add Real-time Features**: Use Supabase real-time for live updates
3. **Implement Analytics**: Track user engagement and quiz performance
4. **Add More Certifications**: Expand beyond ISC² CC
5. **Mobile Optimization**: Optimize for offline usage with local caching

## Support

If you encounter issues:
1. Check Supabase documentation: [supabase.com/docs](https://supabase.com/docs)
2. Review Flutter Supabase guide: [supabase.com/docs/guides/getting-started/tutorials/with-flutter](https://supabase.com/docs/guides/getting-started/tutorials/with-flutter)
3. Check the migration logs for specific error messages
4. Verify your database schema matches the expected structure