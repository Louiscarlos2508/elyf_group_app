import 'dart:developer' as developer;

import '../../domain/entities/enterprise.dart';
import '../../domain/repositories/enterprise_repository.dart';
import '../../domain/repositories/user_repository.dart';
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
    this.userRepository,
  });

  final EnterpriseRepository _repository;
  final AuditService? auditService;
  final FirestoreSyncService? firestoreSync;
  final PermissionValidatorService? permissionValidator;
  final UserRepository? userRepository;

  /// Récupère toutes les entreprises.
  ///
  /// Lit UNIQUEMENT depuis la base locale (Drift) pour éviter la lecture simultanée.
  /// La synchronisation avec Firestore est gérée par le RealtimeSyncService qui
  /// fait un pull initial au démarrage et écoute les changements en temps réel.
  Future<List<Enterprise>> getAllEnterprises() async {
    try {
      // Lire UNIQUEMENT depuis la base locale (Drift) pour éviter la lecture simultanée
      // La synchronisation avec Firestore est gérée par le RealtimeSyncService
      final localEnterprises = await _repository.getAllEnterprises();

      // Dédupliquer les entreprises par ID pour éviter les duplications
      // (peut arriver si la synchronisation crée des doublons dans Drift)
      final uniqueEnterprises = <String, Enterprise>{};
      for (final enterprise in localEnterprises) {
        // Garder la première entreprise trouvée avec chaque ID
        if (!uniqueEnterprises.containsKey(enterprise.id)) {
          uniqueEnterprises[enterprise.id] = enterprise;
        }
      }

      return uniqueEnterprises.values.toList();
    } catch (e, stackTrace) {
      developer.log(
        'Error getting all enterprises from local database: $e',
        name: 'enterprise.controller',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
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

    // Note: La synchronisation vers Firestore est gérée automatiquement par le repository
    // via la queue de sync (SyncManager). Pas besoin d'appel manuel ici.

    // Récupérer le nom de l'utilisateur pour l'audit trail
    String? userDisplayName;
    if (currentUserId != null && userRepository != null) {
      try {
        final user = await userRepository!.getUserById(currentUserId);
        userDisplayName = user?.fullName;
      } catch (e) {
        developer.log(
          'Error fetching user for audit log: $e',
          name: 'enterprise.controller',
        );
      }
    }

    // Log audit trail
    if (auditService != null) {
      await auditService!.logAction(
        action: AuditAction.create,
        entityType: 'enterprise',
        entityId: enterprise.id,
        userId: currentUserId ?? 'system',
        description: 'Enterprise created: ${enterprise.name}',
        newValue: enterprise.toMap(),
        userDisplayName: userDisplayName,
      );
    } else {
      developer.log(
        'Warning: AuditService is null, audit log not created for enterprise: ${enterprise.id}',
        name: 'enterprise.controller',
      );
    }
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

    // Note: La synchronisation vers Firestore est gérée automatiquement par le repository
    // via la queue de sync (SyncManager). Pas besoin d'appel manuel ici.

    // Récupérer le nom de l'utilisateur pour l'audit trail
    String? userDisplayName;
    if (currentUserId != null && userRepository != null) {
      try {
        final user = await userRepository!.getUserById(currentUserId);
        userDisplayName = user?.fullName;
      } catch (e) {
        developer.log(
          'Error fetching user for audit log: $e',
          name: 'enterprise.controller',
        );
      }
    }

    // Log audit trail
    auditService?.logAction(
      action: AuditAction.update,
      entityType: 'enterprise',
      entityId: enterprise.id,
      userId: currentUserId ?? 'system',
      description: 'Enterprise updated: ${enterprise.name}',
      oldValue: oldEnterpriseData?.toMap(),
      newValue: enterprise.toMap(),
      userDisplayName: userDisplayName,
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

    // Note: La synchronisation vers Firestore est gérée automatiquement par le repository
    // via la queue de sync (SyncManager). Pas besoin d'appel manuel ici.

    // Récupérer le nom de l'utilisateur pour l'audit trail
    String? userDisplayName;
    if (currentUserId != null && userRepository != null) {
      try {
        final user = await userRepository!.getUserById(currentUserId);
        userDisplayName = user?.fullName;
      } catch (e) {
        developer.log(
          'Error fetching user for audit log: $e',
          name: 'enterprise.controller',
        );
      }
    }

    // Log audit trail
    auditService?.logAction(
      action: AuditAction.delete,
      entityType: 'enterprise',
      entityId: enterpriseId,
      userId: currentUserId ?? 'system',
      description: 'Enterprise deleted: ${enterprise.name}',
      oldValue: enterprise.toMap(),
      userDisplayName: userDisplayName,
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
      // Note: La synchronisation vers Firestore est gérée automatiquement par le repository
      // via la queue de sync (SyncManager). Pas besoin d'appel manuel ici.

      // Récupérer le nom de l'utilisateur pour l'audit trail
      String? userDisplayName;
      if (currentUserId != null && userRepository != null) {
        try {
          final user = await userRepository!.getUserById(currentUserId);
          userDisplayName = user?.fullName;
        } catch (e) {
          developer.log(
            'Error fetching user for audit log: $e',
            name: 'enterprise.controller',
          );
        }
      }

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
        userDisplayName: userDisplayName,
      );
    }
  }
}
