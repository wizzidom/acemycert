import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../core/theme.dart';
import '../../models/certification.dart';

import '../../services/quiz_service.dart';
import '../../widgets/custom_button.dart';

class CertificationDetailScreen extends StatefulWidget {
  final String certificationId;

  const CertificationDetailScreen({
    super.key,
    required this.certificationId,
  });

  @override
  State<CertificationDetailScreen> createState() => _CertificationDetailScreenState();
}

class _CertificationDetailScreenState extends State<CertificationDetailScreen> {
  late final QuizService _quizService;
  Certification? _certification;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _quizService = QuizService();
    _loadCertification();
  }

  Future<void> _loadCertification() async {
    try {
      final certification = await _quizService.getCertification(widget.certificationId);
      setState(() {
        _certification = certification;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load certification: $e')),
        );
      }
    }
  }

  Future<void> _startRandomQuiz() async {
    if (_certification == null) return;
    
    // Check if certification has any questions
    if (_certification!.totalQuestions == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No questions available for this certification yet. Please check back later.'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
      return;
    }
    
    try {
      final quiz = await _quizService.startQuiz(_certification!.id);
      if (mounted) {
        context.push('/quiz/${quiz.id}', extra: {'quiz': quiz});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start quiz: $e')),
        );
      }
    }
  }

  Future<void> _startSectionQuiz(String sectionId) async {
    if (_certification == null) return;
    
    // Find the section and check if it has questions
    final section = _certification!.sections.firstWhere(
      (s) => s.id == sectionId,
      orElse: () => throw Exception('Section not found'),
    );
    
    if (section.questionCount == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No questions available for this section yet. Please check back later.'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
      return;
    }
    
    try {
      final quiz = await _quizService.startQuiz(_certification!.id, sectionId: sectionId);
      if (mounted) {
        context.push('/quiz/${quiz.id}', extra: {'quiz': quiz});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start section quiz: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _certification?.name ?? 'Certification',
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
      ),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
      ),
    );
  }

  Widget _buildContent() {
    if (_certification == null) {
      return const Center(
        child: Text(
          'Certification not found',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCertificationHeader(),
          const SizedBox(height: 24),
          _buildRandomQuizSection(),
          const SizedBox(height: 32),
          _buildSectionsHeader(),
          const SizedBox(height: 16),
          _buildSectionsList(),
        ],
        ),
      ),
    );
  }

  Widget _buildCertificationHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCertificationIcon(_certification!.name),
                    color: AppTheme.textPrimary,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _certification!.name,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _certification!.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRandomQuizSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  MdiIcons.shuffle,
                  color: AppTheme.accentGreen,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Random Quiz',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Test your knowledge with questions from all sections',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: _certification!.totalQuestions > 0 
                    ? 'Start Random Quiz' 
                    : 'No Questions Available',
                onPressed: _certification!.totalQuestions > 0 ? _startRandomQuiz : null,
                backgroundColor: _certification!.totalQuestions > 0 
                    ? AppTheme.accentGreen 
                    : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionsHeader() {
    return Row(
      children: [
        Icon(
          MdiIcons.bookOpenPageVariant,
          color: AppTheme.secondaryTeal,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          'Practice Sections',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionsList() {
    return Column(
      children: _certification!.sections.map((section) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildSectionCard(section),
        );
      }).toList(),
    );
  }

  Widget _buildSectionCard(QuizSection section) {
    final hasQuestions = section.questionCount > 0;
    final cardColor = hasQuestions ? AppTheme.surfaceCharcoal : AppTheme.surfaceCharcoal.withOpacity(0.5);
    final iconColor = hasQuestions ? AppTheme.secondaryTeal : AppTheme.textSecondary;
    final textColor = hasQuestions ? AppTheme.textPrimary : AppTheme.textSecondary;
    
    return Card(
      color: cardColor,
      child: InkWell(
        onTap: hasQuestions ? () => _startSectionQuiz(section.id) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  hasQuestions ? MdiIcons.bookOpenPageVariant : MdiIcons.bookRemove,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasQuestions 
                          ? '${section.questionCount} questions'
                          : 'No questions available',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: hasQuestions ? AppTheme.textSecondary : AppTheme.errorRed,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasQuestions)
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.textSecondary,
                  size: 16,
                )
              else
                Icon(
                  Icons.lock,
                  color: AppTheme.textSecondary,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCertificationIcon(String certificationName) {
    if (certificationName.contains('Security+')) {
      return MdiIcons.security;
    } else if (certificationName.contains('A+')) {
      return MdiIcons.laptop;
    } else if (certificationName.contains('CC')) {
      return MdiIcons.certificate;
    }
    return MdiIcons.security;
  }
}