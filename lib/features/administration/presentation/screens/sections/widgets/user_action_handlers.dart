import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/administration/domain/entities/user.dart';
import 'package:elyf_groupe_app/core/auth/entities/enterprise_module_user.dart';
import '../dialogs/create_user_dialog.dart';
import '../dialogs/edit_user_dialog.dart';
import '../dialogs/assign_enterprise_dialog.dart';
import '../../../../application/providers.dart';
import '../../../../../../shared/utils/notification_service.dart';

/// Action handlers for user section.
///
/// Extracted for better code organization and file size compliance.
class UserActionHandlers {
  UserActionHandlers({required this.ref, required this.context});

  final WidgetRef ref;
  final BuildContext context;

  Future<void> handleCreateUser() async {
    final result = await showDialog<User>(
      context: context,
      builder: (context) => const CreateUserDialog(),
    );

    if (result != null && context.mounted) {
      try {
        await ref.read(userControllerProvider).createUser(result);
        // Toujours invalider le provider pour forcer une relecture
        // Même si la sauvegarde locale a échoué, l'utilisateur existe dans Firestore
        ref.invalidate(usersProvider);
        if (context.mounted) {
          NotificationService.showSuccess(
            context,
            'Utilisateur créé avec succès. Si l\'utilisateur n\'apparaît pas immédiatement, rechargez la liste.',
          );
        }
      } catch (e) {
        // Invalider quand même le provider pour forcer une relecture depuis Firestore
        // L'utilisateur peut avoir été créé dans Firestore même si la sauvegarde locale a échoué
        ref.invalidate(usersProvider);
        if (context.mounted) {
          final errorMessage = e.toString();
          // Si c'est une erreur SQLite mais que l'utilisateur existe dans Firestore,
          // afficher un message informatif plutôt qu'une erreur
          if (errorMessage.toLowerCase().contains('sqlite') ||
              errorMessage.toLowerCase().contains('drift') ||
              errorMessage.toLowerCase().contains('database')) {
            NotificationService.showInfo(
              context,
              'Utilisateur créé dans Firebase. Une erreur est survenue lors de la sauvegarde locale. '
              'L\'utilisateur sera disponible après rechargement de la liste.',
            );
          } else {
            NotificationService.showError(
              context,
              'Erreur lors de la création: $errorMessage',
            );
          }
        }
      }
    }
  }

  Future<void> handleEditUser(User user) async {
    final result = await showDialog<User>(
      context: context,
      builder: (context) => EditUserDialog(user: user),
    );

    if (result != null && context.mounted) {
      try {
        await ref.read(userControllerProvider).updateUser(result);
        ref.invalidate(usersProvider);
        if (context.mounted) {
          NotificationService.showSuccess(
            context,
            'Utilisateur modifié avec succès',
          );
        }
      } catch (e) {
        if (context.mounted) {
          NotificationService.showError(context, e.toString());
        }
      }
    }
  }

  Future<void> handleAssignEnterprise(User user) async {
    final result = await showDialog<dynamic>(
      context: context,
      builder: (context) => AssignEnterpriseDialog(user: user),
    );

    if (result != null && context.mounted) {
      ref.invalidate(enterpriseModuleUsersProvider);
      // Si c'est un EnterpriseModuleUser (mode classique), invalider pour cet utilisateur
      if (result is EnterpriseModuleUser) {
        ref.invalidate(userEnterpriseModuleUsersProvider(result.userId));
      } else {
        // Mode batch : invalider pour l'utilisateur concerné
        ref.invalidate(userEnterpriseModuleUsersProvider(user.id));
      }
    }
  }

  Future<void> handleDeleteUser(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'utilisateur'),
        content: Text('Êtes-vous sûr de vouloir supprimer ${user.fullName} ?'),
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

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(userControllerProvider).deleteUser(user.id);
        // Attendre un peu pour que la base de données soit à jour
        await Future.delayed(const Duration(milliseconds: 100));
        // Invalider le provider pour forcer le rafraîchissement
        ref.invalidate(usersProvider);
        // Invalider aussi les providers dépendants
        ref.invalidate(enterpriseModuleUsersProvider);
        ref.invalidate(userEnterpriseModuleUsersProvider(user.id));
        if (context.mounted) {
          NotificationService.showSuccess(context, 'Utilisateur supprimé');
        }
      } catch (e) {
        if (context.mounted) {
          NotificationService.showError(context, e.toString());
        }
      }
    }
  }

  Future<void> handleToggleStatus(User user) async {
    try {
      await ref
          .read(userControllerProvider)
          .toggleUserStatus(user.id, !user.isActive);
      ref.invalidate(usersProvider);
      if (context.mounted) {
        NotificationService.showInfo(
          context,
          user.isActive ? 'Utilisateur désactivé' : 'Utilisateur activé',
        );
      }
    } catch (e) {
      if (context.mounted) {
        NotificationService.showError(context, e.toString());
      }
    }
  }

  Future<void> handleRemoveAssignment(EnterpriseModuleUser assignment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer l\'assignation'),
        content: Text(
          'Êtes-vous sûr de vouloir retirer cette assignation?\n\n'
          'Entreprise: ${assignment.enterpriseId}\n'
          'Module: ${assignment.moduleId}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref
            .read(adminControllerProvider)
            .removeUserFromEnterprise(
              assignment.userId,
              assignment.enterpriseId,
              assignment.moduleId,
            );
        // Attendre un peu pour que la base de données soit à jour
        await Future.delayed(const Duration(milliseconds: 100));
        ref.invalidate(enterpriseModuleUsersProvider);
        ref.invalidate(userEnterpriseModuleUsersProvider(assignment.userId));
        if (context.mounted) {
          NotificationService.showSuccess(
            context,
            'Assignation retirée avec succès',
          );
        }
      } catch (e) {
        if (context.mounted) {
          NotificationService.showError(context, e.toString());
        }
      }
    }
  }
}
