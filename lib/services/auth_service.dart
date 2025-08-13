import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_user;


abstract class AuthService {
  Future<app_user.User?> signIn(String email, String password);
  Future<app_user.User?> signUp(String email, String password, String name);
  Future<void> signOut();
  Stream<AuthState> get authStateChanges;
  app_user.User? get currentUser;
  bool get isAuthenticated;
}

class SupabaseAuthService implements AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<app_user.User?> signIn(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        return await _getUserProfile(response.user!.id);
      }
      return null;
    } on AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  @override
  Future<app_user.User?> signUp(String email, String password, String name) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
        emailRedirectTo: null, // Disable email confirmation redirect
      );

      if (response.user != null) {
        // Create user profile
        await _createUserProfile(response.user!.id, name, email);
        return await _getUserProfile(response.user!.id);
      }
      return null;
    } on AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  @override
  Stream<AuthState> get authStateChanges {
    return _supabase.auth.onAuthStateChange;
  }

  @override
  app_user.User? get currentUser {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      // In a real app, you'd fetch the full user profile here
      // For now, return a basic user object
      return app_user.User(
        id: user.id,
        email: user.email ?? '',
        name: user.userMetadata?['name'] ?? 'User',
        createdAt: DateTime.parse(user.createdAt),
        progress: app_user.UserProgress.initial(user.id),
      );
    }
    return null;
  }

  @override
  bool get isAuthenticated {
    return _supabase.auth.currentUser != null;
  }

  Future<void> _createUserProfile(String userId, String name, String email) async {
    try {
      await _supabase.from('user_profiles').insert({
        'id': userId,
        'name': name,
        'current_streak': 0,
        'total_questions_answered': 0,
        'total_quizzes_completed': 0,
        'last_activity_date': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Log error but don't throw - user creation should still succeed
      print('Failed to create user profile: $e');
    }
  }

  Future<app_user.User?> _getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .single();

      final user = _supabase.auth.currentUser;
      if (user != null) {
        return app_user.User(
          id: userId,
          email: user.email ?? '',
          name: response['name'] ?? 'User',
          createdAt: DateTime.parse(user.createdAt),
          progress: app_user.UserProgress(
            userId: userId,
            currentStreak: response['current_streak'] ?? 0,
            totalQuestionsAnswered: response['total_questions_answered'] ?? 0,
            totalQuizzesCompleted: response['total_quizzes_completed'] ?? 0,
            certificationProgress: {},
            lastActivityDate: DateTime.parse(
              response['last_activity_date'] ?? DateTime.now().toIso8601String(),
            ),
          ),
        );
      }
      return null;
    } catch (e) {
      // If profile doesn't exist, return basic user info
      final user = _supabase.auth.currentUser;
      if (user != null) {
        return app_user.User(
          id: userId,
          email: user.email ?? '',
          name: user.userMetadata?['name'] ?? 'User',
          createdAt: DateTime.parse(user.createdAt),
          progress: app_user.UserProgress.initial(userId),
        );
      }
      return null;
    }
  }
}

// Mock service for development/testing
class MockAuthService implements AuthService {
  app_user.User? _currentUser;
  bool _isAuthenticated = false;

  @override
  Future<app_user.User?> signIn(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Simple validation for demo
    if (email.isNotEmpty && password.length >= 6) {
      _currentUser = app_user.User(
        id: 'mock_user_id',
        email: email,
        name: 'Demo User',
        createdAt: DateTime.now(),
        progress: app_user.UserProgress.initial('mock_user_id'),
      );
      _isAuthenticated = true;
      return _currentUser;
    }
    throw Exception('Invalid credentials');
  }

  @override
  Future<app_user.User?> signUp(String email, String password, String name) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    if (email.isNotEmpty && password.length >= 6 && name.isNotEmpty) {
      _currentUser = app_user.User(
        id: 'mock_user_id',
        email: email,
        name: name,
        createdAt: DateTime.now(),
        progress: app_user.UserProgress.initial('mock_user_id'),
      );
      _isAuthenticated = true;
      return _currentUser;
    }
    throw Exception('Invalid registration data');
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
    _isAuthenticated = false;
  }

  @override
  Stream<AuthState> get authStateChanges {
    // Return a simple stream for mock purposes
    return Stream.value(AuthState(AuthChangeEvent.signedIn, null));
  }

  @override
  app_user.User? get currentUser => _currentUser;

  @override
  bool get isAuthenticated => _isAuthenticated;
}