class AppConstants {
  // App Info
  static const String appName = 'CyberQuiz Pro';
  static const String appVersion = '1.0.0';
  
  // Supabase Configuration (These should be moved to environment variables in production)
  static const String supabaseUrl = 'https://jxlxgvfxxbjlypngrdbm.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp4bHhndmZ4eGJqbHlwbmdyZGJtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUwNzc2NTMsImV4cCI6MjA3MDY1MzY1M30.pX7LLZ6NNaWnsBeyNkLu6NNfSgcf3wDE5GgcaAy5twE';
  // Quiz Configuration
  static const int defaultQuizLength = 10;
  static const int maxQuizLength = 50;
  static const int minQuizLength = 5;
  
  // Streak Configuration
  static const int maxStreakDays = 365;
  static const int streakResetHours = 24;
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double cardBorderRadius = 12.0;
  static const double buttonBorderRadius = 12.0;
  static const double minTouchTarget = 48.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Local Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String quizProgressKey = 'quiz_progress';
  static const String streakDataKey = 'streak_data';
  
  // Error Messages
  static const String networkErrorMessage = 'Network connection error. Please check your internet connection.';
  static const String authErrorMessage = 'Authentication failed. Please check your credentials.';
  static const String genericErrorMessage = 'Something went wrong. Please try again.';
  
  // Success Messages
  static const String loginSuccessMessage = 'Welcome back!';
  static const String signupSuccessMessage = 'Account created successfully!';
  static const String quizCompletedMessage = 'Quiz completed!';
}

// Certification Types
enum CertificationType {
  comptiaAPlus('CompTIA A+', 'comptia_a_plus'),
  comptiaSecurityPlus('CompTIA Security+', 'comptia_security_plus'),
  isc2CC('ISC² CC', 'isc2_cc');
  
  const CertificationType(this.displayName, this.id);
  final String displayName;
  final String id;
}

// Quiz Status
enum QuizStatus {
  notStarted,
  inProgress,
  completed,
  abandoned
}

// Question Difficulty
enum QuestionDifficulty {
  easy,
  medium,
  hard
}