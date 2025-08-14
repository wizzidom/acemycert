// Script to import questions from JSON files to Supabase
// Run this when you have new question files to import

import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuestionImporter {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Domain mapping for section IDs
  static const Map<String, String> domainMapping = {
    'Security Principles': 'security-principles',
    'Business Continuity (BC), Disaster Recovery (DR) & Incident Response Concepts': 'incident-response',
    'Access Controls Concepts': 'access-controls',
    'Network Security': 'network-security',
    'Security Operations': 'security-operations',
  };

  /// Import questions from a JSON file
  Future<void> importQuestionsFromFile(String filePath, String certificationId) async {
    try {
      print('📚 Importing questions from $filePath...');
      
      // Read JSON file
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final questions = json.decode(jsonString) as List<dynamic>;
      
      int importedCount = 0;
      
      for (final questionData in questions) {
        await _insertQuestion(
          certificationId: certificationId,
          questionData: questionData as Map<String, dynamic>,
        );
        importedCount++;
      }
      
      print('✅ Imported $importedCount questions successfully');
      
    } catch (e) {
      print('❌ Failed to import questions: $e');
      rethrow;
    }
  }

  /// Insert a single question with its answers
  Future<void> _insertQuestion({
    required String certificationId,
    required Map<String, dynamic> questionData,
  }) async {
    try {
      // Determine section ID from domain
      final domain = questionData['domain'] as String;
      final sectionId = domainMapping[domain] ?? 'security-principles';
      
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
      
    } catch (e) {
      print('❌ Failed to insert question: ${questionData['question']?.toString().substring(0, 50)}... - $e');
      rethrow;
    }
  }

  /// Import all questions from a directory
  Future<void> importQuestionsFromDirectory(String directoryPath, String certificationId) async {
    try {
      final directory = Directory(directoryPath);
      final files = directory.listSync()
          .where((file) => file.path.endsWith('.json'))
          .cast<File>();
      
      for (final file in files) {
        await importQuestionsFromFile(file.path, certificationId);
      }
      
    } catch (e) {
      print('❌ Failed to import from directory: $e');
      rethrow;
    }
  }

  /// Verify import results
  Future<void> verifyImport(String certificationId) async {
    try {
      print('🔍 Verifying import results...');
      
      // Check total questions
      final totalQuestions = await _supabase
          .from('questions')
          .select('id')
          .eq('certification_id', certificationId);
      
      print('📊 Total questions for $certificationId: ${totalQuestions.length}');
      
      // Check questions per section
      final sections = await _supabase
          .from('sections')
          .select('id, name')
          .eq('certification_id', certificationId);
      
      for (final section in sections) {
        final sectionQuestions = await _supabase
            .from('questions')
            .select('id')
            .eq('section_id', section['id']);
        
        print('  ${section['name']}: ${sectionQuestions.length} questions');
      }
      
    } catch (e) {
      print('❌ Verification failed: $e');
    }
  }
}

/// Example usage
Future<void> main() async {
  // Initialize Supabase (you'll need to set up your credentials)
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  
  final importer = QuestionImporter();
  
  try {
    // Import from a single file
    await importer.importQuestionsFromFile(
      'data/new_questions_template.json',
      'isc2-cc',
    );
    
    // Or import from a directory
    // await importer.importQuestionsFromDirectory(
    //   'data/CompTIA Security+/',
    //   'comptia-security-plus',
    // );
    
    // Verify the import
    await importer.verifyImport('isc2-cc');
    
  } catch (e) {
    print('Import failed: $e');
  }
}