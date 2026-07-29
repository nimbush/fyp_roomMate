// Shared form validation helpers.
//
// Kept in one place so the auth screens (login, register, forgot password)
// agree on what counts as valid input.

/// Requires a local part, an `@`, a dotted domain, and a 2+ char TLD, so
/// near-misses like `a@b` or `user@example` are rejected.
final RegExp _emailPattern = RegExp(
  r'^[\w.!#$%&’*+/=?^`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?'
  r'(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$',
);

bool isValidEmail(String? value) {
  if (value == null) return false;
  final trimmed = value.trim();
  if (trimmed.isEmpty || trimmed.length > 254) return false;
  return _emailPattern.hasMatch(trimmed);
}

/// Mirrors the backend rule that a password must be at least 8 characters.
String? validatePassword(String? value) {
  if (value == null || value.isEmpty) return 'Password is required';
  if (value.length < 8) return 'Password must be at least 8 characters';
  return null;
}
