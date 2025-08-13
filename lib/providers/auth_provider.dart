import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider(this._authService) {
    _initializeAuth();
  }

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  void _initializeAuth() {
    _user = _authService.currentUser;
    
    // Listen to auth state changes
    _authService.authStateChanges.listen((authState) {
      _user = _authService.currentUser;
      notifyListeners();
    });
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      final user = await _authService.signIn(email, password);
      if (user != null) {
        _user = user;
        _setLoading(false);
        notifyListeners();
        return true;
      }
      _setError('Sign in failed');
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUp(String email, String password, String name) async {
    _setLoading(true);
    _clearError();
    
    try {
      final user = await _authService.signUp(email, password, name);
      if (user != null) {
        _user = user;
        _setLoading(false);
        notifyListeners();
        return true;
      }
      _setError('Sign up failed');
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void updateUserProgress(UserProgress progress) {
    if (_user != null) {
      _user = _user!.copyWith(progress: progress);
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }
}