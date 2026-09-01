/// How to parse a decoded JSON body into the caller's type.
typedef JsonParser<T> = T Function(dynamic json);

/// One request's worth of configuration for [BaseRepository].
///
/// Repositories describe *what* to call and how to parse it; the base
/// repository owns *how* (headers, auth, timeout, error mapping).
class RequestInput<T> {
  const RequestInput({
    required this.path,
    this.parse,
    this.body,
    this.auth = true,
  });

  /// Path appended to the configured base URL, e.g. `/api/profile`.
  final String path;

  /// Maps the decoded JSON body to [T]. Omit for void endpoints — the raw
  /// decoded body is returned (or null on an empty response).
  final JsonParser<T>? parse;

  /// JSON body for POST/PUT requests.
  final Map<String, dynamic>? body;

  /// Whether to attach the bearer token. Public endpoints (login, register)
  /// opt out.
  final bool auth;
}
