// Migration script to transfer data from local JSON files and Hive to Supabase
// Run this script once to populate your Supabase database with questions and migrate quiz history

import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/quiz_history.dart';
import '../core/constants.dart';

class SupabaseMigrationScript {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Domain mapping for ISC² CC sections
  static const Map<String, String> domainMapping = {
    'Domain 1 -  Security Principles': 'security-principles',
    'Domain 2 - Business Continuity (BC), Disaster Recovery (DR) & Incident Response Concepts': 'incident-response',
    'Domain 3 -  Access Controls Concepts': 'access-controls',
    'Domain 4 – Network Security': 'network-security',
    'Domain 5 – Security Operations': 'security-operations',
  };

  /// Main migration function - call this to migrate everything
  Future<void> runFullMigration() async {
    print('🚀 Starting Supabase migration...');
    
    try {
      // Step 1: Migrate questions from JSON files
      await migrateQuestionsFromJson();
      
      // Step 2: Migrate quiz history from Hive
      await migrateQuizHistoryFromHive();
      
      // Step 3: Verify migration
      await verifyMigration();
      
      print('✅ Migration completed successfully!');
    } catch (e) {
      print('❌ Migration failed: $e');
      rethrow;
    }
  }

  /// Migrate all ISC² CC questions from JSON files to Supabase
  Future<void> migrateQuestionsFromJson() async {
    print('📚 Migrating questions from JSON files...');
    
    final jsonFiles = [
      'data/ISC2\'s CC/Domain 1 -  Security Principles.json',
      'data/ISC2\'s CC/Domain 2 - Business Continuity (BC), Disaster Recovery (DR) & Incident Response Concepts.json',
      'data/ISC2\'s CC/Domain 3 -  Access Controls Concepts.json',
      'data/ISC2\'s CC/Domain 4 – Network Security.json',
      'data/ISC2\'s CC/Domain 5 – Security Operations.json',
    ];

    int totalQuestions = 0;
    
    for (final jsonFile in jsonFiles) {
      try {
        print('  Processing $jsonFile...');
        
        // Load JSON file
        final jsonString = await rootBundle.loadString(jsonFile);
        final questions = json.decode(jsonString) as List<dynamic>;
        
        // Extract domain name from file path and map to section ID
        String domainName = '';
        for (final key in domainMapping.keys) {
          if (jsonFile.contains(key)) {
            domainName = key;
            break;
          }
        }
        
        final sectionId = domainMapping[domainName];
        
        if (sectionId == null) {
          print('    ⚠️  Unknown domain for file: $jsonFile, skipping...');
          continue;
        }
        int domainQuestionCount = 0;
        
        for (final questionData in questions) {
          await _insertQuestionWithAnswers(
            certificationId: 'isc2-cc',
            sectionId: sectionId,
            questionData: questionData as Map<String, dynamic>,
          );
          domainQuestionCount++;
        }
        
        totalQuestions += domainQuestionCount;
        print('    ✅ Migrated $domainQuestionCount questions from $domainName');
        
      } catch (e) {
        print('    ❌ Failed to process $jsonFile: $e');
      }
    }
    
    print('📚 Total questions migrated: $totalQuestions');
  }

  /// Insert a single question with its answers into Supabase
  Future<void> _insertQuestionWithAnswers({
    required String certificationId,
    required String sectionId,
    required Map<String, dynamic> questionData,
  }) async {
    try {
      // Insert question
      final questionResponse = await _supabase
          .from('questions')
          .insert({
            'certification_id': certificationId,
            'section_id': sectionId,
            'text': questionData['question'], // Your JSON uses 'question' not 'text'
            'explanation': questionData['explanation'],
            'difficulty_level': 'medium', // Default difficulty
          })
          .select('id')
          .single();

      final questionId = questionResponse['id'];

      // Insert answers - convert your options format to our format
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
      
    } catch (e) {
      print('      ❌ Failed to insert question: ${questionData['question']?.toString().substring(0, 50)}... - $e');
      rethrow;
    }
  }

  /// Migrate quiz history from Hive to Supabase
  Future<void> migrateQuizHistoryFromHive() async {
    print('📊 Migrating quiz history from Hive...');
    
    try {
      // Initialize Hive if not already done
      if (!Hive.isBoxOpen('quiz_history')) {
        await Hive.openBox<QuizHistoryEntry>('quiz_history');
      }
      
      final hiveBox = Hive.box<QuizHistoryEntry>('quiz_history');
      final hiveEntries = hiveBox.values.toList();
      
      if (hiveEntries.isEmpty) {
        print('  📊 No quiz history found in Hive');
        return;
      }
      
      print('  📊 Found ${hiveEntries.length} quiz history entries in Hive');
      
      // First, we need to ensure current user exists in Supabase
      final currentUserId = await _ensureCurrentUserExists();
      
      int migratedCount = 0;
      
      for (final entry in hiveEntries) {
        try {
          await _migrateQuizHistoryEntry(entry, currentUserId);
          migratedCount++;
        } catch (e) {
          print('    ❌ Failed to migrate quiz history entry: $e');
        }
      }
      
      print('  ✅ Migrated $migratedCount quiz history entries');
      
    } catch (e) {
      print('  ❌ Failed to migrate quiz history: $e');
      rethrow;
    }
  }

