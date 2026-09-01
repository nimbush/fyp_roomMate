import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:roommate_finder/common/utils/api_exception.dart';
import 'package:roommate_finder/common/utils/local_storage.dart';
import 'package:roommate_finder/common/utils/session_manager.dart';
import 'package:roommate_finder/config/app_config.dart';

import 'request_input.dart';

/// Single owner of HTTP concerns: base URL, auth header, timeout, response
/// decoding, error mapping, and session-expiry reporting.
///
/// Feature repositories receive this via `tokenBaseRepoProvider` and stay
/// declarative — a path, a body, a parser.
class BaseRepository {
  BaseRepository({required this.storage, required this.session});

  final LocalStorage storage;
  final SessionManager session;

  Future<T> get<T>(RequestInput<T> input) async {
    final response = await http
        .get(Uri.parse('${AppConfig.baseUrl}${input.path}'),
            headers: await _headers(auth: input.auth))
        .timeout(AppConfig.connectTimeout);
    return _handle(response, input.parse);
  }

  Future<T> post<T>(RequestInput<T> input) async {
    final response = await http
        .post(
          Uri.parse('${AppConfig.baseUrl}${input.path}'),
          headers: await _headers(auth: input.auth),
          body: input.body != null ? jsonEncode(input.body) : null,
        )
        .timeout(AppConfig.connectTimeout);
    return _handle(response, input.parse);
  }

  Future<T> put<T>(RequestInput<T> input) async {
    final response = await http
        .put(
          Uri.parse('${AppConfig.baseUrl}${input.path}'),
          headers: await _headers(auth: input.auth),
          body: input.body != null ? jsonEncode(input.body) : null,
        )
        .timeout(AppConfig.connectTimeout);
    return _handle(response, input.parse);
  }

  /// Multipart request (profile update with images). `fields` values are
  /// stringified; nulls are skipped so the backend keeps existing values.
  Future<T> multipart<T>(
    String method,
    String path, {
    required Map<String, Object?> fields,
    List<File> files = const [],
    String fileField = 'images',
    JsonParser<T>? parse,
  }) async {
    final request =
        http.MultipartRequest(method, Uri.parse('${AppConfig.baseUrl}$path'));
    final token = await _validToken();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    fields.forEach((key, value) {
      if (value != null) request.fields[key] = value.toString();
    });
    for (final file in files) {
      request.files
          .add(await http.MultipartFile.fromPath(fileField, file.path));
    }

    final streamed = await request.send().timeout(AppConfig.connectTimeout);
    return _handle(await http.Response.fromStream(streamed), parse);
  }

  Future<Map<String, String>> _headers({required bool auth}) async {
    if (!auth) return {'Content-Type': 'application/json'};
    final token = await _validToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Catches expiry before spending a round trip on it. The backend answers an
  /// expired token with a generic 500, so if we let the request go out we lose
  /// the ability to tell "session over" apart from "server broken".
  Future<String?> _validToken() async {
    final token = await storage.getToken();
    if (token != null && LocalStorage.isTokenExpired(token)) {
      session.reportExpired();
      throw const ApiException('Your session has expired. Please sign in again.',
          statusCode: 401);
    }
    return token;
  }

  T _handle<T>(http.Response response, JsonParser<T>? parse) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = response.body.isEmpty ? null : jsonDecode(response.body);
      if (parse != null) return parse(json);
      return json as T;
    }

    String message = 'Request failed';
    try {
      final body = jsonDecode(response.body);
      message = body['error'] ?? body['message'] ?? message;
    } catch (_) {}

    // An expired or rejected JWT must not surface as a generic error - the
    // only recovery is signing in again, so hand off to the root session
    // listener.
    if (response.statusCode == 401 || response.statusCode == 403) {
      session.reportExpired();
      throw ApiException('Your session has expired. Please sign in again.',
          statusCode: response.statusCode);
    }
    throw ApiException(message, statusCode: response.statusCode);
  }
}
