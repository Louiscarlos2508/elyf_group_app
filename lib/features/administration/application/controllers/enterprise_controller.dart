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
  /// Si la base locale est vide, récupère automatiquement depuis Firestore
  /// et sauvegarde localement pour la prochaine fois.
  Future<List<Enterprise>> getAllEnterprises() async {
    try {
      final localEnterprises = await _repository.getAllEnterprises();

      // Si la base locale contient des entreprises, les retourner
      if (localEnterprises.isNotEmpty) {
        return localEnterprises;
      }

      // Si la base locale est vide, essayer de récupérer depuis Firestore
      // et sauvegarder localement pour la prochaine fois
      if (firestoreSync != null) {
        try {
          final firestoreEnterprises = await firestoreSync!
              .pullEnterprisesFromFirestore();

          // Sauvegarder chaque entreprise dans la base locale SANS déclencher de sync
          // (ces entités viennent déjà de Firestore, pas besoin de les re-synchroniser)
          for (final enterprise in firestoreEnterprises) {
            try {
              // Utiliser directement saveToLocal pour éviter de mettre dans la queue de sync
              // Les entités viennent déjà de Firestore, donc pas besoin de les re-sync
              await (_repository as dynamic).saveToLocal(enterprise);
            } catch (e) {
              // Ignorer les erreurs de sauvegarde locale individuelle
              // (peut-être que l'entreprise existe déjà)
              developer.log(
                'Error saving enterprise from Firestore to local database: ${enterprise.id}',
                name: 'enterprise.controller',
              );
            }
          }

          // Retourner les entreprises depuis Firestore
          if (firestoreEnterprises.isNotEmpty) {
            developer.log(
              'Loaded ${firestoreEnterprises.length} enterprises from Firestore (local database was empty)',
              name: 'enterprise.controller',
            );
            return firestoreEnterprises;
          }
        } catch (e) {
          developer.log(
            'Error fetching enterprises from Firestore (will use empty local list): $e',
            name: 'enterprise.controller',
          );
          // Continuer avec la liste locale (vide)
        }
      }

      return localEnterprises;
    } catch (e, stackTrace) {
      developer.log(
        'Error getting all enterprises from local database, trying Firestore: $e',
        name: 'enterprise.controller',
        error: e,
        stackTrace: stackTrace,
      );

      // En cas d'erreur locale, essayer Firestore
      if (firestoreSync != null) {
        try {
          final firestoreEnterprises = await firestoreSync!
              .pullEnterprisesFromFirestore();
          developer.log(
            'Loaded ${firestoreEnterprises.length} enterprises from Firestore (local database error)',
            name: 'enterprise.controller',
          );
          return firestoreEnterprises;
        } catch (e) {
          developer.log(
            'Error fetching enterprises from Firestore: $e',
            name: 'enterprise.controller',
          );
          return [];
        }
      }

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

    // Sync to Firestore
    firestoreSync?.syncEnterpriseToFirestore(enterprise);

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

    // Sync to Firestore
    firestoreSync?.syncEnterpriseToFirestore(enterprise, isUpdate: true);

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

    // Delete from Firestore
    firestoreSync?.deleteFromFirestore(
      collection: 'enterprises',
      documentId: enterpriseId,
    );

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
      // Sync to Firestore
      firestoreSync?.syncEnterpriseToFirestore(
        updatedEnterprise,
        isUpdate: true,
      );

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
