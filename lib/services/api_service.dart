import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

/// Turns raw exceptions into text safe to show in the UI.
///
/// `ApiException` already carries a server-authored message, but socket and
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

class ApiService {
  static Future<Map<String, String>> _authHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<dynamic> get(String path) async {
    final headers = await _authHeaders();
    final response = await http
        .get(Uri.parse('${AppConfig.baseUrl}$path'), headers: headers)
        .timeout(AppConfig.connectTimeout);
    return _handle(response);
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body,
      {bool auth = true}) async {
    final headers = auth
        ? await _authHeaders()
        : {'Content-Type': 'application/json'};
    final response = await http
        .post(
          Uri.parse('${AppConfig.baseUrl}$path'),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(AppConfig.connectTimeout);
    return _handle(response);
  }

  static Future<dynamic> put(String path,
      {Map<String, dynamic>? body}) async {
    final headers = await _authHeaders();
    final response = await http
        .put(
          Uri.parse('${AppConfig.baseUrl}$path'),
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(AppConfig.connectTimeout);
    return _handle(response);
  }

  static dynamic _handle(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    String message = 'Request failed';
    try {
      final body = jsonDecode(response.body);
      message = body['error'] ?? body['message'] ?? message;
    } catch (_) {}
    throw ApiException(message, statusCode: response.statusCode);
  }
}
