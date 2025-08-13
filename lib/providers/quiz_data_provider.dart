// Quiz Data Provider - Manages local-first data with background sync
// Provides reactive state management for quiz statistics and history

import 'package:flutter/foundation.dart';
import '../services/hybrid_quiz_history_service.dart';
import '../models/quiz_history.dart';
import '../models/quiz.dart';

class QuizDataProvider extends ChangeNotifier {
  final HybridQuizHistoryService _hybridService = HybridQuizHistoryService();
  
  // Current state
  QuizStatistics? _currentStats;
  List<QuizHistoryEntry> _currentHistory = [];
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _currentUserId;

  // Getters
  QuizStatistics? get currentStats => _currentStats;
  List<QuizHistoryEntry> get currentHistory => _currentHistory;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get isSyncing => _hybridService.isSyncing;
  int get pendingSyncCount => _hybridService.pendingSyncCount;

  QuizDataProvider() {
    // Listen to hybrid service changes
    _hybridService.addListener(_onHybridServiceUpdate);
    _hybridService.statisticsStream.listen(_onStatisticsUpdate);
  }

  /// Initialize for a user - call this on app startup or login
  Future<void> initialize(String userId) async {
    if (_currentUserId == userId && _isInitialized) return;
    
    _currentUserId = userId;
    _isLoading = true;
    notifyListeners();

    try {
      // Initialize hybrid service (syncs data)
      await _hybridService.initialize(userId);
      
      // Load initial data
      await _loadUserData(userId);
      
      _isInitialized = true;
    } catch (e) {
      print('Failed to initialize quiz data provider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load user data from local storage (fast)
  Future<void> _loadUserData(String userId) async {
    try {
      // Load statistics and history in parallel
      final futures = await Future.wait([
        _hybridService.getStatistics(userId),
        _hybridService.getQuizHistory(userId),
      ]);
      
      _currentStats = futures[0] as QuizStatistics;
      _currentHistory = futures[1] as List<QuizHistoryEntry>;
      
      notifyListeners();
    } catch (e) {
      print('Failed to load user data: $e');
    }
  }

  /// Save quiz result - instant UI update + background sync
  Future<void> saveQuizResult(
    QuizResult result,
    String userId,
    String certificationId,
    String certificationName, {
    String? sectionId,
    String? sectionName,
  }) async {
    try {
      await _hybridService.saveQuizResult(
        result,
        userId,
        certificationId,
        certificationName,
        sectionId: sectionId,
        sectionName: sectionName,
      );
      
      // Data will be updated automatically via listeners
    } catch (e) {
      print('Failed to save quiz result: $e');
      rethrow;
    }
  }

  /// Refresh data (pull-to-refresh)
  Future<void> refresh() async {
    if (_currentUserId == null) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      await _loadUserData(_currentUserId!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Force sync with cloud
  Future<void> forceSync() async {
    if (_currentUserId == null) return;
    
    try {
      await _hybridService.syncAllToCloud(_currentUserId!);
      await _loadUserData(_currentUserId!);
    } catch (e) {
      print('Failed to force sync: $e');
    }
  }

  /// Get statistics for specific certification
  Future<QuizStatistics> getStatisticsForCertification(String certificationId) async {
    if (_currentUserId == null) {
      throw Exception('User not initialized');
    }
    
    return await _hybridService.getStatistics(_currentUserId!, certificationId: certificationId);
  }

  /// Get history for specific certification
  Future<List<QuizHistoryEntry>> getHistoryForCertification(String certificationId) async {
    if (_currentUserId == null) {
      throw Exception('User not initialized');
    }
    
    return await _hybridService.getQuizHistoryByCertification(_currentUserId!, certificationId);
  }

  /// Clear all data (logout)
  void clear() {
    _currentStats = null;
    _currentHistory = [];
    _isInitialized = false;
    _isLoading = false;
    _currentUserId = null;
    _hybridService.clearCaches();
    notifyListeners();
  }

  /// Handle hybrid service updates
  void _onHybridServiceUpdate() {
    notifyListeners();
  }

  /// Handle statistics stream updates
  void _onStatisticsUpdate(QuizStatistics stats) {
    _currentStats = stats;
    notifyListeners();
  }

  @override
  void dispose() {
    _hybridService.removeListener(_onHybridServiceUpdate);
    _hybridService.dispose();
    super.dispose();
  }
}