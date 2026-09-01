import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:roommate_finder/common/utils/base_repository/base_repository.dart';
import 'package:roommate_finder/common/utils/base_repository/request_input.dart';
import 'package:roommate_finder/controller/base_repo_provider.dart';
import 'package:roommate_finder/features/discovery/model/discovery_user_model.dart';

final discoveryRepoProvider = Provider<DiscoveryRepository>(
  (ref) => DiscoveryRepository(ref.watch(tokenBaseRepoProvider)),
);

/// Discovery deck + swipe endpoints.
class DiscoveryRepository {
  DiscoveryRepository(this._repo);

  final BaseRepository _repo;

  Future<List<DiscoveryUserModel>> getDiscovery(int userId) =>
      _repo.get(RequestInput<List<DiscoveryUserModel>>(
        path: '/api/discovery?userId=$userId',
        parse: (json) => (json as List<dynamic>)
            .map((e) => DiscoveryUserModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      ));

  Future<void> recordSwipe({
    required int swiperId,
    required int swipedId,
    required bool liked,
  }) =>
      _repo.post(RequestInput<void>(
        path: '/api/swipes',
        body: {
          'swiperId': swiperId,
          'swipedId': swipedId,
          'liked': liked,
        },
        parse: (_) {},
      ));

  /// Whether the user's profile is complete enough to be shown a deck.
  ///
  /// The backend wraps the profile in an envelope —
  /// `{"data": {...}, "profileCompleted": bool}` — with the flag on the
  /// envelope, not the user object; fall back to the inner object for safety.
  Future<bool> getProfileCompleted(int userId) =>
      _repo.get(RequestInput<bool>(
        path: '/api/profile?userId=$userId',
        parse: (json) {
          final map = json as Map<String, dynamic>;
          final flag = map['profileCompleted'] ??
              (map['data'] is Map<String, dynamic>
                  ? (map['data'] as Map<String, dynamic>)['profileCompleted']
                  : null);
          return flag as bool? ?? false;
        },
      ));
}
