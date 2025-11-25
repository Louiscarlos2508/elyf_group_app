import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/module_permission.dart';

/// Widget that shows child only if user has required permission.
class PermissionGuard extends ConsumerWidget {
  const PermissionGuard({
    super.key,
    required this.permission,
    required this.child,
    this.fallback,
  });

  final ModulePermission permission;
  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionService = ref.watch(permissionServiceProvider);
    final hasPermission = permissionService.hasPermission(permission);

    if (hasPermission) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}

/// Widget that shows child only if user has any of the required permissions.
class PermissionGuardAny extends ConsumerWidget {
  const PermissionGuardAny({
    super.key,
    required this.permissions,
    required this.child,
    this.fallback,
  });

  final Set<ModulePermission> permissions;
  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionService = ref.watch(permissionServiceProvider);
    final hasPermission = permissionService.hasAnyPermission(permissions);

    if (hasPermission) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}

/// Widget that shows child only if user has all required permissions.
class PermissionGuardAll extends ConsumerWidget {
  const PermissionGuardAll({
    super.key,
    required this.permissions,
    required this.child,
    this.fallback,
  });

  final Set<ModulePermission> permissions;
  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionService = ref.watch(permissionServiceProvider);
    final hasPermission = permissionService.hasAllPermissions(permissions);

    if (hasPermission) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}

/// Button that is enabled only if user has required permission.
class PermissionButton extends ConsumerWidget {
  const PermissionButton({
    super.key,
    required this.permission,
    required this.onPressed,
    required this.child,
    this.enabledStyle,
    this.disabledStyle,
  });

  final ModulePermission permission;
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? enabledStyle;
  final ButtonStyle? disabledStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionService = ref.watch(permissionServiceProvider);
    final hasPermission = permissionService.hasPermission(permission);

    return FilledButton(
      onPressed: hasPermission ? onPressed : null,
      style: hasPermission ? enabledStyle : disabledStyle,
      child: child,
    );
  }
}

