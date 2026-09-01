import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:roommate_finder/common/utils/base_repository/base_repository.dart';
import 'package:roommate_finder/common/utils/base_repository/request_input.dart';
import 'package:roommate_finder/controller/base_repo_provider.dart';

final settingsRepoProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(tokenBaseRepoProvider)),
);

/// Static content (`GET /api/services/{service}`) and the help & support
/// submission (`POST /api/support`).
class SettingsRepository {
  SettingsRepository(this._base);

  final BaseRepository _base;

  /// Returns the raw `{title, content}` payload for a service page
  /// (NOTIFICATION / PRIVACY / TERMS / ABOUT / FAQ).
  Future<Map<String, dynamic>> getContent(String service) => _base.get(
        RequestInput(
          path: '/api/services/$service',
          parse: (json) => json as Map<String, dynamic>,
        ),
      );

  Future<void> submitSupport({
    required String username,
    required String phoneNumber,
    required String email,
    required String title,
    required String body,
  }) async {
    await _base.post<dynamic>(
      RequestInput(
        path: '/api/support',
        body: {
          'username': username,
          'phoneNumber': phoneNumber,
          'email': email,
          'title': title,
          'body': body,
        },
      ),
    );
  }
}