  /// Ensure current user profile exists for migration
  Future<String> _ensureCurrentUserExists() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found. Please log in first.');
      }

      // Check if user profile already exists
      final existingProfile = await _supabase
          .from('user_profiles')
          .select('id')
          .eq('id', currentUser.id)
          .maybeSingle();
      
      if (existingProfile == null) {
        // Create user profile for current user
        await _supabase.from('user_profiles').insert({
          'id': currentUser.id,
          'name': currentUser.userMetadata?['name'] ?? 'User',
          'email': currentUser.email ?? '',
          'current_streak': 0,
          'total_questions_answered': 0,
          'total_quizzes_completed': 0,
        });
        print('  👤 Created user profile for current user');
      }

      return currentUser.id;
    } catch (e) {
      print('  ❌ Failed to ensure current user exists: $e');
      rethrow;
    }
  }

  /// Migrate a single quiz history entry
  Future<void> _migrateQuizHistoryEntry(QuizHistoryEntry entry, String userId) async {
    // Insert quiz history record
    final historyResponse = await _supabase
        .from('quiz_history')
        .insert({
          'user_id': userId, // Use current authenticated user
          'quiz_id': entry.quizId,
          'certification_id': entry.certificationId,
          'certification_name': entry.certificationName,
          'section_id': entry.sectionId,
          'section_name': entry.sectionName,
          'score_percentage': entry.scorePercentage,
          'correct_answers': entry.correctAnswers,
          'total_questions': entry.totalQuestions,
          'time_taken_seconds': entry.timeTakenSeconds,
          'completed_at': entry.completedAt.toIso8601String(),
        })
        .select('id')
        .single();

    final historyId = historyResponse['id'];

    // Note: We don't have detailed question results in the current Hive model
    // If you want to migrate question-level results, you'd need to modify the QuizHistoryEntry model
    // For now, we'll just migrate the overall quiz results
  }

  /// Verify the migration was successful
  Future<void> verifyMigration() async {
    print('🔍 Verifying migration...');
    
    try {
      // Check questions count
      final questionsCount = await _supabase
          .from('questions')
          .select('id')
          .eq('certification_id', 'isc2-cc');
      
      print('  📚 Total questions in Supabase: ${questionsCount.length}');
      
      // Check questions per section
      final sectionsWithCounts = await _supabase
          .from('sections')
          .select('id, name')
          .eq('certification_id', 'isc2-cc');
      
      for (final section in sectionsWithCounts) {
        final sectionQuestions = await _supabase
            .from('questions')
            .select('id')
            .eq('section_id', section['id']);
        
        print('    ${section['name']}: ${sectionQuestions.length} questions');
      }
      
      // Check quiz history count
      final historyCount = await _supabase
          .from('quiz_history')
          .select('id');
      
      print('  📊 Total quiz history entries: ${historyCount.length}');
      
      // Check user profiles
      final usersCount = await _supabase
          .from('user_profiles')
          .select('id');
      
      print('  👤 Total user profiles: ${usersCount.length}');
      
    } catch (e) {
      print('  ❌ Verification failed: $e');
      rethrow;
    }
  }

  /// Clear all migrated data (use with caution!)
  Future<void> clearMigratedData() async {
    print('🗑️  Clearing migrated data...');
    
    try {
      // Delete in reverse order due to foreign key constraints
      await _supabase.from('answers').delete().neq('id', '00000000-0000-0000-0000-000000000000');
      await _supabase.from('quiz_question_results').delete().neq('id', '00000000-0000-0000-0000-000000000000');
      await _supabase.from('quiz_history').delete().neq('id', '00000000-0000-0000-0000-000000000000');
      await _supabase.from('questions').delete().neq('id', '00000000-0000-0000-0000-000000000000');
      await _supabase.from('user_certification_progress').delete().neq('id', '00000000-0000-0000-0000-000000000000');
      await _supabase.from('user_profiles').delete().neq('id', '00000000-0000-0000-0000-000000000000');
      
      print('  ✅ All migrated data cleared');
    } catch (e) {
      print('  ❌ Failed to clear data: $e');
      rethrow;
    }
  }
}

/// Helper function to run migration from Flutter app
Future<void> runSupabaseMigration() async {
  final migration = SupabaseMigrationScript();
  await migration.runFullMigration();
}

/// Helper function to clear migration data
Future<void> clearSupabaseMigration() async {
  final migration = SupabaseMigrationScript();
  await migration.clearMigratedData();
}