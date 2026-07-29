import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    final data = await ApiService.post('/register', {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'password': password,
    }, auth: false);
    return data as Map<String, dynamic>;
  }

  static Future<void> verifyOtp(String email, String otp) async {
    final data = await ApiService.post('/verify', {
      'email': email,
      'otp': otp,
    }, auth: false) as Map<String, dynamic>;
    final token = data['token'] as String;
    final userId = data['userId'] as int;
    await StorageService.saveAuth(token, userId);
  }

  static Future<void> resendOtp(String email) async {
    await ApiService.post('/resend-otp', {'email': email}, auth: false);
  }

  static Future<void> login(String email, String password) async {
    final data = await ApiService.post('/login', {
      'email': email,
      'password': password,
    }, auth: false) as Map<String, dynamic>;
    final token = data['token'] as String;
    final userId = data['userId'] as int;
    await StorageService.saveAuth(token, userId);
  }

  static Future<void> forgotPassword(String email) async {
    await ApiService.post('/forgot-password', {'email': email}, auth: false);
  }

  static Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await ApiService.post('/reset-password', {
      'email': email,
      'otp': otp,
      'newPassword': newPassword,
    }, auth: false);
  }

  static Future<void> logout() async {
    await StorageService.clearAuth();
  }
}
