import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/enterprise.dart';
import 'providers.dart';
import 'services/tenant_context_service.dart';

/// Notifier for the current tenant ID
class CurrentTenantIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setTenantId(String? id) => state = id;
}

/// Provider de l'ID du tenant actuel (global à l'application)
/// Null si aucun tenant n'est sélectionné
final currentTenantIdProvider = NotifierProvider<CurrentTenantIdNotifier, String?>(CurrentTenantIdNotifier.new);

/// Provider du tenant actuel (résolu depuis l'ID)
final currentTenantProvider = FutureProvider<Enterprise?>((ref) async {
  final tenantId = ref.watch(currentTenantIdProvider);
  if (tenantId == null) return null;
  
  try {
    final repository = ref.watch(enterpriseRepositoryProvider);
    return await repository.getEnterpriseById(tenantId);
  } catch (e) {
    return null;
  }
});

/// Provider du breadcrumb du tenant actuel
/// Retourne la liste des ancêtres + tenant actuel
final tenantBreadcrumbsProvider = FutureProvider<List<Enterprise>>((ref) async {
  final current = await ref.watch(currentTenantProvider.future);
  if (current == null) return [];
  
  final repository = ref.watch(enterpriseRepositoryProvider);
  final breadcrumbs = <Enterprise>[];
  
  // Récupérer tous les ancêtres
  for (final ancestorId in current.ancestorIds) {
    try {
      final ancestor = await repository.getEnterpriseById(ancestorId);
      if (ancestor != null) {
        breadcrumbs.add(ancestor);
      }
    } catch (e) {
      // Ignorer les ancêtres non trouvés
      continue;
    }
  }
  
  // Ajouter le tenant actuel
  breadcrumbs.add(current);
  
  return breadcrumbs;
});

/// Provider des tenants accessibles par l'utilisateur actuel
final accessibleTenantsProvider = FutureProvider<List<Enterprise>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  
  try {
    final service = ref.watch(tenantContextServiceProvider);
    return await service.getAccessibleTenants(userId);
  } catch (e) {
    return [];
  }
});

/// Provider des descendants d'un tenant
final tenantDescendantsProvider = FutureProvider.family<
  List<Enterprise>,
  String
>((ref, tenantId) async {
  final service = ref.watch(tenantContextServiceProvider);
  return await service.getDescendants(tenantId);
});

/// Provider des enfants directs d'un tenant
final tenantChildrenProvider = FutureProvider.family<
  List<Enterprise>,
  String
>((ref, tenantId) async {
  final service = ref.watch(tenantContextServiceProvider);
  return await service.getChildren(tenantId);
});

/// Provider de la hiérarchie complète d'un tenant
final tenantHierarchyProvider = FutureProvider.family<
  EnterpriseHierarchy,
  String
>((ref, tenantId) async {
  final service = ref.watch(tenantContextServiceProvider);
  return await service.getHierarchy(tenantId);
});

/// Provider de l'ID utilisateur actuel (à implémenter selon votre logique auth)
final currentUserIdProvider = Provider<String?>((ref) {
  // TODO: Implémenter la récupération de l'ID utilisateur depuis le service d'auth
  // Pour l'instant, retourne null
  return null;
});

/// Provider de toutes les entreprises
final enterprisesProvider = FutureProvider<List<Enterprise>>((ref) async {
  final repository = ref.watch(enterpriseRepositoryProvider);
  return await repository.getAllEnterprises();
});

/// Provider des assignations d'un utilisateur à des entreprises
final enterpriseModuleUsersProvider = FutureProvider.family((ref, String userId) async {
  final repository = ref.watch(adminRepositoryProvider);
  return await repository.getUserEnterpriseModuleUsers(userId);
});
