import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persisted auth credentials. Injected (via `localStorageProvider`) rather
/// than accessed statically so repositories and controllers stay testable.
class LocalStorage {
  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'user_id';

  Future<void> saveAuth(String token, int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setInt(_userIdKey, userId);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return false;
    if (!isTokenExpired(token)) return true;

    // Don't leave a dead credential sitting on disk once we know it's expired.
    await clearAuth();
    return false;
  }

  /// Reads the `exp` claim straight off the JWT payload.
  ///
  /// The backend's JwtFilter lets an expired-token exception escape as a 500
  /// with a generic Spring error body, so the response gives us nothing to
  /// detect expiry with. The token itself does - and checking it locally also
  /// avoids a pointless round trip on a session we already know is dead.
  ///
  /// Returns true when the token is unreadable: a token we cannot parse is not
  /// one we should trust.
  static bool isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      // Base64url payloads arrive without padding; normalize before decoding.
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;

      final exp = payload['exp'];
      if (exp is! int) return true;

      // `exp` is in seconds since epoch, DateTime works in milliseconds.
      final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      // Treat a token about to lapse as already gone, so a request cannot die
      // in flight seconds after we approved it.
      return DateTime.now()
          .isAfter(expiry.subtract(const Duration(seconds: 30)));
    } catch (_) {
      return true;
    }
  }
}
