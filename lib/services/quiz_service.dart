import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/certification.dart';
import '../models/quiz.dart';
import '../core/constants.dart';
import 'supabase_data_loader_service.dart';
import 'quiz_history_service.dart';

class QuizService {
  // Certifications data - ISC² CC has real data, others have 0 questions
  static List<Certification>? _certifications;
  
  // Quiz history service for saving results
  final QuizHistoryService _historyService = QuizHistoryService();
  
  static Future<List<Certification>> _getCertifications() async {
    if (_certifications != null) {
      return _certifications!;
    }
    
    _certifications = [
      // ISC² CC with real data - moved to top
      await _createISC2Certification(),
      
      // Other certifications with 0 questions (no data available)
      Certification(
        id: 'comptia-security-plus',
        name: 'CompTIA Security+',
        description: 'Foundational cybersecurity certification covering network security, compliance, and operational security. (No questions available yet)',
        iconUrl: '',
        totalQuestions: 0,
        sections: [
          QuizSection(
            id: 'threats-attacks-vulnerabilities',
            name: 'Threats, Attacks, and Vulnerabilities',
            certificationId: 'comptia-security-plus',
            questionCount: 0,
            description: 'Understanding various security threats and attack vectors (No questions available)',
          ),
          QuizSection(
            id: 'architecture-design',
            name: 'Architecture and Design',
            certificationId: 'comptia-security-plus',
            questionCount: 0,
            description: 'Secure network architecture and design principles (No questions available)',
          ),
          QuizSection(
            id: 'implementation',
            name: 'Implementation',
            certificationId: 'comptia-security-plus',
            questionCount: 0,
            description: 'Implementing secure protocols and systems (No questions available)',
          ),
          QuizSection(
            id: 'operations-incident-response',
            name: 'Operations and Incident Response',
            certificationId: 'comptia-security-plus',
            questionCount: 0,
            description: 'Security operations and incident response procedures (No questions available)',
          ),
          QuizSection(
            id: 'governance-risk-compliance',
            name: 'Governance, Risk, and Compliance',
            certificationId: 'comptia-security-plus',
            questionCount: 0,
            description: 'Risk management and compliance frameworks (No questions available)',
          ),
        ],
      ),    
  Certification(
        id: 'comptia-a-plus',
        name: 'CompTIA A+',
        description: 'Entry-level IT certification covering hardware, networking, mobile devices, and troubleshooting. (No questions available yet)',
        iconUrl: '',
        totalQuestions: 0,
        sections: [
          QuizSection(
            id: 'mobile-devices',
            name: 'Mobile Devices',
            certificationId: 'comptia-a-plus',
            questionCount: 0,
            description: 'Mobile device hardware and configuration (No questions available)',
          ),
          QuizSection(
            id: 'networking',
            name: 'Networking',
            certificationId: 'comptia-a-plus',
            questionCount: 0,
            description: 'Network protocols, devices, and troubleshooting (No questions available)',
          ),
          QuizSection(
            id: 'hardware',
            name: 'Hardware',
            certificationId: 'comptia-a-plus',
            questionCount: 0,
            description: 'Computer hardware components and troubleshooting (No questions available)',
          ),
          QuizSection(
            id: 'virtualization-cloud',
            name: 'Virtualization and Cloud Computing',
            certificationId: 'comptia-a-plus',
            questionCount: 0,
            description: 'Virtual machines and cloud services (No questions available)',
          ),
        ],
      ),
    ];
    
    return _certifications!;
  } 
 /// Create ISC² CC certification with real data from Supabase
  static Future<Certification> _createISC2Certification() async {
    try {
      final dataLoader = SupabaseDataLoaderService();
      final questionCounts = await dataLoader.getQuestionCounts();
      final sectionInfo = await dataLoader.getISC2Sections();
      
      List<QuizSection> sections = [];
      
      sectionInfo.forEach((sectionId, info) {
        final questionCount = questionCounts[sectionId] ?? 20;
        
        sections.add(QuizSection(
          id: sectionId,
          name: info['name'] as String,
          certificationId: 'isc2-cc',
          questionCount: questionCount,
          description: info['description'] as String,
        ));
      });
      
      final totalQuestions = await dataLoader.getTotalQuestionCount();
      
      return Certification(
        id: 'isc2-cc',
        name: 'ISC² CC',
        description: 'Certified in Cybersecurity - foundational cybersecurity knowledge and skills with real exam questions.',
        iconUrl: '',
        totalQuestions: totalQuestions,
        sections: sections,
      );
    } catch (e) {
      return Certification(
        id: 'isc2-cc',
        name: 'ISC² CC',
        description: 'Certified in Cybersecurity - foundational cybersecurity knowledge and skills.',
        iconUrl: '',
        totalQuestions: 100,
        sections: _createFallbackISC2Sections(),
      );
    }
  } 
 /// Create fallback sections with accurate counts if data loading fails
  static List<QuizSection> _createFallbackISC2Sections() {
    return [
      QuizSection(
        id: 'security-principles',
        name: 'Security Principles',
        certificationId: 'isc2-cc',
        questionCount: 20,
        description: 'Fundamental security concepts and principles (20 questions)',
      ),
      QuizSection(
        id: 'incident-response',
        name: 'Business Continuity, Disaster Recovery & Incident Response Concepts',
        certificationId: 'isc2-cc',
        questionCount: 20,
        description: 'Incident response processes and business continuity (20 questions)',
      ),
      QuizSection(
        id: 'access-controls',
        name: 'Access Controls Concepts',
        certificationId: 'isc2-cc',
        questionCount: 20,
        description: 'Access control concepts and implementation (20 questions)',
      ),
      QuizSection(
        id: 'network-security',
        name: 'Network Security',
        certificationId: 'isc2-cc',
        questionCount: 20,
        description: 'Network security concepts and technologies (20 questions)',
      ),
      QuizSection(
        id: 'security-operations',
        name: 'Security Operations',
        certificationId: 'isc2-cc',
        questionCount: 20,
        description: 'Security operations and data security (20 questions)',
      ),
    ];
  } 
 Future<List<Certification>> getCertifications() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return await _getCertifications();
  }

  Future<Certification> getCertification(String certificationId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final certifications = await _getCertifications();
    final certification = certifications.firstWhere(
      (cert) => cert.id == certificationId,
      orElse: () => throw Exception('Certification not found'),
    );
    
    return certification;
  }

  Future<Quiz> startQuiz(String certificationId, {String? sectionId}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    List<Question> questions = [];
    
    // Only ISC² CC has real data, others have no questions
    if (certificationId == 'isc2-cc') {
      questions = await _getISC2Questions(sectionId);
    } else {
      // No questions available for other certifications
      throw Exception('No questions available for this certification. Please check back later when content is added.');
    }
    
    if (questions.isEmpty) {
      throw Exception('No questions available for this certification/section');
    }
    
    // Shuffle questions and limit to 10 for quiz
    questions.shuffle();
    questions = questions.take(10).toList();
    
    // Get current user ID from Supabase
    final currentUser = Supabase.instance.client.auth.currentUser;
    final userId = currentUser?.id ?? 'anonymous_user';

    final quiz = Quiz(
      id: 'quiz_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      certificationId: certificationId,
      sectionId: sectionId,
      questions: questions,
      status: QuizStatus.inProgress,
      startedAt: DateTime.now(), // Real start time for accurate calculation
    );
    
    return quiz;
  }  
