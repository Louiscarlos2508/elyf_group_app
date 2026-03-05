import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/permissions/entities/module_permission.dart';
import '../../application/providers/permission_providers.dart';
import 'package:elyf_groupe_app/core/logging/app_logger.dart';

/// Widget that shows child only if user has required permission (using centralized system).
class GazPermissionGuard extends ConsumerWidget {
  const GazPermissionGuard({
    super.key,
    required this.permission,
    required this.child,
    this.fallback,
  });

  final ActionPermission permission;
  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionAsync = ref.watch(userHasGazPermissionProvider(permission.id));

    return permissionAsync.when(
      data: (hasPermission) {
        if (hasPermission) return child;
        return fallback ?? const SizedBox.shrink();
      },
      loading: () {
        // preserve child if we had data before (avoids flickering during sync)
        if (permissionAsync.hasValue) {
          if (permissionAsync.value == true) return child;
          return fallback ?? const SizedBox.shrink();
        }
        return const SizedBox.shrink();
      },
      error: (error, _) {
        AppLogger.error('Permission check error: $error', name: 'gaz.permissions');
        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}

/// Widget that shows child only if user has any of the required permissions.
class GazPermissionGuardAny extends ConsumerWidget {
  const GazPermissionGuardAny({
    super.key,
    required this.permissions,
    required this.child,
    this.fallback,
  });

  final List<ActionPermission> permissions;
  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We could create a combined provider, but for now let's use individual checks
    // or just refactor this to be more efficient later if needed.
    // For now, let's at least make it safe from flickering.
    
    // Simple approach: watch all and check if any is true
    for (final p in permissions) {
      final pAsync = ref.watch(userHasGazPermissionProvider(p.id));
      if (pAsync.value == true) return child;
    }
    
    // If none are true yet, check if any are still loading
    final anyLoading = permissions.any((p) => ref.watch(userHasGazPermissionProvider(p.id)).isLoading && !ref.watch(userHasGazPermissionProvider(p.id)).hasValue);
    
    if (anyLoading) return const SizedBox.shrink();

    return fallback ?? const SizedBox.shrink();
  }
}

/// Widget that shows child only if user has all required permissions.
class GazPermissionGuardAll extends ConsumerWidget {
  const GazPermissionGuardAll({
    super.key,
    required this.permissions,
    required this.child,
    this.fallback,
  });

  final List<ActionPermission> permissions;
  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAsync = permissions.map((p) => ref.watch(userHasGazPermissionProvider(p.id))).toList();
    
    if (allAsync.any((a) => a.isLoading && !a.hasValue)) {
      return const SizedBox.shrink();
    }
    
    if (allAsync.every((a) => a.value == true)) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}
