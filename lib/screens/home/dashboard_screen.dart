import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../models/certification.dart';
import '../../services/quiz_service.dart';
import '../../providers/quiz_data_provider.dart';
import '../../models/quiz_history.dart';
import '../../scripts/migrate_to_supabase.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final QuizService _quizService;
  List<Certification> _certifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _quizService = QuizService();
    _loadCertifications();
    _initializeQuizData();
  }

  Future<void> _initializeQuizData() async {
    final authProvider = context.read<AuthProvider>();
    final quizDataProvider = context.read<QuizDataProvider>();

    if (authProvider.user != null && !quizDataProvider.isInitialized) {
      await quizDataProvider.initialize(authProvider.user!.id);
    }
  }

  Future<void> _loadCertifications() async {
    try {
      final certifications = await _quizService.getCertifications();
      if (mounted) {
        setState(() {
          _certifications = certifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    final quizDataProvider = context.read<QuizDataProvider>();
    await quizDataProvider.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SafeArea(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with greeting and profile
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, ${user.name}! 👋',
                                style:
                                    Theme.of(context).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Ready to master cybersecurity?',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              _showProfileMenu(context, authProvider),
                          icon: CircleAvatar(
                            backgroundColor: AppTheme.primaryBlue,
                            child: Text(
                              user.name.isNotEmpty
                                  ? user.name[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Streak Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppTheme.primaryBlue,
                            AppTheme.secondaryTeal
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(
                            AppConstants.cardBorderRadius),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentGreen.withValues(alpha: 0.2),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.local_fire_department,
                              color: Colors.orange,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Consumer<QuizDataProvider>(
                                  builder: (context, quizData, child) {
                                    final streak = _calculateStreak(
                                        quizData.currentStats?.recentQuizzes ??
                                            []);
                                    return Text(
                                      '$streak Day Streak',
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  },
                                ),
                                Text(
                                  'Keep it up! Study daily to maintain your streak',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary
                                        .withValues(alpha: 0.8),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Quick Stats
                    Row(
                      children: [
                        Expanded(
                          child: Consumer<QuizDataProvider>(
                            builder: (context, quizData, child) {
                              final questionsAnswered = (quizData.currentStats
                                          ?.totalQuizzesCompleted ??
                                      0) *
                                  10;
                              return _buildStatCard(
                                'Questions\nAnswered',
                                '$questionsAnswered',
                                Icons.quiz_outlined,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Consumer<QuizDataProvider>(
                            builder: (context, quizData, child) {
                              final quizzesCompleted = quizData
                                      .currentStats?.totalQuizzesCompleted ??
                                  0;
                              return _buildStatCard(
                                'Quizzes\nCompleted',
                                '$quizzesCompleted',
                                Icons.check_circle_outline,
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Migration Button (temporary - remove after migration)
                    if (true) // Set to false after migration is complete
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 24),
                        child: ElevatedButton.icon(
                          onPressed: _runMigration,
                          icon: const Icon(Icons.cloud_upload),
                          label: const Text('Migrate to Supabase'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentGreen,
                            foregroundColor: AppTheme.textPrimary,
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),

                    // Certifications Section
                    Text(
                      'Available Certifications',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontSize: 20,
                              ),
                    ),

                    const SizedBox(height: 16),

                    // Certification Cards
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      ..._certifications.map(
                        (cert) => _buildCertificationCard(context, cert),
                      ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCharcoal,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppTheme.accentGreen,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCertificationCard(BuildContext context, Certification cert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: InkWell(
          onTap: () {
            context.push('/certification/${cert.id}');
          },
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Certification Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.security,
                    color: AppTheme.primaryBlue,
                    size: 30,
                  ),
                ),

                const SizedBox(width: 16),

                // Certification Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cert.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cert.description,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${cert.sections.length} sections',
                        style: const TextStyle(
                          color: AppTheme.accentGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.textSecondary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProfileMenu(BuildContext context, AuthProvider authProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCharcoal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person, color: AppTheme.textPrimary),
              title: const Text('Profile',
                  style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                context.push('/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: AppTheme.textPrimary),
              title: const Text('Settings',
                  style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings coming soon!')),
                );
              },
            ),
            const Divider(color: AppTheme.textSecondary),
            ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.errorRed),
              title: const Text('Sign Out',
                  style: TextStyle(color: AppTheme.errorRed)),
              onTap: () async {
                Navigator.pop(context);
                await authProvider.signOut();
                if (context.mounted) {
                  context.go('/auth/login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  int _calculateStreak(List<QuizHistoryEntry> recentQuizzes) {
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

  /// Run Supabase migration (temporary method)
  Future<void> _runMigration() async {
    // Store the context before async operations
    final scaffoldContext = ScaffoldMessenger.of(context);
    final navigatorContext = Navigator.of(context);

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          backgroundColor: AppTheme.surfaceCharcoal,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Migrating data to Supabase...\nThis may take a few minutes.',
                style: TextStyle(color: AppTheme.textPrimary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

      // Run migration
      await runSupabaseMigration();

      // Close loading dialog safely
      if (mounted) {
        try {
          navigatorContext.pop();
        } catch (e) {
          // Dialog might already be closed, ignore error
        }
      }

      // Show success message
      if (mounted) {
        scaffoldContext.showSnackBar(
          const SnackBar(
            content: Text('Migration completed successfully!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }

      // Refresh data
      if (mounted) {
        await _refreshData();
      }
    } catch (e) {
      // Close loading dialog safely
      if (mounted) {
        try {
          navigatorContext.pop();
        } catch (e) {
          // Dialog might already be closed, ignore error
        }
      }

      // Show error message
      if (mounted) {
        scaffoldContext.showSnackBar(
          SnackBar(
            content: Text('Migration failed: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }
}
