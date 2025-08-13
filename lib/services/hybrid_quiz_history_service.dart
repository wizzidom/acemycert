// Hybrid Quiz History Service - Local-first with background cloud sync
// This provides instant UI updates while syncing to Supabase in the background

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/quiz_history.dart';
import '../models/quiz.dart';
import '../repositories/quiz_history_repository.dart';
import '../repositories/hive_quiz_history_repository.dart';
import '../repositories/supabase_quiz_history_repository.dart';

class HybridQuizHistoryService extends ChangeNotifier {
  // Local storage for instant access
  final QuizHistoryRepository _localRepository = HiveQuizHistoryRepository();
  
  // Cloud storage for persistence and sync
  final QuizHistoryRepository _cloudRepository = SupabaseQuizHistoryRepository();
  
  // Cache for statistics to avoid recalculation
  final Map<String, QuizStatistics> _statsCache = {};
  final Map<String, List<QuizHistoryEntry>> _historyCache = {};
  
  // Sync queue for background operations
  final List<QuizHistoryEntry> _syncQueue = [];
  bool _isSyncing = false;
  
  // Stream controller for real-time updates
  final StreamController<QuizStatistics> _statsController = StreamController.broadcast();
  Stream<QuizStatistics> get statisticsStream => _statsController.stream;

  /// Save quiz result - instant local save + background cloud sync
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
    
