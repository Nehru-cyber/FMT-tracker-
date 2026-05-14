import '../models/user.dart';
import 'database_service.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  static final LocalAuthentication _localAuth = LocalAuthentication();

  // Check if biometric hardware is available
  static Future<bool> isBiometricAvailable() async {
    if (kIsWeb) return false;
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck || isDeviceSupported;
    } on PlatformException {
      return false;
    }
  }

  // Get available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  // Authenticate with biometrics (fingerprint / face ID)
  static Future<bool> authenticateWithBiometrics() async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) return false;

      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to access FMT Tracker',
      );
    } on PlatformException {
      return false;
    }
  }

  // Register with email/password
  static Future<User?> registerWithEmail({
    required String name,
    required String email,
    required String password,
    String phone = '',
  }) async {
    try {
      final existingUser = await DatabaseService.findUserByEmail(email.toLowerCase());

      if (existingUser != null) {
        throw Exception('User with this email already exists');
      }

      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        email: email,
        phone: phone,
        password: _hashPassword(password),
      );

      await DatabaseService.saveUser(user);
      // Mark this user as currently logged in
      await DatabaseService.saveSetting('currentUserId', user.id);
      return user;
    } catch (e) {
      rethrow;
    }
  }

  // Login with email/password
  static Future<User?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final user = await DatabaseService.findUserByEmail(email.toLowerCase());

      if (user == null) {
        throw Exception('User not found');
      }

      if (user.password != _hashPassword(password)) {
        throw Exception('Invalid password');
      }

      // Mark this user as currently logged in
      await DatabaseService.saveSetting('currentUserId', user.id);
      return user;
    } catch (e) {
      rethrow;
    }
  }

  // Login as guest
  static Future<User> loginAsGuest() async {
    final user = User.guest();
    await DatabaseService.saveUser(user);
    await DatabaseService.saveSetting('currentUserId', user.id);
    return user;
  }

  // Enable biometric lock for the current user
  static Future<bool> enableBiometricLock() async {
    final isAvailable = await isBiometricAvailable();
    if (!isAvailable) return false;

    // Verify biometric first
    final authenticated = await authenticateWithBiometrics();
    if (!authenticated) return false;

    final user = await DatabaseService.getLoggedInUser();
    if (user == null) return false;

    final updatedUser = user.copyWith(biometricEnabled: true);
    await DatabaseService.saveUser(updatedUser);
    return true;
  }

  // Disable biometric lock
  static Future<bool> disableBiometricLock() async {
    final user = await DatabaseService.getLoggedInUser();
    if (user == null) return false;

    final updatedUser = user.copyWith(biometricEnabled: false);
    await DatabaseService.saveUser(updatedUser);
    return true;
  }

  // Save credentials for quick login (remember me)
  static Future<void> saveCredentials(String email, String password) async {
    await DatabaseService.saveSetting('saved_email', email);
    await DatabaseService.saveSetting('saved_password', _hashPassword(password));
    await DatabaseService.saveSetting('remember_me', true);
  }

  // Get saved credentials
  static Future<Map<String, String?>> getSavedCredentials() async {
    final rememberMe = await DatabaseService.getSetting('remember_me', defaultValue: false);
    if (rememberMe != true) return {'email': null, 'password': null};
    return {
      'email': await DatabaseService.getSetting('saved_email'),
    };
  }

  // Check if remember me is enabled
  static Future<bool> isRememberMeEnabled() async {
    return await DatabaseService.getSetting('remember_me', defaultValue: false) == true;
  }

  // Clear saved credentials
  static Future<void> clearSavedCredentials() async {
    await DatabaseService.saveSetting('saved_email', null);
    await DatabaseService.saveSetting('saved_password', null);
    await DatabaseService.saveSetting('remember_me', false);
  }

  // Quick login with saved credentials (biometric verified)
  static Future<User?> quickLogin() async {
    final savedEmail = await DatabaseService.getSetting('saved_email');
    final savedPasswordHash = await DatabaseService.getSetting('saved_password');

    if (savedEmail == null || savedPasswordHash == null) return null;

    final user = await DatabaseService.findUserByEmail(savedEmail.toString().toLowerCase());

    if (user == null) return null;
    if (user.password != savedPasswordHash) return null;

    await DatabaseService.saveSetting('currentUserId', user.id);
    return user;
  }

  // Logout
  static Future<void> logout() async {
    final user = await DatabaseService.getLoggedInUser();
    if (user != null && user.isGuest) {
      // Clear guest data completely
      await DatabaseService.clearAllData();
    }
    // Clear the current session (but keep the user account data)
    await DatabaseService.saveSetting('currentUserId', null);
  }

  // Simple password hashing
  static String _hashPassword(String password) {
    var hash = 0;
    for (var i = 0; i < password.length; i++) {
      hash = ((hash << 5) - hash) + password.codeUnitAt(i);
      hash = hash & hash;
    }
    return hash.toString();
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    return await DatabaseService.getLoggedInUser() != null;
  }

  // Get current user
  static Future<User?> getCurrentUser() async {
    return await DatabaseService.getLoggedInUser();
  }
}
