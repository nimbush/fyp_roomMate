import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:roommate_finder/common/utils/base_repository/base_repository.dart';
import 'package:roommate_finder/common/utils/base_repository/request_input.dart';
import 'package:roommate_finder/common/utils/local_storage.dart';
import 'package:roommate_finder/controller/base_repo_provider.dart';

final authRepoProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(tokenBaseRepoProvider),
    ref.watch(localStorageProvider),
  ),
);

/// Auth endpoints. All are public (`auth: false`) — they run before a token
/// exists. Successful login/verify persist the credential via [LocalStorage].
class AuthRepository {
  AuthRepository(this._repo, this._storage);

  final BaseRepository _repo;
  final LocalStorage _storage;

  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
  }) =>
      _repo.post(RequestInput<Map<String, dynamic>>(
        path: '/register',
        auth: false,
        body: {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'phoneNumber': phoneNumber,
          'password': password,
        },
        parse: (json) => (json as Map<String, dynamic>?) ?? const {},
      ));

  Future<void> verifyOtp(String email, String otp) async {
    final data = await _repo.post(RequestInput<Map<String, dynamic>>(
      path: '/verify',
      auth: false,
      body: {'email': email, 'otp': otp},
      parse: (json) => json as Map<String, dynamic>,
    ));
    await _storage.saveAuth(data['token'] as String, data['userId'] as int);
  }

  Future<void> resendOtp(String email) => _repo.post(RequestInput<void>(
        path: '/resend-otp',
        auth: false,
        body: {'email': email},
        parse: (_) {},
      ));

  Future<void> login(String email, String password) async {
    final data = await _repo.post(RequestInput<Map<String, dynamic>>(
      path: '/login',
      auth: false,
      body: {'email': email, 'password': password},
      parse: (json) => json as Map<String, dynamic>,
    ));
    await _storage.saveAuth(data['token'] as String, data['userId'] as int);
  }

  Future<void> forgotPassword(String email) => _repo.post(RequestInput<void>(
        path: '/forgot-password',
        auth: false,
        body: {'email': email},
        parse: (_) {},
      ));

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) =>
      _repo.post(RequestInput<void>(
        path: '/reset-password',
        auth: false,
        body: {'email': email, 'otp': otp, 'newPassword': newPassword},
        parse: (_) {},
      ));

  Future<void> logout() => _storage.clearAuth();
}
