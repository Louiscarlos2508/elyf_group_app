import 'dart:developer' as developer;
import 'app_exceptions.dart';

/// Logger centralisé pour les erreurs.
class ErrorLogger {
  ErrorLogger._();

  static final instance = ErrorLogger._();

  /// Log une erreur avec son stack trace.
  void logError(
    Object error, [
    StackTrace? stackTrace,
    String? context,
  ]) {
    final contextStr = context != null ? '[$context] ' : '';
    developer.log(
      '$contextStr$error',
      name: 'ErrorLogger',
      error: error,
      stackTrace: stackTrace,
      level: 1000, // Error level
    );
  }

  /// Log une exception AppException.
  void logAppException(
    AppException exception, [
    String? context,
  ]) {
    final contextStr = context != null ? '[$context] ' : '';
    developer.log(
      '$contextStr${exception.code ?? 'NO_CODE'}: ${exception.message}',
      name: 'ErrorLogger',
      error: exception,
      level: 1000, // Error level
    );
  }

  /// Log un warning.
  void logWarning(
    String message, [
    String? context,
  ]) {
    final contextStr = context != null ? '[$context] ' : '';
    developer.log(
      '$contextStr$message',
      name: 'ErrorLogger',
      level: 900, // Warning level
    );
  }

  /// Log une information.
  void logInfo(
    String message, [
    String? context,
  ]) {
    final contextStr = context != null ? '[$context] ' : '';
    developer.log(
      '$contextStr$message',
      name: 'ErrorLogger',
      level: 800, // Info level
    );
  }
}

