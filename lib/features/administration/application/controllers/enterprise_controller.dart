import '../../domain/entities/enterprise.dart';
import '../../domain/repositories/enterprise_repository.dart';
import '../../domain/services/audit/audit_service.dart';
import '../../domain/entities/audit_log.dart';
import '../../data/services/firestore_sync_service.dart';
import '../../domain/services/validation/permission_validator_service.dart';

/// Controller pour gérer les entreprises.
/// 
/// Intègre audit trail, Firestore sync et validation des permissions pour les entreprises.
class EnterpriseController {
  EnterpriseController(
    this._repository, {
    this.auditService,
    this.firestoreSync,
    this.permissionValidator,
  });

  final EnterpriseRepository _repository;
  final AuditService? auditService;
  final FirestoreSyncService? firestoreSync;
  final PermissionValidatorService? permissionValidator;

  /// Récupère toutes les entreprises.
  Future<List<Enterprise>> getAllEnterprises() async {
    return await _repository.getAllEnterprises();
  }

  /// Récupère les entreprises par type.
  Future<List<Enterprise>> getEnterprisesByType(String type) async {
    return await _repository.getEnterprisesByType(type);
  }

  /// Récupère une entreprise par son ID.
  Future<Enterprise?> getEnterpriseById(String enterpriseId) async {
    return await _repository.getEnterpriseById(enterpriseId);
  }

  /// Crée une nouvelle entreprise.
  /// 
  /// Logs audit trail and syncs to Firestore.
  /// Validates permissions before creating.
  Future<void> createEnterprise(
    Enterprise enterprise, {
    String? currentUserId,
  }) async {
    // Validate permissions
    if (currentUserId != null && permissionValidator != null) {
      final hasPermission = await permissionValidator!.canManageEnterprises(
        userId: currentUserId,
      );
      if (!hasPermission) {
        throw Exception('Permission denied: Cannot create enterprises');
      }
    }
    await _repository.createEnterprise(enterprise);

    // Sync to Firestore
    firestoreSync?.syncEnterpriseToFirestore(enterprise);

    // Log audit trail
    auditService?.logAction(
      action: AuditAction.create,
      entityType: 'enterprise',
      entityId: enterprise.id,
      userId: currentUserId ?? 'system',
      description: 'Enterprise created: ${enterprise.name}',
      newValue: enterprise.toMap(),
    );
  }

  /// Met à jour une entreprise.
  /// 
  /// Logs audit trail and syncs to Firestore.
  /// Validates permissions before updating.
  Future<void> updateEnterprise(
    Enterprise enterprise, {
    String? currentUserId,
    Enterprise? oldEnterprise,
  }) async {
    // Validate permissions
    if (currentUserId != null && permissionValidator != null) {
      final hasPermission = await permissionValidator!.canManageEnterprises(
        userId: currentUserId,
      );
      if (!hasPermission) {
        throw Exception('Permission denied: Cannot update enterprises');
      }
    }
    // Get old enterprise if not provided
    final oldEnterpriseData =
        oldEnterprise ?? await _repository.getEnterpriseById(enterprise.id);

    await _repository.updateEnterprise(enterprise);

    // Sync to Firestore
    firestoreSync?.syncEnterpriseToFirestore(enterprise, isUpdate: true);

    // Log audit trail
    auditService?.logAction(
      action: AuditAction.update,
      entityType: 'enterprise',
      entityId: enterprise.id,
      userId: currentUserId ?? 'system',
      description: 'Enterprise updated: ${enterprise.name}',
      oldValue: oldEnterpriseData?.toMap(),
      newValue: enterprise.toMap(),
    );
  }

  /// Supprime une entreprise.
  /// 
  /// Logs audit trail and syncs to Firestore.
  /// Validates permissions before deleting.
  Future<void> deleteEnterprise(
    String enterpriseId, {
    String? currentUserId,
    Enterprise? enterpriseData,
  }) async {
    // Validate permissions
    if (currentUserId != null && permissionValidator != null) {
      final hasPermission = await permissionValidator!.canManageEnterprises(
        userId: currentUserId,
      );
      if (!hasPermission) {
        throw Exception('Permission denied: Cannot delete enterprises');
      }
    }
    // Get enterprise data if not provided
    final enterprise =
        enterpriseData ?? await _repository.getEnterpriseById(enterpriseId);
    if (enterprise == null) return;

    await _repository.deleteEnterprise(enterpriseId);

    // Delete from Firestore
    firestoreSync?.deleteFromFirestore(
      collection: 'enterprises',
      documentId: enterpriseId,
    );

    // Log audit trail
    auditService?.logAction(
      action: AuditAction.delete,
      entityType: 'enterprise',
      entityId: enterpriseId,
      userId: currentUserId ?? 'system',
      description: 'Enterprise deleted: ${enterprise.name}',
      oldValue: enterprise.toMap(),
    );
  }

  /// Active ou désactive une entreprise.
  /// 
  /// Logs audit trail and syncs to Firestore.
  /// Validates permissions before toggling.
  Future<void> toggleEnterpriseStatus(
    String enterpriseId,
    bool isActive, {
    String? currentUserId,
  }) async {
    // Validate permissions
    if (currentUserId != null && permissionValidator != null) {
      final hasPermission = await permissionValidator!.canManageEnterprises(
        userId: currentUserId,
      );
      if (!hasPermission) {
        throw Exception('Permission denied: Cannot toggle enterprise status');
      }
    }
    final oldEnterprise = await _repository.getEnterpriseById(enterpriseId);
    if (oldEnterprise == null) return;

    await _repository.toggleEnterpriseStatus(enterpriseId, isActive);

    final updatedEnterprise = await _repository.getEnterpriseById(enterpriseId);
    if (updatedEnterprise != null) {
      // Sync to Firestore
      firestoreSync?.syncEnterpriseToFirestore(
        updatedEnterprise,
        isUpdate: true,
      );

      // Log audit trail
      auditService?.logAction(
        action: isActive ? AuditAction.activate : AuditAction.deactivate,
        entityType: 'enterprise',
        entityId: enterpriseId,
        userId: currentUserId ?? 'system',
        description:
            'Enterprise ${isActive ? 'activated' : 'deactivated'}: ${updatedEnterprise.name}',
        oldValue: oldEnterprise.toMap(),
        newValue: updatedEnterprise.toMap(),
      );
    }
  }
}

