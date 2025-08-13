import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../core/theme.dart';
import '../../models/quiz.dart';
import '../../widgets/custom_button.dart';
import '../../providers/quiz_data_provider.dart';
import '../../providers/auth_provider.dart';

class QuizResultsScreen extends StatefulWidget {
  final String quizId;
  final QuizResult? quizResult;

  const QuizResultsScreen({
    super.key,
    required this.quizId,
    this.quizResult,
  });

  @override
  State<QuizResultsScreen> createState() => _QuizResultsScreenState();
}

class _QuizResultsScreenState extends State<QuizResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _scoreAnimationController;
  late Animation<double> _scoreAnimation;
  late AnimationController _confettiController;
  
  bool _showReview = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
    _saveQuizResultToProvider();
  }

  /// Save quiz result using hybrid provider for instant updates
  Future<void> _saveQuizResultToProvider() async {
    if (widget.quizResult == null) return;
    
    try {
      final authProvider = context.read<AuthProvider>();
      final quizDataProvider = context.read<QuizDataProvider>();
      
      if (authProvider.user != null) {
        // Extract certification info from the quiz result
        // Note: You might need to pass more context about the certification
        await quizDataProvider.saveQuizResult(
          widget.quizResult!,
          authProvider.user!.id,
          'isc2-cc', // You might need to pass this from the quiz
          'ISC² CC', // You might need to pass this from the quiz
          sectionId: null, // Extract from quiz context if available
          sectionName: null, // Extract from quiz context if available
        );
      }
    } catch (e) {
      print('Failed to save quiz result via provider: $e');
    }
  }

  void _setupAnimations() {
    _scoreAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scoreAnimation = Tween<double>(
      begin: 0.0,
      end: widget.quizResult?.scorePercentage ?? 0.0,
    ).animate(CurvedAnimation(
      parent: _scoreAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _confettiController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 500), () {
      _scoreAnimationController.forward();
      
      // Show confetti for good scores
      if ((widget.quizResult?.scorePercentage ?? 0) >= 70) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          _confettiController.forward();
        });
      }
    });
  }

  @override
  void dispose() {
    _scoreAnimationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.quizResult == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppTheme.backgroundDark,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: Text(
            'Results not found',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: _buildAppBar(),
      body: _showReview ? _buildReviewContent() : _buildResultsContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.backgroundDark,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: AppTheme.textPrimary),
        onPressed: () => context.go('/dashboard'),
      ),
      title: Text(
        _showReview ? 'Review Questions' : 'Quiz Results',
        style: const TextStyle(color: AppTheme.textPrimary),
      ),
      actions: [
        if (!_showReview)
          TextButton(
            onPressed: () => setState(() => _showReview = true),
            child: const Text(
              'Review',
              style: TextStyle(color: AppTheme.accentGreen),
            ),
          ),
        if (_showReview)
          TextButton(
            onPressed: () => setState(() => _showReview = false),
            child: const Text(
              'Results',
              style: TextStyle(color: AppTheme.accentGreen),
            ),
          ),
      ],
    );
  }

  Widget _buildResultsContent() {
    final result = widget.quizResult!;
    
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
        children: [
          _buildScoreCard(result),
          const SizedBox(height: 24),
          _buildStatsCards(result),
          const SizedBox(height: 24),
          _buildPerformanceBreakdown(result),
          const SizedBox(height: 32),
          _buildActionButtons(),
        ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(QuizResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Congratulations message
            Text(
              _getScoreMessage(result.scorePercentage),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: _getScoreColor(result.scorePercentage),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Animated score circle
            SizedBox(
              width: 150,
              height: 150,
              child: AnimatedBuilder(
                animation: _scoreAnimation,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 150,
                        height: 150,
                        child: CircularProgressIndicator(
                          value: _scoreAnimation.value / 100,
                          strokeWidth: 12,
                          backgroundColor: AppTheme.surfaceCharcoal,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getScoreColor(result.scorePercentage),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_scoreAnimation.value.round()}%',
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 36,
                            ),
                          ),
                          Text(
                            '${result.correctAnswers}/${result.totalQuestions}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Quiz completed on ${_formatDate(result.completedAt)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards(QuizResult result) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: MdiIcons.checkCircle,
            label: 'Correct',
            value: '${result.correctAnswers}',
            color: AppTheme.successGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: MdiIcons.closeCircle,
            label: 'Incorrect',
            value: '${result.totalQuestions - result.correctAnswers}',
            color: AppTheme.errorRed,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: MdiIcons.clockOutline,
            label: 'Time',
            value: _formatDuration(result.timeTaken),
            color: AppTheme.secondaryTeal,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceBreakdown(QuizResult result) {
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
                  color: AppTheme.secondaryTeal,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Performance',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPerformanceItem(
              'Overall Score',
              '${result.scorePercentage.round()}%',
              result.scorePercentage / 100,
              _getScoreColor(result.scorePercentage),
            ),
            const SizedBox(height: 12),
            _buildPerformanceItem(
              'Accuracy',
              '${((result.correctAnswers / result.totalQuestions) * 100).round()}%',
              result.correctAnswers / result.totalQuestions,
              AppTheme.accentGreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceItem(String label, String value, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppTheme.surfaceCharcoal,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: CustomButton(
            text: 'Review Questions',
            onPressed: () => setState(() => _showReview = true),
            backgroundColor: AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedCustomButton(
            text: 'Back to Dashboard',
            onPressed: () => context.go('/dashboard'),
            borderColor: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewContent() {
    final result = widget.quizResult!;
    
    return SafeArea(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: result.questionResults.length,
      itemBuilder: (context, index) {
        final questionResult = result.questionResults[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildReviewQuestionCard(questionResult, index + 1),
        );
      },
      ),
    );
  }

  Widget _buildReviewQuestionCard(QuestionResult questionResult, int questionNumber) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question header
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: questionResult.isCorrect 
                        ? AppTheme.successGreen 
                        : AppTheme.errorRed,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    questionResult.isCorrect 
                        ? Icons.check 
                        : Icons.close,
                    color: AppTheme.textPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Question $questionNumber',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Question text
            Text(
              questionResult.question.text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.4,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Answer options
            ...questionResult.question.answers.map((answer) {
              final isSelected = answer.id == questionResult.selectedAnswerId;
              final isCorrect = answer.isCorrect;
              
              Color backgroundColor = Colors.transparent;
              Color borderColor = AppTheme.surfaceCharcoal;
              Widget? trailing;
              
              if (isCorrect) {
                backgroundColor = AppTheme.successGreen.withValues(alpha: 0.1);
                borderColor = AppTheme.successGreen;
                trailing = const Icon(Icons.check_circle, color: AppTheme.successGreen);
              } else if (isSelected && !isCorrect) {
                backgroundColor = AppTheme.errorRed.withValues(alpha: 0.1);
                borderColor = AppTheme.errorRed;
                trailing = const Icon(Icons.cancel, color: AppTheme.errorRed);
              }
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        answer.text,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: isSelected || isCorrect 
                              ? FontWeight.w600 
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 8),
                      trailing,
                    ],
                  ],
                ),
              );
            }).toList(),
            
            const SizedBox(height: 16),
            
            // Explanation
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        MdiIcons.lightbulbOn,
                        color: AppTheme.accentGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Explanation',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.accentGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    questionResult.question.explanation,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getScoreMessage(double score) {
    if (score >= 90) return 'Excellent!';
    if (score >= 80) return 'Great Job!';
    if (score >= 70) return 'Well Done!';
    if (score >= 60) return 'Good Effort!';
    return 'Keep Practicing!';
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return AppTheme.successGreen;
    if (score >= 60) return AppTheme.accentGreen;
    return AppTheme.errorRed;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
}