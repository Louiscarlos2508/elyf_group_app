import 'package:flutter/material.dart';

import 'tracking_helpers.dart';
import '../../../../domain/entities/production_day.dart';

/// Dialog de confirmation pour supprimer un jour de production.
class PersonnelDeleteDialog {
  /// Affiche le dialog de confirmation de suppression.
  static Future<bool?> show(
    BuildContext context,
    ProductionDay day,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer le jour'),
        content: Text(
          'Supprimer le personnel et la production du ${TrackingHelpers.formatDate(day.date)} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

