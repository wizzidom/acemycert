import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/quiz.dart';
import '../core/constants.dart';

class DataLoaderService {
  static const Map<String, String> _isc2DataFiles = {
    'security-principles': 'data/ISC2\'s CC/Domain 1 -  Security Principles.json',
    'incident-response': 'data/ISC2\'s CC/Domain 2 - Business Continuity (BC), Disaster Recovery (DR) & Incident Response Concepts.json',
    'access-controls': 'data/ISC2\'s CC/Domain 3 -  Access Controls Concepts.json',
    'network-security': 'data/ISC2\'s CC/Domain 4 – Network Security.json',
    'security-operations': 'data/ISC2\'s CC/Domain 5 – Security Operations.json',
  };

  // Each domain has exactly 20 questions
  static const int _questionsPerDomain = 20;
  static const int _totalISC2Questions = 100; // 5 domains × 20 questions

  /// Load all ISC² CC questions from JSON files
  static Future<List<Question>> loadISC2Questions() async {
    List<Question> allQuestions = [];
    
    for (final entry in _isc2DataFiles.entries) {
      try {
        final questions = await _loadQuestionsFromFile(entry.value, entry.key);
        allQuestions.addAll(questions);
      } catch (e) {
        print('Error loading ${entry.value}: $e');
        // Continue loading other files even if one fails
      }
    }
    
    return allQuestions;
  }

  /// Load questions from a specific domain file
  static Future<List<Question>> loadQuestionsFromDomain(String sectionId) async {
    if (!_isc2DataFiles.containsKey(sectionId)) {
      throw Exception('Unknown section: $sectionId');
    }
    
    return await _loadQuestionsFromFile(_isc2DataFiles[sectionId]!, sectionId);
  }

  /// Load and parse questions from a JSON file
  static Future<List<Question>> _loadQuestionsFromFile(String filePath, String sectionId) async {
    try {
      final String jsonString = await rootBundle.loadString(filePath);
      final List<dynamic> jsonData = json.decode(jsonString);
      
      return jsonData.map((item) => _parseQuestionFromJson(item, sectionId)).toList();
    } catch (e) {
      throw Exception('Failed to load questions from $filePath: $e');
    }
  }

  /// Parse a single question from JSON format
  static Question _parseQuestionFromJson(Map<String, dynamic> json, String sectionId) {
    final options = json['options'] as Map<String, dynamic>;
    final correctAnswerKey = json['answer'] as String;
    
    // Convert options to Answer objects
    List<Answer> answers = [];
    String correctAnswerId = '';
    
    options.forEach((key, value) {
      final answerId = '${json['id']}_$key';
      final isCorrect = key == correctAnswerKey;
      
      answers.add(Answer(
        id: answerId,
        text: value as String,
        isCorrect: isCorrect,
      ));
      
      if (isCorrect) {
        correctAnswerId = answerId;
      }
    });

    return Question(
      id: 'isc2_${sectionId}_${json['id']}',
      text: json['question'] as String,
      answers: answers,
      correctAnswerId: correctAnswerId,
      explanation: json['explanation'] as String,
      sectionId: sectionId,
      certificationId: 'isc2-cc',
      difficulty: QuestionDifficulty.medium, // Default difficulty
    );
  }

  /// Get section information for ISC² CC (matches exact domain names from JSON)
  static Map<String, Map<String, dynamic>> getISC2Sections() {
    return {
      'security-principles': {
        'name': 'Security Principles',
        'description': 'Fundamental security concepts and principles (20 questions)',
        'file': _isc2DataFiles['security-principles']!,
      },
      'incident-response': {
        'name': 'Business Continuity, Disaster Recovery & Incident Response Concepts',
        'description': 'Incident response processes and business continuity (20 questions)',
        'file': _isc2DataFiles['incident-response']!,
      },
      'access-controls': {
        'name': 'Access Controls Concepts',
        'description': 'Access control concepts and implementation (20 questions)',
        'file': _isc2DataFiles['access-controls']!,
      },
      'network-security': {
        'name': 'Network Security',
        'description': 'Network security concepts and technologies (20 questions)',
        'file': _isc2DataFiles['network-security']!,
      },
      'security-operations': {
        'name': 'Security Operations',
        'description': 'Security operations and data security (20 questions)',
        'file': _isc2DataFiles['security-operations']!,
      },
    };
  }

  /// Get question counts for each section (20 questions per domain)
  static Map<String, int> getQuestionCounts() {
    Map<String, int> counts = {};
    
    for (final sectionId in _isc2DataFiles.keys) {
      counts[sectionId] = _questionsPerDomain;
    }
    
    return counts;
  }

  /// Get total number of ISC² CC questions
  static int getTotalQuestionCount() {
    return _totalISC2Questions;
  }
}