import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/enterprise.dart';
import '../../domain/repositories/enterprise_repository.dart';
import '../../domain/repositories/admin_repository.dart';
import '../providers.dart';

/// Service global de gestion du contexte tenant
/// Permet de gérer le tenant actuel et de naviguer dans la hiérarchie
class TenantContextService {
  TenantContextService(this._enterpriseRepository, this._adminRepository);
  
  final EnterpriseRepository _enterpriseRepository;
  final AdminRepository _adminRepository;
  
  String? _currentTenantId;
  
  /// Obtenir le tenant actuel
  Future<Enterprise?> getCurrentTenant() async {
    if (_currentTenantId == null) return null;
    
    try {
      return await _enterpriseRepository.getEnterpriseById(_currentTenantId!);
    } catch (e) {
      return null;
    }
  }
  
  /// Obtenir tous les tenants accessibles par un utilisateur
  Future<List<Enterprise>> getAccessibleTenants(String userId) async {
    try {
      // Récupérer les assignations de l'utilisateur
      final assignments = await _adminRepository.getUserEnterpriseModuleUsers(userId);
      
      // Extraire les IDs d'entreprises uniques
      final enterpriseIds = assignments
          .map((a) => a.enterpriseId)
          .toSet()
          .toList();
      
      // Récupérer les entreprises
      final enterprises = <Enterprise>[];
      
      for (final id in enterpriseIds) {
        try {
          final enterprise = await _enterpriseRepository.getEnterpriseById(id);
          if (enterprise != null) {
            enterprises.add(enterprise);
          }
        } catch (e) {
          // Ignorer les entreprises non trouvées
          continue;
        }
      }
      
      return enterprises;
    } catch (e) {
      return [];
    }
  }
  
  /// Vérifier si un utilisateur a accès à un tenant
  /// Inclut l'accès aux tenants parents (héritage)
  Future<bool> hasAccessToTenant(String userId, String tenantId) async {
    final accessible = await getAccessibleTenants(userId);
    
    // Vérifier accès direct
    if (accessible.any((e) => e.id == tenantId)) {
      return true;
    }
    
    // Vérifier accès via ancêtres (si l'utilisateur a accès à un parent)
    return accessible.any((e) => e.ancestorIds.contains(tenantId));
  }
  
  /// Obtenir tous les descendants d'un tenant
  Future<List<Enterprise>> getDescendants(String tenantId) async {
    try {
      // Get all enterprises and filter descendants
      final allEnterprises = await _enterpriseRepository.getAllEnterprises();
      return allEnterprises
          .where((e) => e.ancestorIds.contains(tenantId))
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  /// Obtenir les enfants directs d'un tenant
  Future<List<Enterprise>> getChildren(String tenantId) async {
    try {
      // Get all enterprises and filter children
      final allEnterprises = await _enterpriseRepository.getAllEnterprises();
      return allEnterprises
          .where((e) => e.parentEnterpriseId == tenantId)
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  /// Obtenir la hiérarchie complète d'un tenant (ancêtres + tenant + descendants)
  Future<EnterpriseHierarchy> getHierarchy(String tenantId) async {
    final current = await _enterpriseRepository.getEnterpriseById(tenantId);
    if (current == null) {
      throw Exception('Enterprise not found: $tenantId');
    }
    
    // Récupérer les ancêtres
    final ancestors = <Enterprise>[];
    for (final ancestorId in current.ancestorIds) {
      try {
        final ancestor = await _enterpriseRepository.getEnterpriseById(ancestorId);
        if (ancestor != null) {
          ancestors.add(ancestor);
        }
      } catch (e) {
        continue;
      }
    }
      
    // Récupérer les descendants
    final descendants = await getDescendants(tenantId);
    
    return EnterpriseHierarchy(
      current: current,
      ancestors: ancestors,
      descendants: descendants,
    );
  }
  
  /// Changer le tenant actuel
  void switchTenant(String tenantId) {
    _currentTenantId = tenantId;
  }
  
  /// Effacer le tenant actuel
  void clearTenant() {
    _currentTenantId = null;
  }
  
  /// Calculer le chemin hiérarchique pour un nouveau tenant
  Future<HierarchyInfo> calculateHierarchyInfo({
    required String enterpriseId,
    String? parentEnterpriseId,
  }) async {
    if (parentEnterpriseId == null) {
      // Entreprise racine
      return HierarchyInfo(
        level: 0,
        path: '/$enterpriseId',
        ancestorIds: [],
      );
    }
    
    try {
      final parent = await _enterpriseRepository.getEnterpriseById(parentEnterpriseId);
      if (parent == null) {
        // Si le parent n'est pas trouvé, traiter comme racine
        return HierarchyInfo(
          level: 0,
          path: '/$enterpriseId',
          ancestorIds: [],
        );
      }
      
      return HierarchyInfo(
        level: parent.hierarchyLevel + 1,
        path: '${parent.hierarchyPath}/$enterpriseId',
        ancestorIds: [...parent.ancestorIds, parent.id],
      );
    } catch (e) {
      // Si le parent n'est pas trouvé, traiter comme racine
      return HierarchyInfo(
        level: 0,
        path: '/$enterpriseId',
        ancestorIds: [],
      );
    }
  }
}

/// Informations de hiérarchie calculées
class HierarchyInfo {
  const HierarchyInfo({
    required this.level,
    required this.path,
    required this.ancestorIds,
  });
  
  final int level;
  final String path;
  final List<String> ancestorIds;
}

/// Hiérarchie complète d'une entreprise
class EnterpriseHierarchy {
  const EnterpriseHierarchy({
    required this.current,
    required this.ancestors,
    required this.descendants,
  });
  
  final Enterprise current;
  final List<Enterprise> ancestors;
  final List<Enterprise> descendants;
  
  /// Obtenir le breadcrumb (ancêtres + current)
  List<Enterprise> get breadcrumb => [...ancestors, current];
  
  /// Obtenir tous les tenants de la hiérarchie
  List<Enterprise> get all => [...ancestors, current, ...descendants];
}

/// Provider du service de contexte tenant
final tenantContextServiceProvider = Provider<TenantContextService>((ref) {
  return TenantContextService(
    ref.watch(enterpriseRepositoryProvider),
    ref.watch(adminRepositoryProvider),
  );
});
