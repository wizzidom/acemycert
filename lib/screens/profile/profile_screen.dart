
import 'package:cybersecurity_quiz_platform/services/supabase_data_loader_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../providers/quiz_data_provider.dart';
import '../../services/hybrid_quiz_history_service.dart';
import '../../services/supabase_data_loader_service.dart';
import '../../models/quiz_history.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    _initializeQuizData();
  }

  Future<void> _initializeQuizData() async {
    final authProvider = context.read<AuthProvider>();
    final quizDataProvider = context.read<QuizDataProvider>();

    if (authProvider.user != null && !quizDataProvider.isInitialized) {
      await quizDataProvider.initialize(authProvider.user!.id);
    }
  }

  Future<void> _refreshStatistics() async {
    final quizDataProvider = context.read<QuizDataProvider>();
    await quizDataProvider.refresh();
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
              onRefresh: _refreshStatistics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildProfileHeader(user),
                    const SizedBox(height: 24),
                    _buildStatsSection(user, quizDataProvider.currentStats as QuizStatistics?),
                    const SizedBox(height: 24),
                    _buildAchievementsSection(
                        user, quizDataProvider.currentStats as QuizStatistics?),
                    const SizedBox(height: 24),
                    _buildSyncStatus(quizDataProvider),
                    const SizedBox(height: 24),
                    _buildSettingsSection(),
                    const SizedBox(height: 24),
                    // Debug: Test Supabase connection
                    if (true) // Set to false in production
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _testSupabaseConnection,
                          icon: const Icon(Icons.bug_report),
                          label: const Text('Test Supabase Connection'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.secondaryTeal,
                            side:
                                const BorderSide(color: AppTheme.secondaryTeal),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
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

  Widget _buildProfileHeader(user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Avatar
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentGreen.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                MdiIcons.account,
                size: 50,
                color: AppTheme.textPrimary,
              ),
            ),

            const SizedBox(height: 16),

            // User Name
            Text(
              user.name,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 4),

            // User Email
            Text(
              user.email,
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 16),

            // Member Since
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.secondaryTeal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppTheme.secondaryTeal.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Member since ${_formatDate(user.createdAt)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.secondaryTeal,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(user, QuizStatistics? statistics) {
    final stats = statistics;

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
              ],
            ),

            const SizedBox(height: 20),

            // Stats Grid - Use real data from quiz history
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: MdiIcons.fire,
                    label: 'Current Streak',
                    value: _calculateStreak(stats?.recentQuizzes ?? []),
                    color: AppTheme.errorRed,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    icon: MdiIcons.helpCircle,
                    label: 'Questions Answered',
                    value:
                        '${(stats?.totalQuizzesCompleted ?? 0) * 10}', // 10 questions per quiz
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
                    value: '${stats?.totalQuizzesCompleted ?? 0}',
                    color: AppTheme.successGreen,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    icon: MdiIcons.clockOutline,
                    label: 'Study Time',
                    value:
                        _formatDuration(stats?.totalStudyTime ?? Duration.zero),
                    color: AppTheme.accentGreen,
                  ),
                ),
              ],
            ),

            if (stats != null && stats.averageScore > 0) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      icon: MdiIcons.trendingUp,
                      label: 'Average Score',
                      value: '${stats.averageScore.round()}%',
                      color: AppTheme.secondaryTeal,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatItem(
                      icon: MdiIcons.trophy,
                      label: 'Best Score',
                      value: '${stats.bestScore.round()}%',
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

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(user, QuizStatistics? statistics) {
    final stats = statistics;
    final totalQuestions = (stats?.totalQuizzesCompleted ?? 0) * 10;
    final currentStreak = _calculateStreakFromStats(stats?.recentQuizzes ?? []);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  MdiIcons.trophy,
                  color: AppTheme.accentGreen,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Achievements',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 20,
                      ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Achievement badges - Use real data from quiz history
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildAchievementBadge(
                  icon: MdiIcons.accountCheck,
                  label: 'First Quiz',
                  isUnlocked: (stats?.totalQuizzesCompleted ?? 0) > 0,
                ),
                _buildAchievementBadge(
                  icon: MdiIcons.fire,
                  label: '7 Day Streak',
                  isUnlocked: currentStreak >= 7,
                ),
                _buildAchievementBadge(
                  icon: MdiIcons.star,
                  label: '100 Questions',
                  isUnlocked: totalQuestions >= 100,
                ),
                _buildAchievementBadge(
                  icon: MdiIcons.trophy,
                  label: 'Quiz Master',
                  isUnlocked: (stats?.totalQuizzesCompleted ?? 0) >= 50,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementBadge({
    required IconData icon,
    required String label,
    required bool isUnlocked,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isUnlocked
            ? AppTheme.accentGreen.withValues(alpha: 0.1)
            : AppTheme.surfaceCharcoal,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnlocked
              ? AppTheme.accentGreen.withValues(alpha: 0.3)
              : AppTheme.textSecondary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isUnlocked ? AppTheme.accentGreen : AppTheme.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isUnlocked ? AppTheme.accentGreen : AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  MdiIcons.cog,
                  color: AppTheme.secondaryTeal,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 20,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSettingsItem(
              icon: MdiIcons.bell,
              title: 'Notifications',
              subtitle: 'Manage your notification preferences',
              onTap: () {
                // TODO: Navigate to notifications settings
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Notifications settings coming soon!')),
                );
              },
            ),
            const Divider(color: AppTheme.surfaceCharcoal),
            _buildSettingsItem(
              icon: MdiIcons.themeLightDark,
              title: 'Theme',
              subtitle: 'Dark theme (default)',
              onTap: () {
                // TODO: Theme settings
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Theme settings coming soon!')),
                );
              },
            ),
            const Divider(color: AppTheme.surfaceCharcoal),
            _buildSettingsItem(
              icon: MdiIcons.help,
              title: 'Help & Support',
              subtitle: 'Get help and contact support',
              onTap: () {
                // TODO: Help & support
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Help & support coming soon!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textSecondary, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(AuthProvider authProvider) {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: 'Logout',
        onPressed: () => _showLogoutDialog(authProvider),
        backgroundColor: AppTheme.errorRed,
        icon: MdiIcons.logout,
      ),
    );
  }

  void _showLogoutDialog(AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceCharcoal,
        title: const Text(
          'Logout',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await authProvider.signOut();
              if (mounted) {
                context.go('/auth/login');
              }
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: AppTheme.errorRed),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatDateShort(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '${difference}d ago';
    if (difference < 30) return '${(difference / 7).floor()}w ago';
    return '${(difference / 30).floor()}m ago';
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else if (duration.inSeconds > 0) {
      return '${duration.inSeconds}s';
    } else {
      return '0m';
    }
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
                  quizDataProvider.isSyncing
                      ? MdiIcons.send
                      : MdiIcons.checkCircle,
                  color: quizDataProvider.isSyncing
                      ? AppTheme.accentGreen
                      : AppTheme.successGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  quizDataProvider.isSyncing ? 'Syncing...' : 'All data synced',
                  style: TextStyle(
                    color: quizDataProvider.isSyncing
                        ? AppTheme.accentGreen
                        : AppTheme.successGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (quizDataProvider.pendingSyncCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  String _calculateStreak(List<QuizHistoryEntry> recentQuizzes) {
    return _calculateStreakFromStats(recentQuizzes).toString();
  }

  int _calculateStreakFromStats(List<QuizHistoryEntry> recentQuizzes) {
    if (recentQuizzes.isEmpty) return 0;

    // Sort by completion date (most recent first)
    final sortedQuizzes = List<QuizHistoryEntry>.from(recentQuizzes)
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

    int streak = 0;
    DateTime? lastDate;

    for (final quiz in sortedQuizzes) {
      final quizDate = DateTime(
          quiz.completedAt.year, quiz.completedAt.month, quiz.completedAt.day);

      if (lastDate == null) {
        // First quiz
        streak = 1;
        lastDate = quizDate;
      } else {
        final daysDifference = lastDate.difference(quizDate).inDays;

        if (daysDifference == 1) {
          // Consecutive day
          streak++;
          lastDate = quizDate;
        } else if (daysDifference == 0) {
          // Same day, don't increment streak but continue
          continue;
        } else {
          // Gap in streak, stop counting
          break;
        }
      }
    }

    return streak;
  }

  /// Test Supabase connection (debug method)
  Future<void> _testSupabaseConnection() async {
    try {
      final dataLoader = SupabaseDataLoaderService();
      final isConnected = await dataLoader.testConnection();

      if (isConnected) {
        final stats = await dataLoader.getDatabaseStats();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Supabase Connected!\n'
                'Questions: ${stats['questions']}\n'
                'Users: ${stats['users']}\n'
                'Quiz History: ${stats['quiz_history']}',
              ),
              backgroundColor: AppTheme.successGreen,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Supabase connection failed'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection test failed: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }
}
