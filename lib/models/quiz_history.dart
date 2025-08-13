import 'package:hive/hive.dart';
import 'quiz.dart';

part 'quiz_history.g.dart';

@HiveType(typeId: 0)
class QuizHistoryEntry extends HiveObject {
  @HiveField(0)
  String quizId;

  @HiveField(1)
  String userId;

  @HiveField(2)
  String certificationId;

  @HiveField(3)
  String? sectionId;

  @HiveField(4)
  double scorePercentage;

  @HiveField(5)
  int correctAnswers;

  @HiveField(6)
  int totalQuestions;

  @HiveField(7)
  int timeTakenSeconds;

  @HiveField(8)
  DateTime completedAt;

  @HiveField(9)
  String certificationName;

  @HiveField(10)
  String? sectionName;

  QuizHistoryEntry({
    required this.quizId,
    required this.userId,
    required this.certificationId,
    this.sectionId,
    required this.scorePercentage,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.timeTakenSeconds,
    required this.completedAt,
    required this.certificationName,
    this.sectionName,
  });

  // Convert from QuizResult for easy storage
  factory QuizHistoryEntry.fromQuizResult(
    QuizResult result,
    String userId,
    String certificationId,
    String certificationName, {
    String? sectionId,
    String? sectionName,
  }) {
    return QuizHistoryEntry(
      quizId: result.quizId,
      userId: userId,
      certificationId: certificationId,
      sectionId: sectionId,
      scorePercentage: result.scorePercentage,
      correctAnswers: result.correctAnswers,
      totalQuestions: result.totalQuestions,
      timeTakenSeconds: result.timeTaken.inSeconds,
      completedAt: result.completedAt,
      certificationName: certificationName,
      sectionName: sectionName,
    );
  }

  // Convert to map for easy Supabase migration
  Map<String, dynamic> toSupabaseMap() {
    return {
      'quiz_id': quizId,
      'user_id': userId,
      'certification_id': certificationId,
      'section_id': sectionId,
      'score_percentage': scorePercentage,
      'correct_answers': correctAnswers,
      'total_questions': totalQuestions,
      'time_taken_seconds': timeTakenSeconds,
      'completed_at': completedAt.toIso8601String(),
      'certification_name': certificationName,
      'section_name': sectionName,
    };
  }

  // Create from Supabase data (for future migration)
  factory QuizHistoryEntry.fromSupabaseMap(Map<String, dynamic> map) {
    return QuizHistoryEntry(
      quizId: map['quiz_id'],
      userId: map['user_id'],
      certificationId: map['certification_id'],
      sectionId: map['section_id'],
      scorePercentage: (map['score_percentage'] as num).toDouble(),
      correctAnswers: map['correct_answers'],
      totalQuestions: map['total_questions'],
      timeTakenSeconds: map['time_taken_seconds'],
      completedAt: DateTime.parse(map['completed_at']),
      certificationName: map['certification_name'],
      sectionName: map['section_name'],
    );
  }

  Duration get timeTaken => Duration(seconds: timeTakenSeconds);
  
  bool get isPassing => scorePercentage >= 70.0;
  
  String get grade {
    if (scorePercentage >= 90) return 'A';
    if (scorePercentage >= 80) return 'B';
    if (scorePercentage >= 70) return 'C';
    if (scorePercentage >= 60) return 'D';
    return 'F';
  }
}