import 'package:flutter/material.dart';

import '../../../domain/entities/audit_log.dart';

/// Helper utilities for audit log display.
class AuditLogHelpers {
  AuditLogHelpers._();

  /// Gets a human-readable label for an audit action.
  static String getActionLabel(AuditAction action) {
    switch (action) {
      case AuditAction.create:
        return 'Création';
      case AuditAction.update:
        return 'Modification';
      case AuditAction.delete:
        return 'Suppression';
      case AuditAction.assign:
        return 'Assignation';
      case AuditAction.unassign:
        return 'Désassignation';
      case AuditAction.activate:
        return 'Activation';
      case AuditAction.deactivate:
        return 'Désactivation';
      case AuditAction.permissionChange:
        return 'Changement de permissions';
      case AuditAction.roleChange:
        return 'Changement de rôle';
      case AuditAction.unknown:
        return 'Action inconnue';
    }
  }

  /// Gets an icon for an audit action.
  static IconData getActionIcon(AuditAction action) {
    switch (action) {
      case AuditAction.create:
        return Icons.add_circle_outline;
      case AuditAction.update:
        return Icons.edit_outlined;
      case AuditAction.delete:
        return Icons.delete_outline;
      case AuditAction.assign:
        return Icons.person_add_outlined;
      case AuditAction.unassign:
        return Icons.person_remove_outlined;
      case AuditAction.activate:
        return Icons.check_circle_outline;
      case AuditAction.deactivate:
        return Icons.block_outlined;
      case AuditAction.permissionChange:
        return Icons.shield_outlined;
      case AuditAction.roleChange:
        return Icons.swap_horiz_outlined;
      case AuditAction.unknown:
        return Icons.help_outline;
    }
  }

  /// Gets a color for an audit action.
  static Color getActionColor(AuditAction action, BuildContext context) {
    final theme = Theme.of(context);
    switch (action) {
      case AuditAction.create:
        return theme.colorScheme.primary;
      case AuditAction.update:
        return theme.colorScheme.secondary;
      case AuditAction.delete:
        return theme.colorScheme.error;
      case AuditAction.activate:
        return Colors.green;
      case AuditAction.deactivate:
        return Colors.orange;
      default:
        return theme.colorScheme.tertiary;
    }
  }
}