/// Get ISC² CC questions from Supabase
  Future<List<Question>> _getISC2Questions(String? sectionId) async {
    try {
      final dataLoader = SupabaseDataLoaderService();
      if (sectionId != null) {
        return await dataLoader.loadQuestionsFromDomain(sectionId);
      } else {
        return await dataLoader.loadISC2Questions();
      }
    } catch (e) {
      return [];
    }
  }

  Future<void> submitAnswer(String quizId, String questionId, String answerId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // In real app, save answer to database
  }

  Future<QuizResult> completeQuiz(Quiz quiz, Map<String, String> userAnswers) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Calculate actual time taken from quiz start to completion
    final actualCompletionTime = DateTime.now();
    final actualTimeTaken = actualCompletionTime.difference(quiz.startedAt);
    
    int correctAnswers = 0;
    List<QuestionResult> questionResults = [];
    
    for (final question in quiz.questions) {
      final userAnswerId = userAnswers[question.id];
      final isCorrect = userAnswerId == question.correctAnswerId;
      
      if (isCorrect) correctAnswers++;
      
      questionResults.add(QuestionResult(
        questionId: question.id,
        question: question,
        selectedAnswerId: userAnswerId,
        isCorrect: isCorrect,
        answeredAt: actualCompletionTime, // Use actual completion time
      ));
    }
    
    final result = QuizResult(
      quizId: quiz.id,
      correctAnswers: correctAnswers,
      totalQuestions: quiz.questions.length,
      scorePercentage: (correctAnswers / quiz.questions.length) * 100,
      questionResults: questionResults,
      completedAt: actualCompletionTime, // Use actual completion time
      timeTaken: actualTimeTaken, // Use actual time taken
    );
    
    // Save quiz result to history
    await _saveQuizToHistory(quiz, result);
    
    return result;
  }

  /// Save completed quiz to history using hybrid service
  Future<void> _saveQuizToHistory(Quiz quiz, QuizResult result) async {
    // Note: This will be handled by the QuizDataProvider in the UI layer
    // The quiz completion screen should call quizDataProvider.saveQuizResult()
    // This ensures instant UI updates with background cloud sync
    print('Quiz completed - UI should handle saving via QuizDataProvider');
  }

  Future<void> saveProgress(QuizProgress progress) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // In real app, save to database
  }
}