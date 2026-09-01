import 'dart:async';
import 'dart:io';

/// A server-reported failure carrying a message already safe to show users.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Turns raw exceptions into text safe to show in the UI.
///
/// [ApiException] already carries a server-authored message, but socket and
/// timeout failures stringify to Dart internals (`SocketException: ... errno`)
/// which must never reach the user.
String friendlyError(Object e, String fallback) {
  if (e is ApiException) return e.message;
  if (e is SocketException) {
    return 'Cannot reach the server. Check your connection and try again.';
  }
  if (e is TimeoutException) {
    return 'The server took too long to respond. Please try again.';
  }
  return fallback;
}
