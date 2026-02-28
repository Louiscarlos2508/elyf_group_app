import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../core/auth/entities/enterprise_module_user.dart';
import '../../../../core/permissions/entities/user_role.dart';
import '../../domain/entities/enterprise.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../application/services/tenant_context_service.dart';

/// Firestore-based repository for administration operations
/// Online-only, multi-tenant aware
class AdminFirestoreRepository implements AdminRepository {
  AdminFirestoreRepository({
    required FirebaseFirestore firestore,
    required Ref ref,
  })  : _firestore = firestore,
        _ref = ref;

  final FirebaseFirestore _firestore;
  final Ref _ref;

  // Collections
  CollectionReference<Map<String, dynamic>> get _enterprises =>
      _firestore.collection('enterprises');
  CollectionReference<Map<String, dynamic>> get _roles =>
      _firestore.collection('roles');
  CollectionReference<Map<String, dynamic>> get _enterpriseModuleUsers =>
      _firestore.collection('enterprise_module_users');

  // ============================================================================
  // ENTERPRISE METHODS (Hierarchy-aware)
  // ============================================================================

  /// Get enterprise by ID
  Future<Enterprise> getEnterpriseById(String id) async {
    final doc = await _enterprises.doc(id).get();
    if (!doc.exists) {
      throw Exception('Enterprise not found: $id');
    }
    return Enterprise.fromMap(doc.data()!);
  }

