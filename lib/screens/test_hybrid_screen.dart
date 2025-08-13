// Test screen to verify hybrid local-first approach is working
// This can be accessed via a debug button to test instant updates

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../core/theme.dart';
import '../providers/quiz_data_provider.dart';
import '../providers/auth_provider.dart';
import '../models/quiz.dart';

class TestHybridScreen extends StatelessWidget {
  const TestHybridScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundDark,
        title: const Text('Test Hybrid System'),
        foregroundColor: AppTheme.textPrimary,
      ),
      body: Consumer2<AuthProvider, QuizDataProvider>(
        builder: (context, authProvider, quizDataProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'System Status',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        _buildStatusRow('User ID', authProvider.user?.id ?? 'Not logged in'),
                        _buildStatusRow('Provider Initialized', quizDataProvider.isInitialized ? 'Yes' : 'No'),
                        _buildStatusRow('Is Loading', quizDataProvider.isLoading ? 'Yes' : 'No'),
                        _buildStatusRow('Is Syncing', quizDataProvider.isSyncing ? 'Yes' : 'No'),
                        _buildStatusRow('Pending Sync', '${quizDataProvider.pendingSyncCount}'),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Current Stats Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Statistics',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        if (quizDataProvider.currentStats != null) ...[
                          _buildStatusRow('Total Quizzes', '${quizDataProvider.currentStats!.totalQuizzesCompleted}'),
                          _buildStatusRow('Average Score', '${quizDataProvider.currentStats!.averageScore.round()}%'),
                          _buildStatusRow('Best Score', '${quizDataProvider.currentStats!.bestScore.round()}%'),
                          _buildStatusRow('Study Time', _formatDuration(quizDataProvider.currentStats!.totalStudyTime)),
                        ] else
                          const Text('No statistics available'),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Test Actions
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Test Actions',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        
                        ElevatedButton.icon(
                          onPressed: () => _simulateQuizCompletion(context, quizDataProvider, authProvider),
                          icon:  Icon(MdiIcons.play),
                          label: const Text('Simulate Quiz Completion'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: AppTheme.textPrimary,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        ElevatedButton.icon(
                          onPressed: () => quizDataProvider.refresh(),
                          icon:  Icon(MdiIcons.refresh),
                          label: const Text('Refresh Data'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondaryTeal,
                            foregroundColor: AppTheme.textPrimary,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        ElevatedButton.icon(
                          onPressed: () => quizDataProvider.forceSync(),
                          icon:  Icon(MdiIcons.cloudUpload),
                          label: const Text('Force Sync'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentGreen,
                            foregroundColor: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Instructions
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Test Instructions',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '1. Click "Simulate Quiz Completion" to test instant updates\n'
                          '2. Watch the statistics update immediately\n'
                          '3. Check sync status to see background sync\n'
                          '4. Navigate to Profile/Dashboard to see real-time data',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  Future<void> _simulateQuizCompletion(
    BuildContext context,
    QuizDataProvider quizDataProvider,
    AuthProvider authProvider,
  ) async {
    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    // Create a mock quiz result
    final mockResult = QuizResult(
      quizId: 'test_${DateTime.now().millisecondsSinceEpoch}',
      correctAnswers: 8,
      totalQuestions: 10,
      scorePercentage: 80.0,
      questionResults: [], // Empty for test
      completedAt: DateTime.now(),
      timeTaken: const Duration(minutes: 5),
    );

    try {
      // This should update the UI instantly
      await quizDataProvider.saveQuizResult(
        mockResult,
        authProvider.user!.id,
        'isc2-cc',
        'ISC² CC',
        sectionId: 'security-principles',
        sectionName: 'Security Principles',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quiz result saved! Check stats for instant update.'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }
}