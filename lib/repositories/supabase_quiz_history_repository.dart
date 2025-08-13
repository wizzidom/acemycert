import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/quiz_history.dart';
import 'quiz_history_repository.dart';

class SupabaseQuizHistoryRepository implements QuizHistoryRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<void> saveQuizResult(QuizHistoryEntry entry) async {
    try {
      // Insert quiz history record
      await _supabase
          .from('quiz_history')
          .insert({
            'user_id': entry.userId,
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
          });

      // Note: Detailed question results would be inserted here if we had them
      // For now, we're just storing the overall quiz results
      
    } catch (e) {
      throw Exception('Failed to save quiz result: $e');
    }
  }

  @override
  Future<List<QuizHistoryEntry>> getQuizHistory(String userId) async {
    try {
      final response = await _supabase
          .from('quiz_history')
          .select('*')
          .eq('user_id', userId)
          .order('completed_at', ascending: false);

      return response.map((data) => _mapToQuizHistoryEntry(data)).toList();
    } catch (e) {
      throw Exception('Failed to get quiz history: $e');
    }
  }

  @override
  Future<List<QuizHistoryEntry>> getQuizHistoryByCertification(String userId, String certificationId) async {
    try {
      final response = await _supabase
          .from('quiz_history')
          .select('*')
          .eq('user_id', userId)
          .eq('certification_id', certificationId)
          .order('completed_at', ascending: false);

      return response.map((data) => _mapToQuizHistoryEntry(data)).toList();
    } catch (e) {
      throw Exception('Failed to get quiz history by certification: $e');
    }
  }

  @override
  Future<List<QuizHistoryEntry>> getQuizHistoryBySection(String userId, String certificationId, String sectionId) async {
    try {
      final response = await _supabase
          .from('quiz_history')
          .select('*')
          .eq('user_id', userId)
          .eq('certification_id', certificationId)
          .eq('section_id', sectionId)
          .order('completed_at', ascending: false);

      return response.map((data) => _mapToQuizHistoryEntry(data)).toList();
    } catch (e) {
      throw Exception('Failed to get quiz history by section: $e');
    }
  }

  @override
  Future<QuizHistoryEntry?> getLatestQuiz(String userId) async {
    try {
      final response = await _supabase
          .from('quiz_history')
          .select('*')
          .eq('user_id', userId)
          .order('completed_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response != null ? _mapToQuizHistoryEntry(response) : null;
    } catch (e) {
      throw Exception('Failed to get latest quiz: $e');
    }
  }

  @override
  Future<void> deleteQuizHistory(String quizId) async {
    try {
      await _supabase
          .from('quiz_history')
          .delete()
          .eq('quiz_id', quizId);
    } catch (e) {
      throw Exception('Failed to delete quiz history: $e');
    }
  }

  @override
  Future<void> clearAllHistory(String userId) async {
    try {
      await _supabase
          .from('quiz_history')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to clear all history: $e');
    }
  }

  @override
  Future<double> getAverageScore(String userId, {String? certificationId}) async {
    try {
      var query = _supabase
          .from('quiz_history')
          .select('score_percentage')
          .eq('user_id', userId);

      if (certificationId != null) {
        query = query.eq('certification_id', certificationId);
      }

      final response = await query;
      
      if (response.isEmpty) return 0.0;
      
      final scores = response.map((data) => data['score_percentage'] as double).toList();
      return scores.reduce((a, b) => a + b) / scores.length;
    } catch (e) {
      throw Exception('Failed to get average score: $e');
    }
  }

  @override
  Future<double> getBestScore(String userId, {String? certificationId}) async {
    try {
      var query = _supabase
          .from('quiz_history')
          .select('score_percentage')
          .eq('user_id', userId);

      if (certificationId != null) {
        query = query.eq('certification_id', certificationId);
      }

      final response = await query.order('score_percentage', ascending: false).limit(1).maybeSingle();
      
      return response?['score_percentage']?.toDouble() ?? 0.0;
    } catch (e) {
      throw Exception('Failed to get best score: $e');
    }
  }

  @override
  Future<int> getTotalQuizzesCompleted(String userId, {String? certificationId}) async {
    try {
      var query = _supabase
          .from('quiz_history')
          .select('id')
          .eq('user_id', userId);

      if (certificationId != null) {
        query = query.eq('certification_id', certificationId);
      }

      final response = await query;
      return response.length;
    } catch (e) {
      throw Exception('Failed to get total quizzes completed: $e');
    }
  }

  @override
  Future<Duration> getTotalStudyTime(String userId, {String? certificationId}) async {
    try {
      var query = _supabase
          .from('quiz_history')
          .select('time_taken_seconds')
          .eq('user_id', userId);

      if (certificationId != null) {
        query = query.eq('certification_id', certificationId);
      }

      final response = await query;
      
      if (response.isEmpty) return Duration.zero;
      
      final totalSeconds = response
          .map((data) => data['time_taken_seconds'] as int)
          .reduce((a, b) => a + b);
      
      return Duration(seconds: totalSeconds);
    } catch (e) {
      throw Exception('Failed to get total study time: $e');
    }
  }

  @override
  Future<Map<String, double>> getScoresByDomain(String userId, String certificationId) async {
    try {
      final response = await _supabase
          .from('quiz_history')
          .select('section_id, score_percentage')
          .eq('user_id', userId)
          .eq('certification_id', certificationId)
          .not('section_id', 'is', null);

      final Map<String, List<double>> domainScores = {};
      
      for (final data in response) {
        final sectionId = data['section_id'] as String;
        final score = data['score_percentage'] as double;
        
        domainScores.putIfAbsent(sectionId, () => []).add(score);
      }
      
      // Calculate average score per domain
      final Map<String, double> averageScores = {};
      domainScores.forEach((domain, scores) {
        averageScores[domain] = scores.reduce((a, b) => a + b) / scores.length;
      });
      
      return averageScores;
    } catch (e) {
      throw Exception('Failed to get scores by domain: $e');
    }
  }

  @override
  Future<List<QuizHistoryEntry>> getRecentQuizzes(String userId, {int limit = 10}) async {
    try {
      final response = await _supabase
          .from('quiz_history')
          .select('*')
          .eq('user_id', userId)
          .order('completed_at', ascending: false)
          .limit(limit);

      return response.map((data) => _mapToQuizHistoryEntry(data)).toList();
    } catch (e) {
      throw Exception('Failed to get recent quizzes: $e');
    }
  }

  /// Map Supabase response to QuizHistoryEntry
  QuizHistoryEntry _mapToQuizHistoryEntry(Map<String, dynamic> data) {
    return QuizHistoryEntry(
      quizId: data['quiz_id'] as String,
      userId: data['user_id'] as String,
      certificationId: data['certification_id'] as String,
      certificationName: data['certification_name'] as String,
      sectionId: data['section_id'] as String?,
      sectionName: data['section_name'] as String?,
      scorePercentage: (data['score_percentage'] as num).toDouble(),
      correctAnswers: data['correct_answers'] as int,
      totalQuestions: data['total_questions'] as int,
      timeTakenSeconds: data['time_taken_seconds'] as int,
      completedAt: DateTime.parse(data['completed_at'] as String),
    );
  }
}