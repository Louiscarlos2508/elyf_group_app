import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/core.dart';
import '../../../../../core/permissions/entities/module_permission.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';

/// Widget that shows child only if user has required permission (using centralized system).
class CentralizedPermissionGuard extends ConsumerWidget {
  const CentralizedPermissionGuard({
    super.key,
    required this.permissionId,
    required this.child,
    this.fallback,
  });

  final String permissionId;
  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionAsync = ref.watch(hasPermissionProvider(permissionId));

    return permissionAsync.when(
      data: (hasPermission) {
        if (hasPermission) return child;
        return fallback ?? const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => fallback ?? const SizedBox.shrink(),
    );
  }
}

/// Widget that shows child only if user has any of the required permissions.
class CentralizedPermissionGuardAny extends ConsumerWidget {
  const CentralizedPermissionGuardAny({
    super.key,
    required this.permissionIds,
    required this.child,
    this.fallback,
  });

  final Set<String> permissionIds;
  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionAsync = ref.watch(hasAnyPermissionProvider(permissionIds));

    return permissionAsync.when(
      data: (hasPermission) {
        if (hasPermission) return child;
        return fallback ?? const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => fallback ?? const SizedBox.shrink(),
    );
  }
}

/// Widget that shows child only if user has all required permissions.
class CentralizedPermissionGuardAll extends ConsumerWidget {
  const CentralizedPermissionGuardAll({
    super.key,
    required this.permissionIds,
    required this.child,
    this.fallback,
  });

  final Set<String> permissionIds;
  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionAsync = ref.watch(hasAllPermissionsProvider(permissionIds));

    return permissionAsync.when(
      data: (hasPermission) {
        if (hasPermission) return child;
        return fallback ?? const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => fallback ?? const SizedBox.shrink(),
    );
  }
}

/// Helper widget using permission constants for easier usage.
class EauMineralePermissionGuard extends ConsumerWidget {
  const EauMineralePermissionGuard({
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
    return CentralizedPermissionGuard(
      permissionId: permission.id,
      fallback: fallback,
      child: child,
    );
  }
}
