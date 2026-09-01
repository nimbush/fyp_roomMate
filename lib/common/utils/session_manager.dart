import 'package:flutter/foundation.dart';

/// Broadcasts "the session is no longer valid" from the network layer up to
/// the widget tree.
///
/// [BaseRepository] sits below the widget tree and has no `BuildContext`, so
/// it cannot navigate on its own. It reports 401/403 here instead, and the
/// root listener (see `main.dart`) clears auth state and sends the user to
/// /login.
class SessionManager {
  /// Fires when the server rejects our credentials. Listened to at the app
  /// root.
  final ValueNotifier<int> expired = ValueNotifier<int>(0);

  /// Guards against a burst of parallel requests all reporting the same
  /// expiry - several 401s in flight should produce one redirect, not five.
  bool _handling = false;

  void reportExpired() {
    if (_handling) return;
    _handling = true;
    expired.value++;
  }

  /// Called once the redirect has completed, so a later expiry can fire again.
  void reset() => _handling = false;
}
