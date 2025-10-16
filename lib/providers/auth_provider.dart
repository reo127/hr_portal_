import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
}

class AuthProvider with ChangeNotifier {
  final AuthService _authService;

  AuthStatus _status = AuthStatus.uninitialized;
  User? _user;
  String? _errorMessage;
  bool _isLoading = false;

  AuthProvider({AuthService? authService})
      : _authService = authService ?? AuthService();

  // Getters
  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // Initialize auth state (check if user is already logged in)
  Future<void> checkAuthStatus() async {
    try {
      final isAuth = await _authService.isAuthenticated();

      if (isAuth) {
        _user = await _authService.getCurrentUser();
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
        _user = null;
      }

      notifyListeners();
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _user = null;
      notifyListeners();
    }
  }

  // Login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _user = await _authService.login(email: email, password: password);
      _status = AuthStatus.authenticated;
      _isLoading = false;

      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _user = null;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;

      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _authService.logout();
      _status = AuthStatus.unauthenticated;
      _user = null;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Logout failed: $e';
      notifyListeners();
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Get token for API calls
  Future<String?> getToken() async {
    return _user?.token;
  }
}
