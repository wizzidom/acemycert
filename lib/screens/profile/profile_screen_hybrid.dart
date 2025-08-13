// Example of how to update profile screen to use hybrid local-first approach
// This shows the pattern for instant updates with background sync

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/quiz_data_provider.dart';
import '../../services/hybrid_quiz_history_service.dart';
import '../../widgets/custom_button.dart';
import '../../models/quiz_history.dart';

class ProfileScreenHybrid extends StatefulWidget {
  const ProfileScreenHybrid({super.key});

  @override
  State<ProfileScreenHybrid> createState() => _ProfileScreenHybridState();
}

class _ProfileScreenHybridState extends State<ProfileScreenHybrid> {
  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final authProvider = context.read<AuthProvider>();
    final quizDataProvider = context.read<QuizDataProvider>();
    
    if (authProvider.user != null && !quizDataProvider.isInitialized) {
      await quizDataProvider.initialize(authProvider.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundDark,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        automaticallyImplyLeading: false,
        actions: [
          // Sync indicator
          Consumer<QuizDataProvider>(
            builder: (context, quizData, child) {
              if (quizData.isSyncing) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer2<AuthProvider, QuizDataProvider>(
        builder: (context, authProvider, quizDataProvider, child) {
          final user = authProvider.user;
          
          if (user == null) {
            return const Center(
              child: Text(
                'User not found',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
            );
          }

          // Show loading only on first load
          if (quizDataProvider.isLoading && !quizDataProvider.isInitialized) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          return SafeArea(
            child: RefreshIndicator(
              onRefresh: () => quizDataProvider.refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildProfileHeader(user),
                    const SizedBox(height: 24),
                    _buildStatsSection(quizDataProvider.currentStats),
                    const SizedBox(height: 24),
                    _buildAchievementsSection(quizDataProvider.currentStats),
                    const SizedBox(height: 24),
                    _buildSyncStatus(quizDataProvider),
                    const SizedBox(height: 24),
                    _buildSettingsSection(),
                    const SizedBox(height: 32),
                    _buildLogoutButton(authProvider),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsSection(QuizStatistics? statistics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  MdiIcons.chartLine,
                  color: AppTheme.accentGreen,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Your Statistics',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 20,
                  ),
                ),
                const Spacer(),
                // Real-time update indicator
                if (statistics != null && !statistics.isStale)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Live',
                      style: TextStyle(
                        color: AppTheme.successGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Stats Grid - Real-time data
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: MdiIcons.fire,
                    label: 'Current Streak',
                    value: _calculateStreak(statistics?.recentQuizzes ?? []),
                    color: AppTheme.errorRed,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    icon: MdiIcons.helpCircle,
                    label: 'Questions Answered',
                    value: '${(statistics?.totalQuizzesCompleted ?? 0) * 10}',
                    color: AppTheme.secondaryTeal,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: MdiIcons.checkCircle,
                    label: 'Quizzes Completed',
                    value: '${statistics?.totalQuizzesCompleted ?? 0}',
                    color: AppTheme.successGreen,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    icon: MdiIcons.clockOutline,
                    label: 'Study Time',
                    value: _formatDuration(statistics?.totalStudyTime ?? Duration.zero),
                    color: AppTheme.accentGreen,
                  ),
                ),
              ],
            ),
            
            if (statistics != null && statistics.averageScore > 0) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      icon: MdiIcons.trendingUp,
                      label: 'Average Score',
                      value: '${statistics.averageScore.round()}%',
                      color: AppTheme.secondaryTeal,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatItem(
                      icon: MdiIcons.trophy,
                      label: 'Best Score',
                      value: '${statistics.bestScore.round()}%',
                      color: AppTheme.accentGreen,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatus(QuizDataProvider quizDataProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  MdiIcons.cloudSync,
                  color: AppTheme.secondaryTeal,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Sync Status',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Icon(
                  quizDataProvider.isSyncing ? MdiIcons.send : MdiIcons.checkCircle,
                  color: quizDataProvider.isSyncing ? AppTheme.accentGreen : AppTheme.successGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  quizDataProvider.isSyncing ? 'Syncing...' : 'All data synced',
                  style: TextStyle(
                    color: quizDataProvider.isSyncing ? AppTheme.accentGreen : AppTheme.successGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (quizDataProvider.pendingSyncCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${quizDataProvider.pendingSyncCount} pending',
                      style: const TextStyle(
                        color: AppTheme.accentGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            
            if (quizDataProvider.pendingSyncCount > 0) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => quizDataProvider.forceSync(),
                icon:  Icon(MdiIcons.cloudUpload, size: 16),
                label: const Text('Force Sync'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: AppTheme.textPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ... other methods remain the same as original profile screen ...
  
  Widget _buildProfileHeader(user) {
    // Same as original implementation
    return Container(); // Placeholder
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    // Same as original implementation
    return Container(); // Placeholder
  }

  Widget _buildAchievementsSection(QuizStatistics? statistics) {
    // Same as original implementation but using statistics parameter
    return Container(); // Placeholder
  }

  Widget _buildSettingsSection() {
    // Same as original implementation
    return Container(); // Placeholder
  }

  Widget _buildLogoutButton(AuthProvider authProvider) {
    // Same as original implementation
    return Container(); // Placeholder
  }

  String _calculateStreak(List<QuizHistoryEntry> recentQuizzes) {
    return _calculateStreakFromStats(recentQuizzes).toString();
  }

  int _calculateStreakFromStats(List<QuizHistoryEntry> recentQuizzes) {
    // Same implementation as original
    return 0; // Placeholder
  }

  String _formatDuration(Duration duration) {
    // Same implementation as original
    return '0m'; // Placeholder
  }
}