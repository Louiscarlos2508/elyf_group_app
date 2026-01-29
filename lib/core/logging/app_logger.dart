import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Service de logging centralisé pour l'application.
///
/// Remplace tous les `debugPrint` et fournit une interface cohérente
/// pour le logging avec différents niveaux.
///
/// Utilise `dart:developer` pour un logging structuré qui s'intègre
/// avec Dart DevTools.
///
/// Exemple d'utilisation:
/// ```dart
/// AppLogger.debug('Message de debug', name: 'module.auth');
/// AppLogger.info('Opération réussie', name: 'module.auth');
/// AppLogger.warning('Attention: valeur par défaut utilisée', name: 'module.auth');
/// AppLogger.error('Erreur lors de la connexion', error: e, stackTrace: st, name: 'module.auth');
/// ```
class AppLogger {
  AppLogger._();

  /// Log un message de debug.
  ///
  /// Les messages de debug ne sont loggés qu'en mode debug (kDebugMode).
  /// Utilisez ce niveau pour des informations détaillées utiles uniquement
  /// pendant le développement.
  ///
  /// [message] Le message à logger.
  /// [name] Le nom du logger (ex: 'module.auth', 'module.gaz').
  /// [error] L'erreur associée (optionnel).
  /// [stackTrace] La stack trace (optionnel).
  static void debug(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      developer.log(
        message,
        name: name ?? 'app',
        error: error,
        stackTrace: stackTrace,
        level: 700, // Debug level
      );
    }
  }

  /// Log un message d'information.
  ///
  /// Utilisez ce niveau pour des informations générales sur le fonctionnement
  /// de l'application.
  ///
  /// [message] Le message à logger.
  /// [name] Le nom du logger (ex: 'module.auth', 'module.gaz').
  /// [error] L'erreur associée (optionnel).
  /// [stackTrace] La stack trace (optionnel).
  static void info(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: name ?? 'app',
      error: error,
      stackTrace: stackTrace,
      level: 800, // Info level
    );
  }

  /// Log un avertissement.
  ///
  /// Utilisez ce niveau pour des situations qui ne sont pas des erreurs
  /// mais qui méritent attention.
  ///
  /// [message] Le message à logger.
  /// [name] Le nom du logger (ex: 'module.auth', 'module.gaz').
  /// [error] L'erreur associée (optionnel).
  /// [stackTrace] La stack trace (optionnel).
  static void warning(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: name ?? 'app',
      error: error,
      stackTrace: stackTrace,
      level: 900, // Warning level
    );
  }

  /// Log une erreur.
  ///
  /// Utilisez ce niveau pour les erreurs qui doivent être tracées.
  /// Toujours fournir [error] et [stackTrace] si disponibles.
  ///
  /// [message] Le message à logger.
  /// [name] Le nom du logger (ex: 'module.auth', 'module.gaz').
  /// [error] L'erreur associée (recommandé).
  /// [stackTrace] La stack trace (recommandé).
  static void error(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: name ?? 'app',
      error: error,
      stackTrace: stackTrace,
      level: 1000, // Error level (SEVERE)
    );
  }

  /// Log une erreur critique.
  ///
  /// Utilisez ce niveau pour les erreurs critiques qui nécessitent
  /// une attention immédiate.
  ///
  /// [message] Le message à logger.
  /// [name] Le nom du logger (ex: 'module.auth', 'module.gaz').
  /// [error] L'erreur associée (recommandé).
  /// [stackTrace] La stack trace (recommandé).
  static void critical(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: name ?? 'app',
      error: error,
      stackTrace: stackTrace,
      level: 1200, // Critical level
    );
  }
}
