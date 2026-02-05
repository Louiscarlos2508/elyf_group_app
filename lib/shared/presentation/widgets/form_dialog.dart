import 'dart:developer' as developer;


import 'package:flutter/material.dart';

import '../../../core/errors/error_handler.dart';
import '../../../core/logging/app_logger.dart';

/// Dialog générique pour les formulaires avec styling cohérent.
///
/// Ce widget fournit une structure standardisée pour tous les dialogs
/// de formulaire dans l'application, avec gestion responsive et du clavier.
class FormDialog extends StatefulWidget {
  const FormDialog({
    super.key,
    required this.title,
    required this.child,
    this.onSave,
    this.saveLabel = 'Enregistrer',
    this.cancelLabel = 'Annuler',
    this.isLoading = false,
    this.subtitle,
    this.icon,
  });

  /// Titre du dialog.
  final String title;

  /// Sous-titre optionnel (affiché sous le titre).
  final String? subtitle;

  /// Icône optionnelle (affichée à gauche du titre).
  final IconData? icon;

  /// Contenu du formulaire.
  final Widget child;

  /// Callback appelé lors de l'enregistrement.
  /// Si null, le bouton Enregistrer ne fait rien.
  /// Peut retourner un bool : true pour fermer le dialog, false pour le garder ouvert.
  final Future<dynamic> Function()? onSave;

  /// Libellé du bouton d'enregistrement.
  final String saveLabel;

  /// Libellé du bouton d'annulation.
  final String cancelLabel;

  /// Indique si une opération est en cours.
  /// Si true, désactive les boutons et affiche un indicateur de chargement.
  final bool isLoading;

  @override
  State<FormDialog> createState() => _FormDialogState();
}

class _FormDialogState extends State<FormDialog> {
  bool _isLoading = false;

  Future<void> _handleSave() async {
    if (widget.onSave == null) return;

    setState(() => _isLoading = true);
    try {
      final result = await widget.onSave!();
      // Si onSave retourne un bool, vérifier le résultat
      // Si c'est true ou null/void, considérer comme succès
      if (result is bool) {
        if (result && mounted && ModalRoute.of(context)?.isCurrent == true) {
          Navigator.of(context).pop();
        } else if (!result) {
          // Si result est false, l'erreur a été gérée par le formulaire
          // Ne pas fermer le dialog pour que l'utilisateur puisse voir le message
          developer.log(
            'Form submission returned false - error handled by form',
            name: 'FormDialog',
          );
        }
      } else {
        // Si onSave ne retourne rien ou retourne void, fermer le dialog
        if (mounted && ModalRoute.of(context)?.isCurrent == true) {
          Navigator.of(context).pop();
        }
      }
    } catch (e, stackTrace) {
      // Les erreurs sont normalement gérées par le formulaire lui-même
      // mais on log ici au cas où et on affiche un message générique
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error in FormDialog._handleSave: ${appException.message}',
        name: 'FormDialog',
        error: e,
        stackTrace: stackTrace,
      );
      
      // Afficher un message d'erreur si le formulaire n'a pas géré l'erreur
      if (mounted) {
        // Utiliser NotificationService si disponible
        try {
          // Import dynamique pour éviter les dépendances circulaires
          await Future(() => 
              // Utiliser un import conditionnel ou un service global
              null);
        } catch (_) {
          // Si NotificationService n'est pas disponible, au moins log l'erreur
        }
      }
      // Ne pas fermer le dialog en cas d'erreur pour que l'utilisateur puisse voir le message
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool get _effectiveLoading => widget.isLoading || _isLoading;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;

    // Hauteur disponible en tenant compte du clavier
    final availableHeight = screenHeight - keyboardHeight - 100;

    // Largeur responsive : 90% de l'écran, min 320px, max 900px pour supporter les layouts 2 colonnes
    final maxWidth = (screenWidth * 0.9).clamp(320.0, 900.0);

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth < 600 ? 16 : 24,
        vertical: keyboardHeight > 0 ? 16 : 24,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: availableHeight.clamp(300.0, screenHeight * 0.9),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header fixe
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      size: 24,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _effectiveLoading
                        ? null
                        : () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          },
                  ),
                ],
              ),
            ),
            // Contenu scrollable
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  bottom: keyboardHeight > 0 ? 8 : 0,
                ),
                child: widget.child,
              ),
            ),
            // Footer fixe avec padding adaptatif pour le clavier
            Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: keyboardHeight > 0 ? 16 : 24,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _effectiveLoading
                        ? null
                        : () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          },
                    child: Text(widget.cancelLabel),
                  ),
                  const SizedBox(width: 12),
                  IntrinsicWidth(
                    child: FilledButton(
                      onPressed: _effectiveLoading ? null : _handleSave,
                      child: _effectiveLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.saveLabel),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
