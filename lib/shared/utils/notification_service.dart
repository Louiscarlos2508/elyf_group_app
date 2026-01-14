import 'package:flutter/material.dart';

/// Service centralisé pour afficher des notifications (SnackBar) dans l'application.
///
/// Ce service élimine la duplication de code en fournissant des méthodes
/// standardisées pour afficher des messages de succès, d'erreur, d'information
/// et d'avertissement.
class NotificationService {
  NotificationService._();

  /// Affiche un message de succès (SnackBar verte).
  ///
  /// [context] : Le BuildContext pour accéder au ScaffoldMessenger
  /// [message] : Le message à afficher
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  /// Affiche un message d'erreur (SnackBar rouge).
  ///
  /// Nettoie automatiquement le préfixe "Exception: " si présent.
  ///
  /// [context] : Le BuildContext pour accéder au ScaffoldMessenger
  /// [message] : Le message d'erreur à afficher
  static void showError(BuildContext context, String message) {
    if (!context.mounted) return;

    // Nettoyer le préfixe "Exception: " si présent
    final cleanMessage = message.replaceAll('Exception: ', '');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur: $cleanMessage'),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Affiche un message d'information (SnackBar bleue).
  ///
  /// [context] : Le BuildContext pour accéder au ScaffoldMessenger
  /// [message] : Le message informatif à afficher
  static void showInfo(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.blue),
    );
  }

  /// Affiche un message d'avertissement (SnackBar orange).
  ///
  /// [context] : Le BuildContext pour accéder au ScaffoldMessenger
  /// [message] : Le message d'avertissement à afficher
  static void showWarning(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.orange),
    );
  }
}
