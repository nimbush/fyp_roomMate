import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:roommate_finder/common/utils/base_repository/base_repository.dart';
import 'package:roommate_finder/common/utils/local_storage.dart';
import 'package:roommate_finder/common/utils/session_manager.dart';

final localStorageProvider = Provider<LocalStorage>((ref) => LocalStorage());

final sessionManagerProvider =
    Provider<SessionManager>((ref) => SessionManager());

/// The token-attaching HTTP gateway every feature repository is built on.
final tokenBaseRepoProvider = Provider<BaseRepository>(
  (ref) => BaseRepository(
    storage: ref.watch(localStorageProvider),
    session: ref.watch(sessionManagerProvider),
  ),
);
