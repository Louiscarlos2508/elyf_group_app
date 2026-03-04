import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:elyf_groupe_app/features/administration/domain/repositories/enterprise_repository.dart';
import 'package:elyf_groupe_app/features/administration/domain/repositories/admin_repository.dart';

/// Service global de gestion du contexte tenant
/// Permet de gérer le tenant actuel et de naviguer dans la hiérarchie.
/// Déplacé dans core pour casser les dépendances cycliques.
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
      final assignments = await _adminRepository.getUserEnterpriseModuleUsers(userId);
      
      final enterpriseIds = assignments
          .map((a) => a.enterpriseId)
          .toSet()
          .toList();
      
      final enterprises = <Enterprise>[];
      
      for (final id in enterpriseIds) {
        try {
          final enterprise = await _enterpriseRepository.getEnterpriseById(id);
          if (enterprise != null) {
            enterprises.add(enterprise);
          }
        } catch (e) {
          continue;
        }
      }
      
      return enterprises;
    } catch (e) {
      return [];
    }
  }
  
  /// Vérifier si un utilisateur a accès à un tenant
  Future<bool> hasAccessToTenant(String userId, String tenantId) async {
    final accessible = await getAccessibleTenants(userId);
    
    if (accessible.any((e) => e.id == tenantId)) {
      return true;
    }
    
    return accessible.any((e) => e.ancestorIds.contains(tenantId));
  }
  
  /// Obtenir tous les descendants d'un tenant
  Future<List<Enterprise>> getDescendants(String tenantId) async {
    try {
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
      final allEnterprises = await _enterpriseRepository.getAllEnterprises();
      return allEnterprises
          .where((e) => e.parentEnterpriseId == tenantId)
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  /// Obtenir la hiérarchie complète d'un tenant
  Future<EnterpriseHierarchy> getHierarchy(String tenantId) async {
    final current = await _enterpriseRepository.getEnterpriseById(tenantId);
    if (current == null) {
      throw Exception('Enterprise not found: $tenantId');
    }
    
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
      
    final descendants = await getDescendants(tenantId);
    
    return EnterpriseHierarchy(
      current: current,
      ancestors: ancestors,
      descendants: descendants,
    );
  }
  
  void switchTenant(String tenantId) {
    _currentTenantId = tenantId;
  }
  
  void clearTenant() {
    _currentTenantId = null;
  }
  
  Future<HierarchyInfo> calculateHierarchyInfo({
    required String enterpriseId,
    String? parentEnterpriseId,
  }) async {
    if (parentEnterpriseId == null) {
      return HierarchyInfo(
        level: 0,
        path: '/$enterpriseId',
        ancestorIds: [],
      );
    }
    
    try {
      final parent = await _enterpriseRepository.getEnterpriseById(parentEnterpriseId);
      if (parent == null) {
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
      return HierarchyInfo(
        level: 0,
        path: '/$enterpriseId',
        ancestorIds: [],
      );
    }
  }
}

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

class EnterpriseHierarchy {
  const EnterpriseHierarchy({
    required this.current,
    required this.ancestors,
    required this.descendants,
  });
  
  final Enterprise current;
  final List<Enterprise> ancestors;
  final List<Enterprise> descendants;
  
  List<Enterprise> get breadcrumb => [...ancestors, current];
  List<Enterprise> get all => [...ancestors, current, ...descendants];
}
