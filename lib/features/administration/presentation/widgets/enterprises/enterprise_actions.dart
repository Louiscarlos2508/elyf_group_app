import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/enterprise.dart';
import '../../../../../shared/utils/notification_service.dart';
import '../../screens/sections/dialogs/create_enterprise_wizard.dart';
import '../../screens/sections/dialogs/edit_enterprise_dialog.dart';
import '../../../../../../core/auth/providers.dart' show currentUserIdProvider;
import 'package:go_router/go_router.dart';
import 'package:elyf_groupe_app/app/router/app_router.dart';
import '../../screens/sections/admin_audit_trail_section.dart'
    show recentAuditLogsProvider;

/// Utility class for enterprise-related actions.
class EnterpriseActions {
  EnterpriseActions._();

  /// Shows the create enterprise dialog and handles the result.
  static Future<void> create(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<Enterprise>(
      context: context,
      builder: (context) => const CreateEnterpriseWizard(),
    );

    if (result != null) {
      try {
        final currentUserId = ref.read(currentUserIdProvider);
        await ref
            .read(enterpriseControllerProvider)
            .createEnterprise(result, currentUserId: currentUserId);
        
        // Attendre un peu pour que la base de données soit à jour
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Invalider les providers pour forcer le rafraîchissement
        ref.invalidate(enterprisesProvider);
        ref.invalidate(adminStatsProvider);
        // Invalider aussi les providers dépendants
        ref.invalidate(enterprisesByTypeProvider);
        ref.invalidate(enterpriseByIdProvider);
        // Invalider aussi l'audit trail pour afficher le nouveau log
        ref.invalidate(recentAuditLogsProvider);
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
        final currentUserId = ref.read(currentUserIdProvider);
        await ref
            .read(enterpriseControllerProvider)
            .updateEnterprise(result, currentUserId: currentUserId);
        
        // Attendre un peu pour que la base de données soit à jour
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Invalider les providers pour forcer le rafraîchissement
        ref.invalidate(enterprisesProvider);
        ref.invalidate(adminStatsProvider);
        // Invalider aussi les providers dépendants
        ref.invalidate(enterprisesByTypeProvider);
        ref.invalidate(enterpriseByIdProvider);
        ref.invalidate(recentAuditLogsProvider);
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
      final currentUserId = ref.read(currentUserIdProvider);
      await ref
          .read(enterpriseControllerProvider)
          .toggleEnterpriseStatus(
            enterprise.id,
            !enterprise.isActive,
            currentUserId: currentUserId,
          );
      ref.invalidate(enterprisesProvider);
      ref.invalidate(recentAuditLogsProvider);
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
        final currentUserId = ref.read(currentUserIdProvider);
        await ref
            .read(enterpriseControllerProvider)
            .deleteEnterprise(
              enterprise.id,
              currentUserId: currentUserId,
              enterpriseData: enterprise,
            );
        
        // Attendre un peu pour que la base de données soit à jour
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Invalider les providers pour forcer le rafraîchissement
        ref.invalidate(enterprisesProvider);
        ref.invalidate(adminStatsProvider);
        // Invalider aussi les providers dépendants
        ref.invalidate(enterprisesByTypeProvider);
        ref.invalidate(enterpriseByIdProvider);
        ref.invalidate(recentAuditLogsProvider);
        
        if (context.mounted) {
          NotificationService.showSuccess(context, 'Entreprise supprimée');
        }
      } catch (e) {
        if (context.mounted) {
          // Afficher un message d'erreur plus clair pour l'utilisateur
          final errorMessage = e.toString().contains('2067') || 
                              e.toString().contains('FOREIGN KEY') ||
                              e.toString().contains('données liées')
              ? 'Impossible de supprimer l\'entreprise "${enterprise.name}". '
                'Elle contient encore des données liées. '
                'Veuillez supprimer toutes les données associées avant de supprimer l\'entreprise.'
              : e.toString();
          NotificationService.showError(context, errorMessage);
        }
      }
    }
  }

  /// Navigates to the enterprise management dashboard.
  static void viewDetails(
    BuildContext context,
    WidgetRef ref,
    Enterprise enterprise,
  ) {
    context.goNamed(
      AppRoute.adminEnterpriseManagement.name,
      pathParameters: {'id': enterprise.id},
    );
  }

}
