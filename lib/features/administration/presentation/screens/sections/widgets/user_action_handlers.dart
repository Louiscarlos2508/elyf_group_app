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
  UserActionHandlers({
    required this.ref,
    required this.context,
  });

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
        ref.invalidate(usersProvider);
        if (context.mounted) {
          NotificationService.showSuccess(context, 'Utilisateur créé avec succès');
        }
      } catch (e) {
        if (context.mounted) {
          NotificationService.showError(context, e.toString());
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
          NotificationService.showSuccess(context, 'Utilisateur modifié avec succès');
        }
      } catch (e) {
        if (context.mounted) {
          NotificationService.showError(context, e.toString());
        }
      }
    }
  }

  Future<void> handleAssignEnterprise(User user) async {
    final result = await showDialog<EnterpriseModuleUser>(
      context: context,
      builder: (context) => AssignEnterpriseDialog(user: user),
    );

    if (result != null && context.mounted) {
      ref.invalidate(enterpriseModuleUsersProvider);
      ref.invalidate(userEnterpriseModuleUsersProvider(result.userId));
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
        ref.invalidate(usersProvider);
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
      await ref.read(userControllerProvider).toggleUserStatus(user.id, !user.isActive);
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
}

