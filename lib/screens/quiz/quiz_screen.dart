import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../core/theme.dart';
import '../../models/quiz.dart';
import '../../services/quiz_service.dart';
import '../../widgets/custom_button.dart';

class QuizScreen extends StatefulWidget {
  final String quizId;
  final Quiz? quiz;

  const QuizScreen({
    super.key,
    required this.quizId,
    this.quiz,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final QuizService _quizService;
  Quiz? _quiz;
  int _currentQuestionIndex = 0;
  Map<String, String> _userAnswers = {};
  String? _selectedAnswerId;
  bool _hasSubmittedAnswer = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _quizService = QuizService();
    _quiz = widget.quiz;
    
    if (_quiz != null) {
      setState(() {
        _isLoading = false;
      });
    } else {
      _loadQuiz();
    }
  }

  Future<void> _loadQuiz() async {
    try {
      // In a real app, you'd load the quiz by ID from the service
      // For now, we'll use the passed quiz or show an error
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load quiz: $e')),
        );
      }
    }
  }

  void _selectAnswer(String answerId) {
    if (_hasSubmittedAnswer) return;
    
    setState(() {
      _selectedAnswerId = answerId;
    });
  }

  void _submitAnswer() {
    if (_selectedAnswerId == null || _hasSubmittedAnswer) return;
    
    setState(() {
      _hasSubmittedAnswer = true;
      _userAnswers[_currentQuestion.id] = _selectedAnswerId!;
    });
    
    // Save answer
    _quizService.submitAnswer(widget.quizId, _currentQuestion.id, _selectedAnswerId!);
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _quiz!.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerId = _userAnswers[_currentQuestion.id];
        _hasSubmittedAnswer = _selectedAnswerId != null;
      });
    } else {
      _completeQuiz();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _selectedAnswerId = _userAnswers[_currentQuestion.id];
        _hasSubmittedAnswer = _selectedAnswerId != null;
      });
    }
  }

  Future<void> _completeQuiz() async {
    try {
      final result = await _quizService.completeQuiz(_quiz!, _userAnswers);
      if (mounted) {
        context.pushReplacement(
          '/quiz/${widget.quizId}/results',
          extra: {'result': result},
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to complete quiz: $e')),
        );
      }
    }
  }

  Question get _currentQuestion => _quiz!.questions[_currentQuestionIndex];

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
          ),
        ),
      );
    }

    if (_quiz == null) {
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
            'Quiz not found',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuestionCard(),
                  const SizedBox(height: 24),
                  _buildAnswerOptions(),
                  const SizedBox(height: 24),
                  if (_hasSubmittedAnswer) _buildExplanation(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.backgroundDark,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: AppTheme.textPrimary),
        onPressed: () => _showExitDialog(),
      ),
      title: Text(
        'Quiz',
        style: const TextStyle(color: AppTheme.textPrimary),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Text(
              '${_currentQuestionIndex + 1}/${_quiz!.questions.length}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    final progress = (_currentQuestionIndex + 1) / _quiz!.questions.length;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentQuestionIndex + 1}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              Text(
                '${(_currentQuestionIndex + 1)}/${_quiz!.questions.length}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.surfaceCharcoal,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  MdiIcons.helpCircle,
                  color: AppTheme.secondaryTeal,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Question',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.secondaryTeal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _currentQuestion.text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 18,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerOptions() {
    return Column(
      children: _currentQuestion.answers.map((answer) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildAnswerOption(answer),
        );
      }).toList(),
    );
  }

  Widget _buildAnswerOption(Answer answer) {
    final isSelected = _selectedAnswerId == answer.id;
    final isCorrect = answer.isCorrect;
    final showResult = _hasSubmittedAnswer;
    
    Color backgroundColor = AppTheme.surfaceCharcoal;
    Color borderColor = Colors.transparent;
    Color textColor = AppTheme.textPrimary;
    Widget? trailing;
    
    if (showResult) {
      if (isCorrect) {
        backgroundColor = AppTheme.successGreen.withValues(alpha: 0.1);
        borderColor = AppTheme.successGreen;
        trailing = const Icon(Icons.check_circle, color: AppTheme.successGreen);
      } else if (isSelected && !isCorrect) {
        backgroundColor = AppTheme.errorRed.withValues(alpha: 0.1);
        borderColor = AppTheme.errorRed;
        trailing = const Icon(Icons.cancel, color: AppTheme.errorRed);
      }
    } else if (isSelected) {
      backgroundColor = AppTheme.primaryBlue.withValues(alpha: 0.1);
      borderColor = AppTheme.primaryBlue;
    }
    
    return GestureDetector(
      onTap: () => _selectAnswer(answer.id),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                answer.text,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExplanation() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  MdiIcons.lightbulbOn,
                  color: AppTheme.accentGreen,
                  size: 24,
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
            const SizedBox(height: 12),
            Text(
              _currentQuestion.explanation,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCharcoal,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentQuestionIndex > 0)
              Expanded(
                child: OutlinedCustomButton(
                  text: 'Previous',
                  onPressed: _previousQuestion,
                  borderColor: AppTheme.textSecondary,
                ),
              ),
            if (_currentQuestionIndex > 0) const SizedBox(width: 12),
            if (!_hasSubmittedAnswer && _selectedAnswerId != null)
              Expanded(
                child: CustomButton(
                  text: 'Submit Answer',
                  onPressed: _submitAnswer,
                  backgroundColor: AppTheme.primaryBlue,
                ),
              ),
            if (_hasSubmittedAnswer)
              Expanded(
                child: CustomButton(
                  text: _currentQuestionIndex < _quiz!.questions.length - 1
                      ? 'Next Question'
                      : 'Complete Quiz',
                  onPressed: _nextQuestion,
                  backgroundColor: AppTheme.accentGreen,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceCharcoal,
        title: const Text(
          'Exit Quiz?',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          'Your progress will be lost if you exit now.',
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
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
            child: const Text(
              'Exit',
              style: TextStyle(color: AppTheme.errorRed),
            ),
          ),
        ],
      ),
    );
  }
}