import 'package:flutter/material.dart';

import 'notification_service.dart';

/// Mixin pour simplifier les patterns répétés dans les formulaires.
/// 
/// Fournit des helpers pour la gestion des états de chargement,
/// la validation et la soumission de formulaires avec gestion d'erreur automatique.
mixin FormHelperMixin<T extends StatefulWidget> on State<T> {
  /// Gère la soumission d'un formulaire avec gestion automatique des erreurs.
  /// 
  /// [context] : Le BuildContext pour les notifications
  /// [formKey] : La clé du formulaire à valider
  /// [onSubmit] : Fonction async à exécuter lors de la soumission
  /// [onLoadingChanged] : Callback appelé quand l'état de chargement change
  /// [successMessage] : Message de succès à afficher (optionnel, peut être retourné par onSubmit)
  /// 
  /// Retourne true si la soumission a réussi, false sinon.
  Future<bool> handleFormSubmit({
    required BuildContext context,
    required GlobalKey<FormState> formKey,
    required Future<String?> Function() onSubmit,
    required void Function(bool) onLoadingChanged,
    String? successMessage,
  }) async {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    onLoadingChanged(true);
    try {
      final message = await onSubmit();
      final finalMessage = message ?? successMessage;
      
      if (mounted && context.mounted && finalMessage != null) {
        NotificationService.showSuccess(context, finalMessage);
      }
      
      return true;
    } catch (e) {
      if (mounted && context.mounted) {
        NotificationService.showError(context, e.toString());
      }
      return false;
    } finally {
      if (mounted) {
        onLoadingChanged(false);
      }
    }
  }

  /// Valide et soumet un formulaire avec gestion automatique.
  /// 
  /// Version simplifiée qui combine validation et soumission.
  Future<bool> validateAndSubmit({
    required BuildContext context,
    required GlobalKey<FormState> formKey,
    required Future<String?> Function() onSubmit,
    required void Function(bool) onLoadingChanged,
  }) async {
    return handleFormSubmit(
      context: context,
      formKey: formKey,
      onSubmit: onSubmit,
      onLoadingChanged: onLoadingChanged,
    );
  }
}

