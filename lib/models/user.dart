class User {
  final String id;
  final String email;
  final String name;
  final DateTime createdAt;
  final UserProgress progress;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.createdAt,
    required this.progress,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      progress: UserProgress.fromJson(json['progress'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'progress': progress.toJson(),
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    DateTime? createdAt,
    UserProgress? progress,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      progress: progress ?? this.progress,
    );
  }
}

class UserProgress {
  final String userId;
  final int currentStreak;
  final int totalQuestionsAnswered;
  final int totalQuizzesCompleted;
  final Map<String, CertificationProgress> certificationProgress;
  final DateTime lastActivityDate;

  const UserProgress({
    required this.userId,
    required this.currentStreak,
    required this.totalQuestionsAnswered,
    required this.totalQuizzesCompleted,
    required this.certificationProgress,
    required this.lastActivityDate,
  });

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      userId: json['user_id'] as String,
      currentStreak: json['current_streak'] as int? ?? 0,
      totalQuestionsAnswered: json['total_questions_answered'] as int? ?? 0,
      totalQuizzesCompleted: json['total_quizzes_completed'] as int? ?? 0,
      certificationProgress: {},
      lastActivityDate: DateTime.parse(json['last_activity_date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'current_streak': currentStreak,
      'total_questions_answered': totalQuestionsAnswered,
      'total_quizzes_completed': totalQuizzesCompleted,
      'last_activity_date': lastActivityDate.toIso8601String(),
    };
  }

  factory UserProgress.initial(String userId) {
    return UserProgress(
      userId: userId,
      currentStreak: 0,
      totalQuestionsAnswered: 0,
      totalQuizzesCompleted: 0,
      certificationProgress: {},
      lastActivityDate: DateTime.now(),
    );
  }

  UserProgress copyWith({
    String? userId,
    int? currentStreak,
    int? totalQuestionsAnswered,
    int? totalQuizzesCompleted,
    Map<String, CertificationProgress>? certificationProgress,
    DateTime? lastActivityDate,
  }) {
    return UserProgress(
      userId: userId ?? this.userId,
      currentStreak: currentStreak ?? this.currentStreak,
      totalQuestionsAnswered: totalQuestionsAnswered ?? this.totalQuestionsAnswered,
      totalQuizzesCompleted: totalQuizzesCompleted ?? this.totalQuizzesCompleted,
      certificationProgress: certificationProgress ?? this.certificationProgress,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
    );
  }
}

class CertificationProgress {
  final String certificationId;
  final int questionsAnswered;
  final int correctAnswers;
  final int quizzesCompleted;
  final double averageScore;
  final DateTime lastAttempt;

  const CertificationProgress({
    required this.certificationId,
    required this.questionsAnswered,
    required this.correctAnswers,
    required this.quizzesCompleted,
    required this.averageScore,
    required this.lastAttempt,
  });

  factory CertificationProgress.fromJson(Map<String, dynamic> json) {
    return CertificationProgress(
      certificationId: json['certification_id'] as String,
      questionsAnswered: json['questions_answered'] as int? ?? 0,
      correctAnswers: json['correct_answers'] as int? ?? 0,
      quizzesCompleted: json['quizzes_completed'] as int? ?? 0,
      averageScore: (json['average_score'] as num?)?.toDouble() ?? 0.0,
      lastAttempt: DateTime.parse(json['last_attempt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'certification_id': certificationId,
      'questions_answered': questionsAnswered,
      'correct_answers': correctAnswers,
      'quizzes_completed': quizzesCompleted,
      'average_score': averageScore,
      'last_attempt': lastAttempt.toIso8601String(),
    };
  }

  factory CertificationProgress.initial(String certificationId) {
    return CertificationProgress(
      certificationId: certificationId,
      questionsAnswered: 0,
      correctAnswers: 0,
      quizzesCompleted: 0,
      averageScore: 0.0,
      lastAttempt: DateTime.now(),
    );
  }

  double get accuracyPercentage {
    if (questionsAnswered == 0) return 0.0;
    return (correctAnswers / questionsAnswered) * 100;
  }
}