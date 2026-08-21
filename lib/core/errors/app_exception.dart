class AppException implements Exception {
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  const AppException(this.message, {this.cause, this.stackTrace});

  @override
  String toString() => message;
}

class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.cause, super.stackTrace});
}

class ValidationException extends AppException {
  const ValidationException(super.message, {super.cause, super.stackTrace});
}

class UnknownException extends AppException {
  const UnknownException(super.message, {super.cause, super.stackTrace});
}
