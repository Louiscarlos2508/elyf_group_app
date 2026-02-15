import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/administration/application/providers.dart'
    show permissionServiceProvider;
import '../../../../core/permissions/services/permission_service.dart';
import '../../../../core/auth/providers.dart' as auth;
import '../../domain/adapters/immobilier_permission_adapter.dart';

/// Provider for centralized permission service.
/// Uses the shared permission service from administration module.
final centralizedPermissionServiceProvider = Provider<PermissionService>(
  (ref) => ref.watch(permissionServiceProvider),
);

/// Provider for current user ID.
/// Uses the authenticated user ID from auth service, or falls back to default user for development.
final currentUserIdProvider = Provider<String>((ref) {
  final authUserId = ref.watch(auth.currentUserIdProvider);
  if (authUserId != null && authUserId.isNotEmpty) {
    return authUserId;
  }
  return 'default_user_immobilier';
});

/// Provider for immobilier permission adapter.
final immobilierPermissionAdapterProvider =
    Provider<ImmobilierPermissionAdapter>(
      (ref) => ImmobilierPermissionAdapter(
        permissionService: ref.watch(centralizedPermissionServiceProvider),
        userId: ref.watch(currentUserIdProvider),
      ),
    );

final userHasImmobilierPermissionProvider = FutureProvider.family<bool, String>((ref, permission) async {
  final adapter = ref.watch(immobilierPermissionAdapterProvider);
  return await adapter.hasPermission(permission);
});
