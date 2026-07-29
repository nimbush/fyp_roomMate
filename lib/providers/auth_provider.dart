import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  int? _userId;
  String? _pendingEmail;

  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get userId => _userId;
  String? get pendingEmail => _pendingEmail;

  Future<bool> checkAuth() async {
    final loggedIn = await StorageService.isLoggedIn();
    if (loggedIn) {
      _userId = await StorageService.getUserId();
      notifyListeners();
    }
    return loggedIn;
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    _setLoading(true);
    try {
      await AuthService.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
      );
      _pendingEmail = email;
      _error = null;
      return true;
    } catch (e) {
      _error = friendlyError(e, 'Registration failed. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyOtp(String otp) async {
    if (_pendingEmail == null) return false;
    _setLoading(true);
    try {
      await AuthService.verifyOtp(_pendingEmail!, otp);
      _userId = await StorageService.getUserId();
      _error = null;
      return true;
    } catch (e) {
      _error = friendlyError(e, 'Invalid or expired code.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resendOtp() async {
    if (_pendingEmail == null) return;
    try {
      await AuthService.resendOtp(_pendingEmail!);
    } catch (e) {
      _error = friendlyError(e, 'Could not resend the code.');
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      await AuthService.login(email, password);
      _userId = await StorageService.getUserId();
      _error = null;
      return true;
    } catch (e) {
      _error = friendlyError(e, 'Login failed. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    try {
      await AuthService.forgotPassword(email);
      _pendingEmail = email;
      _error = null;
      return true;
    } catch (e) {
      _error = friendlyError(e, 'Could not send the reset code.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword(String otp, String newPassword) async {
    if (_pendingEmail == null) return false;
    _setLoading(true);
    try {
      await AuthService.resetPassword(
        email: _pendingEmail!,
        otp: otp,
        newPassword: newPassword,
      );
      _error = null;
      return true;
    } catch (e) {
      _error = friendlyError(e, 'Password reset failed.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    _userId = null;
    _pendingEmail = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
