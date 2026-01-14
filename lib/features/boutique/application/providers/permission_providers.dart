import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/administration/application/providers.dart'
    show permissionServiceProvider;
import '../../../../core/permissions/services/permission_service.dart';
import '../../../../core/auth/providers.dart' as auth;
import '../../domain/adapters/boutique_permission_adapter.dart';

/// Provider for centralized permission service.
/// Uses the shared permission service from administration module.
final centralizedPermissionServiceProvider = Provider<PermissionService>(
  (ref) => ref.watch(permissionServiceProvider),
);

/// Provider for current user ID.
/// Uses the authenticated user ID from auth service, or falls back to default user for development.
final currentUserIdProvider = Provider<String>((ref) {
  // Récupérer l'ID de l'utilisateur authentifié
  final authUserId = ref.watch(auth.currentUserIdProvider);

  // Si un utilisateur est authentifié, utiliser son ID
  if (authUserId != null && authUserId.isNotEmpty) {
    return authUserId;
  }

  // Sinon, utiliser l'utilisateur par défaut pour le développement
  // TODO: En production, retourner null ou gérer l'erreur si pas d'utilisateur
  return 'default_user_boutique';
});

/// Provider for boutique permission adapter.
final boutiquePermissionAdapterProvider = Provider<BoutiquePermissionAdapter>(
  (ref) => BoutiquePermissionAdapter(
    permissionService: ref.watch(centralizedPermissionServiceProvider),
    userId: ref.watch(currentUserIdProvider),
  ),
);
