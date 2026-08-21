import 'app_exception.dart';

abstract final class ErrorHandler {
  static AppException handle(Object error, [StackTrace? stackTrace]) {
    if (error is AppException) {
      return error;
    }

    return UnknownException(
      'Something went wrong. Please try again.',
      cause: error,
      stackTrace: stackTrace,
    );
  }

  static String userMessage(Object error) {
    if (error is AppException) {
      return error.message;
    }

    return 'Something went wrong. Please try again.';
  }
}
