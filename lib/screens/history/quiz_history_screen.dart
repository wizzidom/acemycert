import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../core/theme.dart';
import '../../models/quiz_history.dart';
import '../../services/hybrid_quiz_history_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/quiz_data_provider.dart';
import '../../widgets/custom_button.dart';

class QuizHistoryScreen extends StatefulWidget {
  const QuizHistoryScreen({super.key});

  @override
  State<QuizHistoryScreen> createState() => _QuizHistoryScreenState();
}

class _QuizHistoryScreenState extends State<QuizHistoryScreen> {
  String _selectedFilter =
      'all'; // all, isc2-cc, comptia-security-plus, comptia-a-plus

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

  List<QuizHistoryEntry> _getFilteredHistory(
      List<QuizHistoryEntry> quizHistory) {
    if (_selectedFilter == 'all') return quizHistory;
    return quizHistory
        .where((quiz) => quiz.certificationId == _selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundDark,
        elevation: 0,
        title: const Text(
          'Quiz History',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        actions: [
          Consumer<QuizDataProvider>(
            builder: (context, quizData, child) {
              return IconButton(
                icon: Icon(
                  quizData.isSyncing ? Icons.sync : Icons.refresh,
                  color: AppTheme.textPrimary,
                ),
                onPressed: () => quizData.refresh(),
              );
            },
          ),
        ],
      ),
      body: Consumer<QuizDataProvider>(
        builder: (context, quizDataProvider, child) {
          // Show loading only on first load
          if (quizDataProvider.isLoading && !quizDataProvider.isInitialized) {
            return _buildLoadingState();
          }

          return _buildContent(quizDataProvider);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
      ),
    );
  }

  Widget _buildContent(QuizDataProvider quizDataProvider) {
    final quizHistory = quizDataProvider.currentHistory;
    final statistics = quizDataProvider.currentStats;

    if (quizHistory.isEmpty) {
      return _buildEmptyState();
    }

    return SafeArea(
      child: Column(
        children: [
          if (statistics != null) _buildStatisticsHeader(statistics),
          _buildFilterTabs(),
          Expanded(child: _buildHistoryList(quizHistory)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              MdiIcons.history,
              size: 80,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No Quiz History Yet',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete your first quiz to see your progress here',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Take a Quiz',
              onPressed: () => Navigator.of(context).pop(),
              backgroundColor: AppTheme.accentGreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsHeader(QuizStatistics stats) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
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
                    'Your Performance',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 20,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Average Score',
                      '${stats.averageScore.round()}%',
                      stats.averageGrade,
                      AppTheme.secondaryTeal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Best Score',
                      '${stats.bestScore.round()}%',
                      stats.bestGrade,
                      AppTheme.successGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Total Quizzes',
                      '${stats.totalQuizzesCompleted}',
                      'completed',
                      AppTheme.accentGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip('All', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('ISC² CC', 'isc2-cc'),
          const SizedBox(width: 8),
          _buildFilterChip('Security+', 'comptia-security-plus'),
          const SizedBox(width: 8),
          _buildFilterChip('A+', 'comptia-a-plus'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentGreen : AppTheme.surfaceCharcoal,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.accentGreen : AppTheme.textSecondary,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.backgroundDark : AppTheme.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList(List<QuizHistoryEntry> quizHistory) {
    final filteredHistory = _getFilteredHistory(quizHistory);

    if (filteredHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              MdiIcons.filterRemove,
              size: 60,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No quizzes found for this filter',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredHistory.length,
      itemBuilder: (context, index) {
        final quiz = filteredHistory[index];
        return _buildHistoryCard(quiz);
      },
    );
  }

  Widget _buildHistoryCard(QuizHistoryEntry quiz) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color:
                          _getScoreColor(quiz.scorePercentage).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        quiz.grade,
                        style: TextStyle(
                          color: _getScoreColor(quiz.scorePercentage),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quiz.certificationName,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        if (quiz.sectionName != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            quiz.sectionName!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${quiz.scorePercentage.round()}%',
                        style: TextStyle(
                          color: _getScoreColor(quiz.scorePercentage),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        '${quiz.correctAnswers}/${quiz.totalQuestions}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    MdiIcons.clockOutline,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDuration(quiz.timeTaken),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                        ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    MdiIcons.calendar,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(quiz.completedAt),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                        ),
                  ),
                  const Spacer(),
                  if (quiz.isPassing)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.successGreen.withOpacity(0.3)),
                      ),
                      child: Text(
                        'PASSED',
                        style: TextStyle(
                          color: AppTheme.successGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return AppTheme.successGreen;
    if (score >= 60) return AppTheme.accentGreen;
    return AppTheme.errorRed;
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '${difference}d ago';

    return '${date.day}/${date.month}/${date.year}';
  }
}
