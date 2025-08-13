import '../models/quiz_history.dart';

/// Abstract repository for quiz history data
/// This allows easy switching between Hive (local) and Supabase (cloud) storage
abstract class QuizHistoryRepository {
  Future<void> saveQuizResult(QuizHistoryEntry entry);
  Future<List<QuizHistoryEntry>> getQuizHistory(String userId);
  Future<List<QuizHistoryEntry>> getQuizHistoryByCertification(String userId, String certificationId);
  Future<List<QuizHistoryEntry>> getQuizHistoryBySection(String userId, String certificationId, String sectionId);
  Future<QuizHistoryEntry?> getLatestQuiz(String userId);
  Future<void> deleteQuizHistory(String quizId);
  Future<void> clearAllHistory(String userId);
  
  // Analytics methods
  Future<double> getAverageScore(String userId, {String? certificationId});
  Future<double> getBestScore(String userId, {String? certificationId});
  Future<int> getTotalQuizzesCompleted(String userId, {String? certificationId});
  Future<Duration> getTotalStudyTime(String userId, {String? certificationId});
  Future<Map<String, double>> getScoresByDomain(String userId, String certificationId);
  Future<List<QuizHistoryEntry>> getRecentQuizzes(String userId, {int limit = 10});
}