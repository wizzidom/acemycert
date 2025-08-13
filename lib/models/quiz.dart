import '../core/constants.dart';

class Quiz {
  final String id;
  final String userId;
  final String certificationId;
  final String? sectionId;
  final List<Question> questions;
  final QuizStatus status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int currentQuestionIndex;

  const Quiz({
    required this.id,
    required this.userId,
    required this.certificationId,
    this.sectionId,
    required this.questions,
    required this.status,
    required this.startedAt,
    this.completedAt,
    this.currentQuestionIndex = 0,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      certificationId: json['certification_id'] as String,
      sectionId: json['section_id'] as String?,
      status: QuizStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => QuizStatus.notStarted,
      ),
      startedAt: DateTime.parse(json['started_at'] as String),
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at'] as String) 
          : null,
      currentQuestionIndex: json['current_question_index'] as int? ?? 0,
      questions: (json['questions'] as List<dynamic>?)
          ?.map((e) => Question.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'certification_id': certificationId,
      'section_id': sectionId,
      'status': status.name,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'current_question_index': currentQuestionIndex,
      'questions': questions.map((e) => e.toJson()).toList(),
    };
  }

  Quiz copyWith({
    String? id,
    String? userId,
    String? certificationId,
    String? sectionId,
    List<Question>? questions,
    QuizStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    int? currentQuestionIndex,
  }) {
    return Quiz(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      certificationId: certificationId ?? this.certificationId,
      sectionId: sectionId ?? this.sectionId,
      questions: questions ?? this.questions,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
    );
  }

  Question? get currentQuestion {
    if (currentQuestionIndex >= 0 && currentQuestionIndex < questions.length) {
      return questions[currentQuestionIndex];
    }
    return null;
  }

  bool get isCompleted => status == QuizStatus.completed;
  bool get hasNextQuestion => currentQuestionIndex < questions.length - 1;
  bool get hasPreviousQuestion => currentQuestionIndex > 0;
  
  double get progressPercentage {
    if (questions.isEmpty) return 0.0;
    return (currentQuestionIndex + 1) / questions.length;
  }
}

class Question {
  final String id;
  final String text;
  final List<Answer> answers;
  final String correctAnswerId;
  final String explanation;
  final String sectionId;
  final String certificationId;
  final QuestionDifficulty difficulty;

  const Question({
    required this.id,
    required this.text,
    required this.answers,
    required this.correctAnswerId,
    required this.explanation,
    required this.sectionId,
    required this.certificationId,
    this.difficulty = QuestionDifficulty.medium,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      text: json['text'] as String,
      correctAnswerId: json['correct_answer_id'] as String,
      explanation: json['explanation'] as String,
      sectionId: json['section_id'] as String,
      certificationId: json['certification_id'] as String,
      difficulty: QuestionDifficulty.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => QuestionDifficulty.medium,
      ),
      answers: (json['answers'] as List<dynamic>?)
          ?.map((e) => Answer.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'correct_answer_id': correctAnswerId,
      'explanation': explanation,
      'section_id': sectionId,
      'certification_id': certificationId,
      'difficulty': difficulty.name,
      'answers': answers.map((e) => e.toJson()).toList(),
    };
  }

  Answer? get correctAnswer {
    try {
      return answers.firstWhere((answer) => answer.id == correctAnswerId);
    } catch (e) {
      return null;
    }
  }

  bool isCorrectAnswer(String answerId) {
    return answerId == correctAnswerId;
  }
}

class Answer {
  final String id;
  final String text;
  final bool isCorrect;

  const Answer({
    required this.id,
    required this.text,
    required this.isCorrect,
  });

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      id: json['id'] as String,
      text: json['text'] as String,
      isCorrect: json['is_correct'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'is_correct': isCorrect,
    };
  }
}

class QuizResult {
  final String quizId;
  final int correctAnswers;
  final int totalQuestions;
  final double scorePercentage;
  final List<QuestionResult> questionResults;
  final DateTime completedAt;
  final Duration timeTaken;

  const QuizResult({
    required this.quizId,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.scorePercentage,
    required this.questionResults,
    required this.completedAt,
    required this.timeTaken,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      quizId: json['quiz_id'] as String,
      correctAnswers: json['correct_answers'] as int,
      totalQuestions: json['total_questions'] as int,
      scorePercentage: (json['score_percentage'] as num).toDouble(),
      completedAt: DateTime.parse(json['completed_at'] as String),
      timeTaken: Duration(seconds: json['time_taken_seconds'] as int),
      questionResults: (json['question_results'] as List<dynamic>?)
          ?.map((e) => QuestionResult.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quiz_id': quizId,
      'correct_answers': correctAnswers,
      'total_questions': totalQuestions,
      'score_percentage': scorePercentage,
      'completed_at': completedAt.toIso8601String(),
      'time_taken_seconds': timeTaken.inSeconds,
      'question_results': questionResults.map((e) => e.toJson()).toList(),
    };
  }

  factory QuizResult.fromQuiz(Quiz quiz, List<QuestionResult> results) {
    final correctCount = results.where((r) => r.isCorrect).length;
    final totalCount = results.length;
    final percentage = totalCount > 0 ? (correctCount / totalCount) * 100 : 0.0;
    
    return QuizResult(
      quizId: quiz.id,
      correctAnswers: correctCount,
      totalQuestions: totalCount,
      scorePercentage: percentage,
      questionResults: results,
      completedAt: DateTime.now(),
      timeTaken: DateTime.now().difference(quiz.startedAt),
    );
  }

  bool get isPassing => scorePercentage >= 70.0;
  String get grade {
    if (scorePercentage >= 90) return 'A';
    if (scorePercentage >= 80) return 'B';
    if (scorePercentage >= 70) return 'C';
    if (scorePercentage >= 60) return 'D';
    return 'F';
  }
}

class QuestionResult {
  final String questionId;
  final Question question;
  final String? selectedAnswerId;
  final bool isCorrect;
  final DateTime answeredAt;

  const QuestionResult({
    required this.questionId,
    required this.question,
    this.selectedAnswerId,
    required this.isCorrect,
    required this.answeredAt,
  });

  factory QuestionResult.fromJson(Map<String, dynamic> json) {
    return QuestionResult(
      questionId: json['question_id'] as String,
      question: Question.fromJson(json['question'] as Map<String, dynamic>),
      selectedAnswerId: json['selected_answer_id'] as String?,
      isCorrect: json['is_correct'] as bool,
      answeredAt: DateTime.parse(json['answered_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'question': question.toJson(),
      'selected_answer_id': selectedAnswerId,
      'is_correct': isCorrect,
      'answered_at': answeredAt.toIso8601String(),
    };
  }
}

class QuizProgress {
  final String quizId;
  final String userId;
  final int currentQuestionIndex;
  final Map<String, String> answers;
  final DateTime lastUpdated;

  const QuizProgress({
    required this.quizId,
    required this.userId,
    required this.currentQuestionIndex,
    required this.answers,
    required this.lastUpdated,
  });

  factory QuizProgress.fromJson(Map<String, dynamic> json) {
    return QuizProgress(
      quizId: json['quiz_id'] as String,
      userId: json['user_id'] as String,
      currentQuestionIndex: json['current_question_index'] as int,
      answers: Map<String, String>.from(json['answers'] as Map),
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quiz_id': quizId,
      'user_id': userId,
      'current_question_index': currentQuestionIndex,
      'answers': answers,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}