  /// Get all enterprises
  Future<List<Enterprise>> getAllEnterprises() async {
    try {
      final snapshot = await _enterprises.get();
      return snapshot.docs
          .map((doc) => _enterpriseFromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get enterprises by type
  Future<List<Enterprise>> getEnterprisesByType(EnterpriseType type) async {
    final snapshot = await _enterprises
        .where('type', isEqualTo: type.id)
        .get();
    return snapshot.docs
        .map((doc) => _enterpriseFromFirestore(doc))
        .toList();
  }

  /// Get enterprise hierarchy (ancestors + current + descendants)
  Future<EnterpriseHierarchy> getEnterpriseHierarchy(String enterpriseId) async {
    final tenantService = _ref.read(tenantContextServiceProvider);
    return await tenantService.getHierarchy(enterpriseId);
  }

  /// Get children of an enterprise
  Future<List<Enterprise>> getEnterpriseChildren(String parentId) async {
    final snapshot = await _enterprises
        .where('parentEnterpriseId', isEqualTo: parentId)
        .get();
    return snapshot.docs
        .map((doc) => _enterpriseFromFirestore(doc))
        .toList();
  }

  /// Get all descendants of an enterprise (recursive)
  Future<List<Enterprise>> getEnterpriseDescendants(String enterpriseId) async {
    final snapshot = await _enterprises
        .where('ancestorIds', arrayContains: enterpriseId)
        .get();
    return snapshot.docs
        .map((doc) => _enterpriseFromFirestore(doc))
        .toList();
  }

  /// Create enterprise with automatic hierarchy calculation
  Future<String> createEnterprise(Enterprise enterprise) async {
    final tenantService = _ref.read(tenantContextServiceProvider);
    
    // Calculate hierarchy info
    final hierarchyInfo = await tenantService.calculateHierarchyInfo(
      enterpriseId: enterprise.id,
      parentEnterpriseId: enterprise.parentEnterpriseId,
    );
    
    // Create enterprise with calculated hierarchy
    final enterpriseWithHierarchy = enterprise.copyWith(
      hierarchyLevel: hierarchyInfo.level,
      hierarchyPath: hierarchyInfo.path,
      ancestorIds: hierarchyInfo.ancestorIds,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await _enterprises.doc(enterprise.id).set(
      _enterpriseToFirestore(enterpriseWithHierarchy),
    );
    
    return enterprise.id;
  }

  /// Update enterprise
  Future<void> updateEnterprise(Enterprise enterprise) async {
    final updatedEnterprise = enterprise.copyWith(
      updatedAt: DateTime.now(),
    );
    
    await _enterprises.doc(enterprise.id).set(
      _enterpriseToFirestore(updatedEnterprise),
      SetOptions(merge: true),
    );
  }

  /// Delete enterprise (only if no children)
  Future<void> deleteEnterprise(String id) async {
    // Check for children
    final children = await getEnterpriseChildren(id);
    if (children.isNotEmpty) {
      throw Exception(
        'Cannot delete enterprise with children. Delete children first.',
      );
    }
    
    await _enterprises.doc(id).delete();
  }

  /// Toggle enterprise status
  Future<void> toggleEnterpriseStatus(String id, bool isActive) async {
    await _enterprises.doc(id).update({
      'isActive': isActive,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // ============================================================================
  // ENTERPRISE MODULE USER METHODS
  // ============================================================================

  @override
  Future<List<EnterpriseModuleUser>> getEnterpriseModuleUsers() async {
    try {
      final snapshot = await _enterpriseModuleUsers.get();
      return snapshot.docs
          .map((doc) => EnterpriseModuleUser.fromMap(doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Stream<List<EnterpriseModuleUser>> watchEnterpriseModuleUsers() {
    return _enterpriseModuleUsers.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => EnterpriseModuleUser.fromMap(doc.data()))
          .toList(),
    ).onErrorReturn(<EnterpriseModuleUser>[]);
  }

  @override
  Future<List<EnterpriseModuleUser>> getUserEnterpriseModuleUsers(
    String userId,
  ) async {
    final snapshot = await _enterpriseModuleUsers
        .where('userId', isEqualTo: userId)
        .get();
    return snapshot.docs
        .map((doc) => EnterpriseModuleUser.fromMap(doc.data()))
        .toList();
  }

  @override
  Future<List<EnterpriseModuleUser>> getEnterpriseUsers(
    String enterpriseId,
  ) async {
    final snapshot = await _enterpriseModuleUsers
        .where('enterpriseId', isEqualTo: enterpriseId)
        .get();
    return snapshot.docs
        .map((doc) => EnterpriseModuleUser.fromMap(doc.data()))
        .toList();
  }

  @override
  Future<List<EnterpriseModuleUser>> getEnterpriseModuleUsersByEnterpriseAndModule(
    String enterpriseId,
    String moduleId,
  ) async {
    final snapshot = await _enterpriseModuleUsers
        .where('enterpriseId', isEqualTo: enterpriseId)
        .where('moduleId', isEqualTo: moduleId)
        .get();
    return snapshot.docs
        .map((doc) => EnterpriseModuleUser.fromMap(doc.data()))
        .toList();
  }

  @override
  Future<EnterpriseModuleUser?> getUserEnterpriseModuleUser({
    required String userId,
    required String enterpriseId,
    required String moduleId,
  }) async {
    final snapshot = await _enterpriseModuleUsers
        .where('userId', isEqualTo: userId)
        .where('enterpriseId', isEqualTo: enterpriseId) // Correction: should be enterpriseId not userId
        .where('moduleId', isEqualTo: moduleId)
        .limit(1)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      return EnterpriseModuleUser.fromMap(snapshot.docs.first.data());
    }
    return null;
  }

  @override
  Future<void> assignUserToEnterprise(
    EnterpriseModuleUser enterpriseModuleUser,
  ) async {
    final id = '${enterpriseModuleUser.userId}_'
        '${enterpriseModuleUser.enterpriseId}_'
        '${enterpriseModuleUser.moduleId}';
    
    await _enterpriseModuleUsers.doc(id).set(
      enterpriseModuleUser.toMap(),
    );
  }

  @override
  Future<void> updateUserRole(
    String userId,
    String enterpriseId,
    String moduleId,
    List<String> roleIds,
  ) async {
    final id = '${userId}_${enterpriseId}_$moduleId';
    await _enterpriseModuleUsers.doc(id).update({
      'roleIds': roleIds,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> updateUserPermissions(
    String userId,
    String enterpriseId,
    String moduleId,
    Set<String> permissions,
  ) async {
    final id = '${userId}_${enterpriseId}_$moduleId';
    await _enterpriseModuleUsers.doc(id).update({
      'customPermissions': permissions.toList(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> removeUserFromEnterprise(
    String userId,
    String enterpriseId,
    String moduleId,
  ) async {
    final id = '${userId}_${enterpriseId}_$moduleId';
    await _enterpriseModuleUsers.doc(id).delete();
  }

  // ============================================================================
  // ROLE METHODS
  // ============================================================================

  @override
  Future<List<UserRole>> getAllRoles() async {
    try {
      final snapshot = await _roles.get();
      return snapshot.docs
          .map((doc) => UserRole.fromMap(doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Stream<List<UserRole>> watchAllRoles() {
    return _roles.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => UserRole.fromMap(doc.data()))
          .toList(),
    ).onErrorReturn(<UserRole>[]);
  }

  @override
  Future<({List<UserRole> roles, int totalCount})> getRolesPaginated({
    int page = 0,
    int limit = 50,
  }) async {
    // Get total count
    final countSnapshot = await _roles.count().get();
    final totalCount = countSnapshot.count ?? 0;
    
    // Firestore doesn't have offset, we need to use cursor-based pagination
    // For simplicity, we'll fetch all and paginate in memory
    // For production, implement proper cursor-based pagination with startAfter
    final allRoles = await getAllRoles();
    final startIndex = page * limit;
    final endIndex = (startIndex + limit).clamp(0, allRoles.length);
    
    final roles = startIndex < allRoles.length
        ? allRoles.sublist(startIndex, endIndex)
        : <UserRole>[];
    
    return (roles: roles, totalCount: totalCount);
  }

  @override
  Future<List<UserRole>> getModuleRoles(String moduleId) async {
    final snapshot = await _roles
        .where('moduleId', isEqualTo: moduleId)
        .get();
    return snapshot.docs
        .map((doc) => UserRole.fromMap(doc.data()))
        .toList();
  }

  @override
  Future<void> createRole(UserRole role) async {
    await _roles.doc(role.id).set(role.toMap());
  }

  @override
  Future<void> updateRole(UserRole role) async {
    await _roles.doc(role.id).set(
      role.toMap(),
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> deleteRole(String roleId) async {
    // Check if role is system role
    final doc = await _roles.doc(roleId).get();
    if (doc.exists) {
      final role = UserRole.fromMap(doc.data()!);
      if (role.isSystemRole) {
        throw Exception('Cannot delete system role');
      }
    }
    
    await _roles.doc(roleId).delete();
  }

  @override
  Stream<bool> watchSyncStatus() {
    // For Firestore, we're always "synced" since it's online-only
    return Stream.value(true);
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Convert Firestore document to Enterprise
  Enterprise _enterpriseFromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    data['id'] = doc.id; // Ensure ID is set
    return Enterprise.fromMap(data);
  }

  /// Convert Enterprise to Firestore map
  Map<String, dynamic> _enterpriseToFirestore(Enterprise enterprise) {
    final map = enterprise.toMap();
    map.remove('id'); // Firestore uses document ID
    return map;
  }
}
