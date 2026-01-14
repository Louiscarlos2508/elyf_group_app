import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/permissions/entities/module_permission.dart';
import '../../application/providers/permission_providers.dart';

/// Widget that shows child only if user has required permission (using centralized system).
class ImmobilierPermissionGuard extends ConsumerWidget {
  const ImmobilierPermissionGuard({
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
    final adapter = ref.watch(immobilierPermissionAdapterProvider);

    return FutureBuilder<bool>(
      future: adapter.hasPermission(permission.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (snapshot.hasData && snapshot.data == true) {
          return child;
        }

        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}

/// Widget that shows child only if user has any of the required permissions.
class ImmobilierPermissionGuardAny extends ConsumerWidget {
  const ImmobilierPermissionGuardAny({
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
    final adapter = ref.watch(immobilierPermissionAdapterProvider);

    return FutureBuilder<bool>(
      future: adapter.hasAnyPermission(permissions.map((p) => p.id).toSet()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (snapshot.hasData && snapshot.data == true) {
          return child;
        }

        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}

/// Widget that shows child only if user has all required permissions.
class ImmobilierPermissionGuardAll extends ConsumerWidget {
  const ImmobilierPermissionGuardAll({
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
    final adapter = ref.watch(immobilierPermissionAdapterProvider);

    return FutureBuilder<bool>(
      future: adapter.hasAllPermissions(permissions.map((p) => p.id).toSet()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (snapshot.hasData && snapshot.data == true) {
          return child;
        }

        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}
