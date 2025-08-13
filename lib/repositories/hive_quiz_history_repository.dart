import 'package:hive/hive.dart';
import '../models/quiz_history.dart';
import 'quiz_history_repository.dart';

class HiveQuizHistoryRepository implements QuizHistoryRepository {
  static const String _boxName = 'quiz_history';
  
  Box<QuizHistoryEntry>? _box;
  
  Future<Box<QuizHistoryEntry>> get _historyBox async {
    _box ??= await Hive.openBox<QuizHistoryEntry>(_boxName);
    return _box!;
  }

  @override
  Future<void> saveQuizResult(QuizHistoryEntry entry) async {
    final box = await _historyBox;
    await box.add(entry);
  }

  @override
  Future<List<QuizHistoryEntry>> getQuizHistory(String userId) async {
    final box = await _historyBox;
    return box.values
        .where((entry) => entry.userId == userId)
        .toList()
        ..sort((a, b) => b.completedAt.compareTo(a.completedAt)); // Most recent first
  }

  @override
  Future<List<QuizHistoryEntry>> getQuizHistoryByCertification(String userId, String certificationId) async {
    final box = await _historyBox;
    return box.values
        .where((entry) => entry.userId == userId && entry.certificationId == certificationId)
        .toList()
        ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }

  @override
  Future<List<QuizHistoryEntry>> getQuizHistoryBySection(String userId, String certificationId, String sectionId) async {
    final box = await _historyBox;
    return box.values
        .where((entry) => 
            entry.userId == userId && 
            entry.certificationId == certificationId && 
            entry.sectionId == sectionId)
        .toList()
        ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }

  @override
  Future<QuizHistoryEntry?> getLatestQuiz(String userId) async {
    final history = await getQuizHistory(userId);
    return history.isNotEmpty ? history.first : null;
  }

  @override
  Future<void> deleteQuizHistory(String quizId) async {
    final box = await _historyBox;
    final entry = box.values.firstWhere((entry) => entry.quizId == quizId);
    await entry.delete();
  }

  @override
  Future<void> clearAllHistory(String userId) async {
    final box = await _historyBox;
    final userEntries = box.values.where((entry) => entry.userId == userId).toList();
    for (final entry in userEntries) {
      await entry.delete();
    }
  }

  @override
  Future<double> getAverageScore(String userId, {String? certificationId}) async {
    final history = certificationId != null
        ? await getQuizHistoryByCertification(userId, certificationId)
        : await getQuizHistory(userId);
    
    if (history.isEmpty) return 0.0;
    
    final totalScore = history.fold<double>(0.0, (sum, entry) => sum + entry.scorePercentage);
    return totalScore / history.length;
  }

  @override
  Future<double> getBestScore(String userId, {String? certificationId}) async {
    final history = certificationId != null
        ? await getQuizHistoryByCertification(userId, certificationId)
        : await getQuizHistory(userId);
    
    if (history.isEmpty) return 0.0;
    
    return history.map((entry) => entry.scorePercentage).reduce((a, b) => a > b ? a : b);
  }

  @override
  Future<int> getTotalQuizzesCompleted(String userId, {String? certificationId}) async {
    final history = certificationId != null
        ? await getQuizHistoryByCertification(userId, certificationId)
        : await getQuizHistory(userId);
    
    return history.length;
  }

  @override
  Future<Duration> getTotalStudyTime(String userId, {String? certificationId}) async {
    final history = certificationId != null
        ? await getQuizHistoryByCertification(userId, certificationId)
        : await getQuizHistory(userId);
    
    final totalSeconds = history.fold<int>(0, (sum, entry) => sum + entry.timeTakenSeconds);
    return Duration(seconds: totalSeconds);
  }

  @override
  Future<Map<String, double>> getScoresByDomain(String userId, String certificationId) async {
    final history = await getQuizHistoryByCertification(userId, certificationId);
    final Map<String, List<double>> domainScores = {};
    
    for (final entry in history) {
      if (entry.sectionId != null) {
        domainScores.putIfAbsent(entry.sectionId!, () => []).add(entry.scorePercentage);
      }
    }
    
    // Calculate average score per domain
    final Map<String, double> averageScores = {};
    domainScores.forEach((domain, scores) {
      averageScores[domain] = scores.reduce((a, b) => a + b) / scores.length;
    });
    
    return averageScores;
  }

  @override
  Future<List<QuizHistoryEntry>> getRecentQuizzes(String userId, {int limit = 10}) async {
    final history = await getQuizHistory(userId);
    return history.take(limit).toList();
  }
}