/// Lifecycle of an async load, exposed by feature controllers.
///
/// Named `Failure` rather than `Error` to avoid shadowing `dart:core`'s
/// [Error] in every file that imports this one.
sealed class GenericState<T> {
  const GenericState();

  /// The data if the state is [Success], otherwise null.
  T? dataOrNull() => switch (this) {
        Success<T>(:final data) => data,
        _ => null,
      };

  /// Executes the callback matching the current state.
  R when<R>({
    required R Function() empty,
    required R Function() loading,
    required R Function(T data) success,
    required R Function(String message, int? statusCode) failure,
  }) =>
      switch (this) {
        Empty<T>() => empty(),
        Loading<T>() => loading(),
        Success<T>(:final data) => success(data),
        Failure<T>(:final message, :final statusCode) =>
          failure(message, statusCode),
      };

  /// Like [when], but unhandled states resolve to null.
  R? whenOrNull<R>({
    R Function()? empty,
    R Function()? loading,
    R Function(T data)? success,
    R Function(String message, int? statusCode)? failure,
  }) =>
      switch (this) {
        Empty<T>() => empty?.call(),
        Loading<T>() => loading?.call(),
        Success<T>(:final data) => success?.call(data),
        Failure<T>(:final message, :final statusCode) =>
          failure?.call(message, statusCode),
      };
}

class Empty<T> extends GenericState<T> {
  const Empty();
}

class Loading<T> extends GenericState<T> {
  const Loading();
}

class Success<T> extends GenericState<T> {
  const Success(this.data);

  final T data;
}

class Failure<T> extends GenericState<T> {
  const Failure(this.message, {this.statusCode});

  final String message;
  final int? statusCode;
}