    try {
      // 1. Save locally first (instant)
      await _localRepository.saveQuizResult(historyEntry);
      
      // 2. Update local cache
      _updateLocalCache(userId, historyEntry);
      
      // 3. Notify UI immediately
      final updatedStats = await _calculateStatistics(userId);
      _statsCache[userId] = updatedStats;
      _statsController.add(updatedStats);
      notifyListeners();
      
      // 4. Queue for background cloud sync
      _syncQueue.add(historyEntry);
      _syncToCloud();
      
    } catch (e) {
      print('Failed to save quiz result locally: $e');
      rethrow;
    }
  }

  /// Get quiz history - from local cache first, fallback to local storage
  Future<List<QuizHistoryEntry>> getQuizHistory(String userId) async {
    // Return cached data if available
    if (_historyCache.containsKey(userId)) {
      return _historyCache[userId]!;
    }
    
    try {
      // Load from local storage
      final history = await _localRepository.getQuizHistory(userId);
      _historyCache[userId] = history;
      return history;
    } catch (e) {
      print('Failed to get local quiz history: $e');
      return [];
    }
  }

  /// Get statistics - from cache first, calculate if needed
  Future<QuizStatistics> getStatistics(String userId, {String? certificationId}) async {
    final cacheKey = '${userId}_${certificationId ?? 'all'}';
    
    // Return cached stats if available and recent
    if (_statsCache.containsKey(cacheKey)) {
      return _statsCache[cacheKey]!;
    }
    
    // Calculate fresh statistics
    final stats = await _calculateStatistics(userId, certificationId: certificationId);
    _statsCache[cacheKey] = stats;
    return stats;
  }

  /// Calculate statistics from local data
  Future<QuizStatistics> _calculateStatistics(String userId, {String? certificationId}) async {
    try {
      final averageScore = await _localRepository.getAverageScore(userId, certificationId: certificationId);
      final bestScore = await _localRepository.getBestScore(userId, certificationId: certificationId);
      final totalQuizzes = await _localRepository.getTotalQuizzesCompleted(userId, certificationId: certificationId);
      final totalStudyTime = await _localRepository.getTotalStudyTime(userId, certificationId: certificationId);
      final recentQuizzes = await _localRepository.getRecentQuizzes(userId);
      
      Map<String, double> domainScores = {};
      if (certificationId != null) {
        domainScores = await _localRepository.getScoresByDomain(userId, certificationId);
      }

      return QuizStatistics(
        averageScore: averageScore,
        bestScore: bestScore,
        totalQuizzesCompleted: totalQuizzes,
        totalStudyTime: totalStudyTime,
        recentQuizzes: recentQuizzes,
        domainScores: domainScores,
      );
    } catch (e) {
      print('Failed to calculate statistics: $e');
      return QuizStatistics(
        averageScore: 0.0,
        bestScore: 0.0,
        totalQuizzesCompleted: 0,
        totalStudyTime: Duration.zero,
        recentQuizzes: [],
        domainScores: {},
      );
    }
  }

  /// Update local cache with new entry
  void _updateLocalCache(String userId, QuizHistoryEntry entry) {
    if (_historyCache.containsKey(userId)) {
      _historyCache[userId]!.insert(0, entry);
    }
    
    // Clear stats cache to force recalculation
    _statsCache.removeWhere((key, value) => key.startsWith(userId));
  }

  /// Background sync to cloud
  Future<void> _syncToCloud() async {
    if (_isSyncing || _syncQueue.isEmpty) return;
    
    _isSyncing = true;
    
    try {
      // Process sync queue
      final toSync = List<QuizHistoryEntry>.from(_syncQueue);
      _syncQueue.clear();
      
      for (final entry in toSync) {
        try {
          await _cloudRepository.saveQuizResult(entry);
          print('✅ Synced quiz result to cloud: ${entry.quizId}');
        } catch (e) {
          print('❌ Failed to sync quiz result: ${entry.quizId} - $e');
          // Re-queue failed items
          _syncQueue.add(entry);
        }
      }
    } catch (e) {
      print('Sync error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Force sync all local data to cloud (for app startup)
  Future<void> syncAllToCloud(String userId) async {
    try {
      print('🔄 Starting full sync to cloud...');
      
      // Get all local history
      final localHistory = await _localRepository.getQuizHistory(userId);
      
      // Get cloud history to compare
      List<QuizHistoryEntry> cloudHistory = [];
      try {
        cloudHistory = await _cloudRepository.getQuizHistory(userId);
      } catch (e) {
        print('Could not fetch cloud history: $e');
      }
      
      // Find entries that exist locally but not in cloud
      final cloudQuizIds = cloudHistory.map((e) => e.quizId).toSet();
      final toSync = localHistory.where((entry) => !cloudQuizIds.contains(entry.quizId)).toList();
      
      print('📤 Syncing ${toSync.length} entries to cloud...');
      
      for (final entry in toSync) {
        try {
          await _cloudRepository.saveQuizResult(entry);
        } catch (e) {
          print('Failed to sync entry ${entry.quizId}: $e');
        }
      }
      
      print('✅ Full sync completed');
    } catch (e) {
      print('Full sync failed: $e');
    }
  }

  /// Sync from cloud to local (for app startup)
  Future<void> syncFromCloud(String userId) async {
    try {
      print('🔄 Starting sync from cloud...');
      
      // Get cloud history
      final cloudHistory = await _cloudRepository.getQuizHistory(userId);
      
      // Get local history to compare
      final localHistory = await _localRepository.getQuizHistory(userId);
      final localQuizIds = localHistory.map((e) => e.quizId).toSet();
      
      // Find entries that exist in cloud but not locally
      final toDownload = cloudHistory.where((entry) => !localQuizIds.contains(entry.quizId)).toList();
      
      print('📥 Downloading ${toDownload.length} entries from cloud...');
      
      for (final entry in toDownload) {
        try {
          await _localRepository.saveQuizResult(entry);
        } catch (e) {
          print('Failed to save cloud entry locally ${entry.quizId}: $e');
        }
      }
      
      // Clear caches to force refresh
      _historyCache.clear();
      _statsCache.clear();
      
      print('✅ Cloud sync completed');
    } catch (e) {
      print('Cloud sync failed: $e');
    }
  }

  /// Initialize service - sync data on app startup
  Future<void> initialize(String userId) async {
    try {
      // First sync from cloud (get any data from other devices)
      await syncFromCloud(userId);
      
      // Then sync to cloud (upload any local-only data)
      await syncAllToCloud(userId);
      
      // Load initial statistics
      final stats = await getStatistics(userId);
      _statsController.add(stats);
      
    } catch (e) {
      print('Failed to initialize hybrid service: $e');
    }
  }

  /// Clear all caches (useful for logout)
  void clearCaches() {
    _historyCache.clear();
    _statsCache.clear();
    _syncQueue.clear();
  }

  /// Get sync status
  bool get isSyncing => _isSyncing;
  int get pendingSyncCount => _syncQueue.length;

  @override
  void dispose() {
    _statsController.close();
    super.dispose();
  }

  // Delegate methods for compatibility
  Future<List<QuizHistoryEntry>> getQuizHistoryByCertification(String userId, String certificationId) async {
    return await _localRepository.getQuizHistoryByCertification(userId, certificationId);
  }

  Future<QuizHistoryEntry?> getLatestQuiz(String userId) async {
    return await _localRepository.getLatestQuiz(userId);
  }

  Future<void> clearHistory(String userId) async {
    await _localRepository.clearAllHistory(userId);
    _historyCache.remove(userId);
    _statsCache.removeWhere((key, value) => key.startsWith(userId));
    notifyListeners();
  }
}

/// Statistics model (same as before but with caching support)
class QuizStatistics {
  final double averageScore;
  final double bestScore;
  final int totalQuizzesCompleted;
  final Duration totalStudyTime;
  final List<QuizHistoryEntry> recentQuizzes;
  final Map<String, double> domainScores;
  final DateTime calculatedAt;

  QuizStatistics({
    required this.averageScore,
    required this.bestScore,
    required this.totalQuizzesCompleted,
    required this.totalStudyTime,
    required this.recentQuizzes,
    required this.domainScores,
    DateTime? calculatedAt,
  }) : calculatedAt = calculatedAt ?? DateTime.now();

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

  bool get isStale => DateTime.now().difference(calculatedAt).inMinutes > 5;
}