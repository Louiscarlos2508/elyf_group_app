import '../logging/app_logger.dart';
import 'app_exceptions.dart';

/// Logger centralisé pour les erreurs.
class ErrorLogger {
  ErrorLogger._();

  static final instance = ErrorLogger._();

  /// Log une erreur avec son stack trace.
  void logError(Object error, [StackTrace? stackTrace, String? context]) {
    AppLogger.error(
      error.toString(),
      name: 'ErrorLogger',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log une exception AppException.
  void logAppException(AppException exception, [String? context]) {
    AppLogger.error(
      '${exception.code ?? 'NO_CODE'}: ${exception.message}',
      name: 'ErrorLogger',
      error: exception,
    );
  }

  /// Log un warning.
  void logWarning(String message, [String? context]) {
    AppLogger.warning(
      message,
      name: 'ErrorLogger',
    );
  }

  /// Log une information.
  void logInfo(String message, [String? context]) {
    AppLogger.info(
      message,
      name: 'ErrorLogger',
    );
  }
}
