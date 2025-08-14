// Bulk Question Uploader - Handles uploading new questions from JSON files
// This script processes your updated JSON files and uploads only NEW questions

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BulkQuestionUploader {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Domain mapping (same as migration script)
  static const Map<String, String> domainMapping = {
    'Domain 1 -  Security Principles': 'security-principles',
    'Domain 2 - Business Continuity (BC), Disaster Recovery (DR) & Incident Response Concepts':
        'incident-response',
    'Domain 3 -  Access Controls Concepts': 'access-controls',
    'Domain 4 – Network Security': 'network-security',
    'Domain 5 – Security Operations': 'security-operations',
  };

  /// Upload new questions from updated JSON files
  Future<void> uploadNewQuestions() async {
    print('🚀 Starting bulk question upload...');

    try {
      // Step 1: Get current question count per domain
      final currentCounts = await _getCurrentQuestionCounts();
      print('📊 Current question counts: $currentCounts');

      // Step 2: Process each JSON file
      final jsonFiles = [
        'data/ISC2\'s CC/Domain 1 -  Security Principles.json',
        'data/ISC2\'s CC/Domain 2 - Business Continuity (BC), Disaster Recovery (DR) & Incident Response Concepts.json',
        'data/ISC2\'s CC/Domain 3 -  Access Controls Concepts.json',
        'data/ISC2\'s CC/Domain 4 – Network Security.json',
        'data/ISC2\'s CC/Domain 5 – Security Operations.json',
      ];

      int totalNewQuestions = 0;

      for (final jsonFile in jsonFiles) {
        final newQuestions = await _processJsonFile(jsonFile, currentCounts);
        totalNewQuestions += newQuestions;
      }

      print('✅ Upload completed! Added $totalNewQuestions new questions');

      // Step 3: Update section question counts
      await _updateSectionCounts();

      // Step 4: Verify upload
      await _verifyUpload();
    } catch (e) {
      print('❌ Bulk upload failed: $e');
      rethrow;
    }
  }

  /// Get current question counts per section
  Future<Map<String, int>> _getCurrentQuestionCounts() async {
    final response = await _supabase
        .from('sections')
        .select('id, question_count')
        .eq('certification_id', 'isc2-cc');

    final Map<String, int> counts = {};
    for (final data in response) {
      counts[data['id'] as String] = data['question_count'] as int;
    }

    return counts;
  }

  /// Process a single JSON file and upload new questions
  Future<int> _processJsonFile(
      String jsonFile, Map<String, int> currentCounts) async {
    try {
      print('📚 Processing $jsonFile...');

      // Load JSON file
      final jsonString = await rootBundle.loadString(jsonFile);
      final questions = json.decode(jsonString) as List<dynamic>;

      // Determine section ID from file path
      String sectionId = '';
      for (final key in domainMapping.keys) {
        if (jsonFile.contains(key)) {
          sectionId = domainMapping[key]!;
          break;
        }
      }

      if (sectionId.isEmpty) {
        print('  ⚠️  Could not determine section for $jsonFile');
        return 0;
      }

      print('  📊 Questions in JSON file: ${questions.length}');

      // Get existing questions from database for duplicate detection
      final existingQuestions = await _getExistingQuestions(sectionId);
      print('  📊 Existing questions in database: ${existingQuestions.length}');

      // Filter out questions that already exist
      final newQuestions = <Map<String, dynamic>>[];
      int duplicateCount = 0;

      for (final questionData in questions) {
        final question = questionData as Map<String, dynamic>;
        final questionText = question['question'] as String;

        // Check if this question already exists
        final isDuplicate = existingQuestions.any((existing) =>
            _normalizeText(existing) == _normalizeText(questionText));

        if (isDuplicate) {
          duplicateCount++;
        } else {
          newQuestions.add(question);
        }
      }

      print('  🔍 Duplicates found: $duplicateCount');
      print('  ➕ New questions to add: ${newQuestions.length}');

      if (newQuestions.isEmpty) {
        print('  ✅ No new questions to add for $sectionId');
        return 0;
      }

      // Upload new questions
      int uploadedCount = 0;
      for (final questionData in newQuestions) {
        try {
          await _insertQuestion(
            certificationId: 'isc2-cc',
            sectionId: sectionId,
            questionData: questionData,
          );
          uploadedCount++;
        } catch (e) {
          print('    ❌ Failed to upload question ${questionData['id']}: $e');
        }
      }

      print('  ✅ Uploaded $uploadedCount new questions to $sectionId');
      return uploadedCount;
    } catch (e) {
      print('  ❌ Failed to process $jsonFile: $e');
      return 0;
    }
  }

  /// Insert a single question with answers
  Future<void> _insertQuestion({
    required String certificationId,
    required String sectionId,
    required Map<String, dynamic> questionData,
  }) async {
    // Insert question
    final questionResponse = await _supabase
        .from('questions')
        .insert({
          'certification_id': certificationId,
          'section_id': sectionId,
          'text': questionData['question'],
          'explanation': questionData['explanation'],
          'difficulty_level': 'medium',
        })
        .select('id')
        .single();

    final questionId = questionResponse['id'];

    // Insert answers
    final options = questionData['options'] as Map<String, dynamic>;
    final correctAnswer = questionData['answer'] as String;
    final answerInserts = <Map<String, dynamic>>[];

    int orderIndex = 1;
    for (final entry in options.entries) {
      final optionKey = entry.key; // A, B, C, D
      final optionText = entry.value as String;
      final isCorrect = optionKey == correctAnswer;

      answerInserts.add({
        'question_id': questionId,
        'text': optionText,
        'is_correct': isCorrect,
        'order_index': orderIndex,
      });
      orderIndex++;
    }

    await _supabase.from('answers').insert(answerInserts);
  }

  /// Update section question counts after upload
  Future<void> _updateSectionCounts() async {
    print('🔄 Updating section question counts...');

    final sections = await _supabase
        .from('sections')
        .select('id')
        .eq('certification_id', 'isc2-cc');

    for (final section in sections) {
      final sectionId = section['id'] as String;

      // Count actual questions in this section
      final questionCount = await _supabase
          .from('questions')
          .select('id')
          .eq('section_id', sectionId);

      // Update section question count
      await _supabase
          .from('sections')
          .update({'question_count': questionCount.length}).eq('id', sectionId);
    }

    // Update total certification question count
    final totalQuestions = await _supabase
        .from('questions')
        .select('id')
        .eq('certification_id', 'isc2-cc');

    await _supabase
        .from('certifications')
        .update({'total_questions': totalQuestions.length}).eq('id', 'isc2-cc');

    print('✅ Section counts updated');
  }

  /// Verify the upload was successful
  Future<void> _verifyUpload() async {
    print('🔍 Verifying upload...');

    // Check total questions
    final totalQuestions = await _supabase
        .from('questions')
        .select('id')
        .eq('certification_id', 'isc2-cc');

    print('📊 Total ISC² CC questions: ${totalQuestions.length}');

    // Check questions per section
    final sections = await _supabase
        .from('sections')
        .select('id, name, question_count')
        .eq('certification_id', 'isc2-cc')
        .order('order_index');

    for (final section in sections) {
      print('  ${section['name']}: ${section['question_count']} questions');
    }
  }

  /// Get existing question texts from database for duplicate detection
  Future<List<String>> _getExistingQuestions(String sectionId) async {
    final response = await _supabase
        .from('questions')
        .select('text')
        .eq('section_id', sectionId);

    return response.map((row) => row['text'] as String).toList();
  }

  /// Normalize text for comparison (remove extra spaces, convert to lowercase)
  String _normalizeText(String text) {
    return text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}

/// Helper function to run the bulk upload
Future<void> runBulkQuestionUpload() async {
  final uploader = BulkQuestionUploader();
  await uploader.uploadNewQuestions();
}
