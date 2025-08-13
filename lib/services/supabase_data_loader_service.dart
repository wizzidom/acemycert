import 'package:cybersecurity_quiz_platform/core/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/quiz.dart';

class SupabaseDataLoaderService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Load all ISC² CC questions from Supabase
  Future<List<Question>> loadISC2Questions() async {
    try {
      final response = await _supabase
          .from('questions_with_answers')
          .select('*')
          .eq('certification_id', 'isc2-cc');

      return response.map((data) => _mapToQuestion(data)).toList();
    } catch (e) {
      throw Exception('Failed to load ISC² CC questions: $e');
    }
  }

  /// Load questions from a specific domain/section
  Future<List<Question>> loadQuestionsFromDomain(String sectionId) async {
    try {
      final response = await _supabase
          .from('questions_with_answers')
          .select('*')
          .eq('certification_id', 'isc2-cc')
          .eq('section_id', sectionId);

      return response.map((data) => _mapToQuestion(data)).toList();
    } catch (e) {
      throw Exception('Failed to load questions from domain $sectionId: $e');
    }
  }

  /// Get question counts for each section
  Future<Map<String, int>> getQuestionCounts() async {
    try {
      final response = await _supabase
          .from('sections')
          .select('id, question_count')
          .eq('certification_id', 'isc2-cc');

      final Map<String, int> counts = {};
      for (final data in response) {
        counts[data['id'] as String] = data['question_count'] as int;
      }

      return counts;
    } catch (e) {
      throw Exception('Failed to get question counts: $e');
    }
  }

  /// Get total question count for ISC² CC
  Future<int> getTotalQuestionCount() async {
    try {
      final response = await _supabase
          .from('questions')
          .select('*')
          .eq('certification_id', 'isc2-cc');

      return response.length;
    } catch (e) {
      throw Exception('Failed to get total question count: $e');
    }
  }

  /// Get ISC² CC section information
  Future<Map<String, Map<String, String>>> getISC2Sections() async {
    try {
      final response = await _supabase
          .from('sections')
          .select('id, name, description')
          .eq('certification_id', 'isc2-cc')
          .order('order_index');

      final Map<String, Map<String, String>> sections = {};
      for (final data in response) {
        sections[data['id'] as String] = {
          'name': data['name'] as String,
          'description': data['description'] as String,
        };
      }

      return sections;
    } catch (e) {
      throw Exception('Failed to get ISC² CC sections: $e');
    }
  }

  /// Load certifications from Supabase
  Future<List<Map<String, dynamic>>> loadCertifications() async {
    try {
      final response = await _supabase
          .from('certifications')
          .select('*')
          .eq('is_active', true)
          .order('name');

      return response;
    } catch (e) {
      throw Exception('Failed to load certifications: $e');
    }
  }

  /// Load sections for a certification
  Future<List<Map<String, dynamic>>> loadSections(
      String certificationId) async {
    try {
      final response = await _supabase
          .from('sections')
          .select('*')
          .eq('certification_id', certificationId)
          .eq('is_active', true)
          .order('order_index');

      return response;
    } catch (e) {
      throw Exception('Failed to load sections for $certificationId: $e');
    }
  }

  /// Map Supabase question data to Question model
  Question _mapToQuestion(Map<String, dynamic> data) {
    final answersData = data['answers'] as List<dynamic>;
    final answers =
        answersData.map((answerData) => _mapToAnswer(answerData)).toList();

    // Find the correct answer ID
    final correctAnswer = answers.firstWhere((answer) => answer.isCorrect);

    return Question(
      id: data['question_id'] as String,
      text: data['question_text'] as String,
      answers: answers,
      correctAnswerId: correctAnswer.id,
      explanation: data['explanation'] as String,
      sectionId: data['section_id'] as String,
      certificationId: data['certification_id'] as String,
      difficulty: _mapDifficulty(data['difficulty_level'] as String?),
    );
  }

  /// Map Supabase answer data to Answer model
  Answer _mapToAnswer(Map<String, dynamic> data) {
    return Answer(
      id: data['id'] as String,
      text: data['text'] as String,
      isCorrect: data['isCorrect'] as bool,
    );
  }

  /// Map difficulty string to enum
  QuestionDifficulty _mapDifficulty(String? difficulty) {
    switch (difficulty?.toLowerCase()) {
      case 'easy':
        return QuestionDifficulty.easy;
      case 'hard':
        return QuestionDifficulty.hard;
      case 'medium':
      default:
        return QuestionDifficulty.medium;
    }
  }

  /// Check if Supabase connection is working
  Future<bool> testConnection() async {
    try {
      await _supabase.from('certifications').select('id').limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get database statistics
  Future<Map<String, int>> getDatabaseStats() async {
    try {
      final certifications =
          await _supabase.from('certifications').select('id');

      final questions = await _supabase.from('questions').select('id');

      final users = await _supabase.from('user_profiles').select('id');

      final quizHistory = await _supabase.from('quiz_history').select('id');

      return {
        'certifications': certifications.length,
        'questions': questions.length,
        'users': users.length,
        'quiz_history': quizHistory.length,
      };
    } catch (e) {
      throw Exception('Failed to get database stats: $e');
    }
  }
}
