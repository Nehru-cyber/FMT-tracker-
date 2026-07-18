import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _biometricAvailable = false;
  bool _rememberMeEnabled = false;
  final Completer<void> _initCompleter = Completer<void>();
  
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isGuest => _user?.isGuest ?? false;
  bool get isPremium => _user?.isPremium ?? false;
  bool get biometricAvailable => _biometricAvailable;
  bool get biometricEnabled => _user?.biometricEnabled ?? false;
  bool get rememberMeEnabled => _rememberMeEnabled;
  bool get canQuickLogin => _biometricAvailable && _rememberMeEnabled;

  /// Completes when the initial user load from DB is done.
  Future<void> get initialized => _initCompleter.future;
  
  AuthProvider() {
    _loadUser();
    _checkBiometric();
  }
  
  Future<void> _loadUser() async {
    try {
      if (!DatabaseService.isInitialized) {
        if (!_initCompleter.isCompleted) _initCompleter.complete();
        return;
      }
      _user = await DatabaseService.getLoggedInUser();
      notifyListeners();
    } catch (e) {
      debugPrint('AuthProvider._loadUser error: $e');
    } finally {
      if (!_initCompleter.isCompleted) _initCompleter.complete();
    }
  }

  /// Refresh user data from DB (e.g. after premium activation).
  Future<void> refreshUser() async {
    if (!DatabaseService.isInitialized) return;
    _user = await DatabaseService.getLoggedInUser();
    notifyListeners();
  }

  Future<void> _checkBiometric() async {
    _biometricAvailable = await AuthService.isBiometricAvailable();
    _rememberMeEnabled = await AuthService.isRememberMeEnabled();
    notifyListeners();
  }
  
  Future<bool> loginWithEmail(String email, String password, {bool rememberMe = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _user = await AuthService.loginWithEmail(email: email, password: password);
      
      // Save credentials if remember me is checked
      if (rememberMe) {
        await AuthService.saveCredentials(email, password);
      } else {
        await AuthService.clearSavedCredentials();
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> registerWithEmail(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _user = await AuthService.registerWithEmail(
        name: name,
        email: email,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> loginAsGuest() async {
    _isLoading = true;
    notifyListeners();
    
    _user = await AuthService.loginAsGuest();
    _isLoading = false;
    notifyListeners();
    return true;
  }

  // Quick login using saved credentials + biometric verification
  Future<bool> quickLoginWithBiometric() async {
    if (!_biometricAvailable) return false;

    final authenticated = await AuthService.authenticateWithBiometrics();
    if (!authenticated) return false;

    _isLoading = true;
    notifyListeners();

    _user = await AuthService.quickLogin();
    _isLoading = false;
    notifyListeners();
    return _user != null;
  }


  Future<void> logout() async {
    await AuthService.logout();
    _user = null;
    notifyListeners();
  }
  
  Future<bool> enableBiometric() async {
    final success = await AuthService.enableBiometricLock();
    if (success) {
      _user = await DatabaseService.getLoggedInUser();
      notifyListeners();
    }
    return success;
  }

  Future<bool> disableBiometric() async {
    final success = await AuthService.disableBiometricLock();
    if (success) {
      _user = await DatabaseService.getLoggedInUser();
      notifyListeners();
    }
    return success;
  }
  
  void updateUser(User user) {
    _user = user;
    notifyListeners();
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
