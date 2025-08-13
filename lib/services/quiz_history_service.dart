import '../models/quiz_history.dart';
import '../models/quiz.dart';
import '../repositories/quiz_history_repository.dart';
import '../repositories/supabase_quiz_history_repository.dart';

class QuizHistoryService {
  // Use Supabase repository for cloud storage
  final QuizHistoryRepository _repository = SupabaseQuizHistoryRepository();
  
  /// Save a completed quiz to history
  Future<void> saveQuizResult(
    QuizResult result,
    String userId,
    String certificationId,
    String certificationName, {
    String? sectionId,
    String? sectionName,
  }) async {
    final historyEntry = QuizHistoryEntry.fromQuizResult(
      result,
      userId,
      certificationId,
      certificationName,
      sectionId: sectionId,
      sectionName: sectionName,
    );
    
    await _repository.saveQuizResult(historyEntry);
  }

  /// Get all quiz history for a user
  Future<List<QuizHistoryEntry>> getQuizHistory(String userId) async {
    return await _repository.getQuizHistory(userId);
  }

  /// Get quiz history for a specific certification
  Future<List<QuizHistoryEntry>> getQuizHistoryByCertification(
    String userId,
    String certificationId,
  ) async {
    return await _repository.getQuizHistoryByCertification(userId, certificationId);
  }

  /// Get the user's latest quiz
  Future<QuizHistoryEntry?> getLatestQuiz(String userId) async {
    return await _repository.getLatestQuiz(userId);
  }

  /// Get user statistics
  Future<QuizStatistics> getStatistics(String userId, {String? certificationId}) async {
    final averageScore = await _repository.getAverageScore(userId, certificationId: certificationId);
    final bestScore = await _repository.getBestScore(userId, certificationId: certificationId);
    final totalQuizzes = await _repository.getTotalQuizzesCompleted(userId, certificationId: certificationId);
    final totalStudyTime = await _repository.getTotalStudyTime(userId, certificationId: certificationId);
    final recentQuizzes = await _repository.getRecentQuizzes(userId);
    
    Map<String, double> domainScores = {};
    if (certificationId != null) {
      domainScores = await _repository.getScoresByDomain(userId, certificationId);
    }

    return QuizStatistics(
      averageScore: averageScore,
      bestScore: bestScore,
      totalQuizzesCompleted: totalQuizzes,
      totalStudyTime: totalStudyTime,
      recentQuizzes: recentQuizzes,
      domainScores: domainScores,
    );
  }

  /// Clear all history for a user
  Future<void> clearHistory(String userId) async {
    await _repository.clearAllHistory(userId);
  }

  /// Get performance trend (last 10 quizzes)
  Future<List<double>> getPerformanceTrend(String userId, {String? certificationId}) async {
    final history = certificationId != null
        ? await _repository.getQuizHistoryByCertification(userId, certificationId)
        : await _repository.getQuizHistory(userId);
    
    // Get last 10 quizzes in chronological order
    final recentQuizzes = history.reversed.take(10).toList();
    return recentQuizzes.map((quiz) => quiz.scorePercentage).toList();
  }

  /// Check if user has improved recently
  Future<bool> hasImprovedRecently(String userId, {String? certificationId}) async {
    final trend = await getPerformanceTrend(userId, certificationId: certificationId);
    if (trend.length < 3) return false;
    
    // Compare last 3 quizzes with previous 3
    final recent = trend.sublist(trend.length - 3);
    final previous = trend.sublist(0, trend.length - 3);
    
    final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
    final previousAvg = previous.reduce((a, b) => a + b) / previous.length;
    
    return recentAvg > previousAvg;
  }
}

/// Statistics model for quiz performance
class QuizStatistics {
  final double averageScore;
  final double bestScore;
  final int totalQuizzesCompleted;
  final Duration totalStudyTime;
  final List<QuizHistoryEntry> recentQuizzes;
  final Map<String, double> domainScores;

  QuizStatistics({
    required this.averageScore,
    required this.bestScore,
    required this.totalQuizzesCompleted,
    required this.totalStudyTime,
    required this.recentQuizzes,
    required this.domainScores,
  });

  String get averageGrade {
    if (averageScore >= 90) return 'A';
    if (averageScore >= 80) return 'B';
    if (averageScore >= 70) return 'C';
    if (averageScore >= 60) return 'D';
    return 'F';
  }

  String get bestGrade {
    if (bestScore >= 90) return 'A';
    if (bestScore >= 80) return 'B';
    if (bestScore >= 70) return 'C';
    if (bestScore >= 60) return 'D';
    return 'F';
  }

  double get passingRate {
    if (recentQuizzes.isEmpty) return 0.0;
    final passingQuizzes = recentQuizzes.where((quiz) => quiz.isPassing).length;
    return (passingQuizzes / recentQuizzes.length) * 100;
  }
}