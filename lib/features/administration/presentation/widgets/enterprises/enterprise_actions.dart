import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/enterprise.dart';
import '../../../../../shared/utils/notification_service.dart';
import '../../screens/sections/dialogs/create_enterprise_dialog.dart';
import '../../screens/sections/dialogs/edit_enterprise_dialog.dart';

/// Utility class for enterprise-related actions.
class EnterpriseActions {
  EnterpriseActions._();

  /// Shows the create enterprise dialog and handles the result.
  static Future<void> create(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<Enterprise>(
      context: context,
      builder: (context) => const CreateEnterpriseDialog(),
    );

    if (result != null) {
      try {
        await ref.read(enterpriseControllerProvider).createEnterprise(result);
        ref.invalidate(enterprisesProvider);
        if (context.mounted) {
          NotificationService.showSuccess(context, 'Entreprise créée');
        }
      } catch (e) {
        if (context.mounted) {
          NotificationService.showError(context, e.toString());
        }
      }
    }
  }

  /// Shows the edit enterprise dialog and handles the result.
  static Future<void> edit(
    BuildContext context,
    WidgetRef ref,
    Enterprise enterprise,
  ) async {
    final result = await showDialog<Enterprise>(
      context: context,
      builder: (context) => EditEnterpriseDialog(enterprise: enterprise),
    );

    if (result != null) {
      try {
        await ref.read(enterpriseControllerProvider).updateEnterprise(result);
        ref.invalidate(enterprisesProvider);
        if (context.mounted) {
          NotificationService.showSuccess(context, 'Entreprise modifiée');
        }
      } catch (e) {
        if (context.mounted) {
          NotificationService.showError(context, e.toString());
        }
      }
    }
  }

  /// Toggles the enterprise status (active/inactive).
  static Future<void> toggleStatus(
    BuildContext context,
    WidgetRef ref,
    Enterprise enterprise,
  ) async {
    try {
      await ref
          .read(enterpriseControllerProvider)
          .toggleEnterpriseStatus(enterprise.id, !enterprise.isActive);
      ref.invalidate(enterprisesProvider);
      if (context.mounted) {
        NotificationService.showInfo(
          context,
          enterprise.isActive ? 'Entreprise désactivée' : 'Entreprise activée',
        );
      }
    } catch (e) {
      if (context.mounted) {
        NotificationService.showError(context, e.toString());
      }
    }
  }

  /// Shows a confirmation dialog and deletes the enterprise.
  static Future<void> delete(
    BuildContext context,
    WidgetRef ref,
    Enterprise enterprise,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'entreprise'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${enterprise.name}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(enterpriseControllerProvider)
            .deleteEnterprise(enterprise.id);
        ref.invalidate(enterprisesProvider);
        if (context.mounted) {
          NotificationService.showSuccess(context, 'Entreprise supprimée');
        }
      } catch (e) {
        if (context.mounted) {
          NotificationService.showError(context, e.toString());
        }
      }
    }
  }
}
