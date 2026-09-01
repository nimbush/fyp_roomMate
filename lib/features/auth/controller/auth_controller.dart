import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:roommate_finder/common/utils/api_exception.dart';
import 'package:roommate_finder/common/utils/local_storage.dart';
import 'package:roommate_finder/controller/base_repo_provider.dart';
import 'package:roommate_finder/features/auth/repo/auth_repository.dart';

/// Sentinel so [AuthState.copyWith] can tell "leave unchanged" apart from
/// "explicitly set to null" for its nullable fields.
const Object _unset = Object();

class AuthState {
  const AuthState({
    this.isLoading = false,
    this.error,
    this.userId,
    this.pendingEmail,
  });

  final bool isLoading;
  final String? error;
  final int? userId;

  /// The email an OTP was last sent to; verify/resend/reset act on it.
  final String? pendingEmail;

  AuthState copyWith({
    bool? isLoading,
    Object? error = _unset,
    Object? userId = _unset,
    Object? pendingEmail = _unset,
  }) =>
      AuthState(
        isLoading: isLoading ?? this.isLoading,
        error: error == _unset ? this.error : error as String?,
        userId: userId == _unset ? this.userId : userId as int?,
        pendingEmail:
            pendingEmail == _unset ? this.pendingEmail : pendingEmail as String?,
      );
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(
    ref.watch(authRepoProvider),
    ref.watch(localStorageProvider),
  ),
);

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repo, this._storage) : super(const AuthState());

  final AuthRepository _repo;
  final LocalStorage _storage;

  Future<bool> checkAuth() async {
    final loggedIn = await _storage.isLoggedIn();
    if (loggedIn) {
      state = state.copyWith(userId: await _storage.getUserId());
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
    state = state.copyWith(isLoading: true);
    try {
      await _repo.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
      );
      state = state.copyWith(pendingEmail: email, error: null);
      return true;
    } catch (e) {
      state = state.copyWith(
          error: friendlyError(e, 'Registration failed. Please try again.'));
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> verifyOtp(String otp) async {
    final email = state.pendingEmail;
    if (email == null) return false;
    state = state.copyWith(isLoading: true);
    try {
      await _repo.verifyOtp(email, otp);
      state = state.copyWith(userId: await _storage.getUserId(), error: null);
      return true;
    } catch (e) {
      state = state.copyWith(error: friendlyError(e, 'Invalid or expired code.'));
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> resendOtp() async {
    final email = state.pendingEmail;
    if (email == null) return;
    try {
      await _repo.resendOtp(email);
    } catch (e) {
      state =
          state.copyWith(error: friendlyError(e, 'Could not resend the code.'));
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repo.login(email, password);
      state = state.copyWith(userId: await _storage.getUserId(), error: null);
      return true;
    } catch (e) {
      state = state.copyWith(
          error: friendlyError(e, 'Login failed. Please try again.'));
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repo.forgotPassword(email);
      state = state.copyWith(pendingEmail: email, error: null);
      return true;
    } catch (e) {
      state = state.copyWith(
          error: friendlyError(e, 'Could not send the reset code.'));
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> resetPassword(String otp, String newPassword) async {
    final email = state.pendingEmail;
    if (email == null) return false;
    state = state.copyWith(isLoading: true);
    try {
      await _repo.resetPassword(email: email, otp: otp, newPassword: newPassword);
      state = state.copyWith(error: null);
      return true;
    } catch (e) {
      state = state.copyWith(error: friendlyError(e, 'Password reset failed.'));
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = state.copyWith(userId: null, pendingEmail: null);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
