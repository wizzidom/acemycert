# JSON Upload Flow

When you add new questions to your JSON files, here's how they get uploaded to Supabase:

## Current Process

1. **Add Questions to JSON**: Edit your domain JSON files and add new questions
2. **Run Bulk Uploader**: Use `flutter run lib/scripts/bulk_question_uploader.dart` or the GUI version
3. **Smart Duplicate Detection**: The uploader compares actual question text content
4. **Upload New Questions**: Only processes questions that don't already exist in the database
5. **Update Counts**: Automatically updates section and certification question counts

## Duplicate Prevention

The system prevents duplicates by:
- **Content-based Detection**: Compares normalized question text (case-insensitive, whitespace-normalized)
- **Database Verification**: Checks existing questions in each section before uploading
- **Safe Re-runs**: You can run the uploader multiple times without creating duplicates
- **Real-time Feedback**: Shows exactly how many duplicates were found and skipped

## Usage Options

### Option 1: Command Line
```bash
flutter run lib/scripts/bulk_question_uploader.dart
```

### Option 2: GUI Interface
```bash
flutter run lib/scripts/run_bulk_uploader.dart
```

The GUI version provides a user-friendly interface with real-time progress and logs.

## Output Example

```
📚 Processing Domain 1 - Security Principles.json...
📊 Questions in JSON file: 150
📊 Existing questions in database: 100
🔍 Duplicates found: 0
➕ New questions to add: 50
✅ Uploaded 50 new questions to security-principles
```

The uploader will show progress and only upload genuinely new questions, making it safe to run multiple times.

## How It Works

When you add 50 new questions to each domain:

1. **Content Analysis**: The uploader reads each JSON file and extracts all questions
2. **Database Query**: Fetches existing question texts from the corresponding section
3. **Text Comparison**: Normalizes and compares question text to detect exact matches
4. **Smart Filtering**: Only processes questions that don't already exist
5. **Batch Upload**: Inserts new questions with proper relationships to answers
6. **Count Updates**: Updates section and certification totals automatically

This ensures that even if you accidentally run the uploader multiple times, or if your JSON files contain some existing questions mixed with new ones, only the genuinely new content gets added to your database.