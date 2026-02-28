import 'dart:developer' as developer;

import '../../../../core/logging/app_logger.dart';

// import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/drift_service.dart';
import '../../domain/entities/enterprise.dart';
import '../../domain/repositories/enterprise_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/repositories/admin_repository.dart';
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
    this.adminRepository,
  });

  final EnterpriseRepository _repository;
  final AuditService? auditService;
  final FirestoreSyncService? firestoreSync;
  final PermissionValidatorService? permissionValidator;
  final UserRepository? userRepository;
  final AdminRepository? adminRepository;

  /// Récupère toutes les entreprises.
  ///
  /// Inclut les entreprises normales ET les points de vente (qui sont des sous-entreprises).
  /// Lit UNIQUEMENT depuis la base locale (Drift) pour éviter la lecture simultanée.
  /// La synchronisation avec Firestore est gérée par le RealtimeSyncService qui
  /// fait un pull initial au démarrage et écoute les changements en temps réel.
  Future<List<Enterprise>> getAllEnterprises() async {
    try {
      // Lire depuis le repository qui agrège désormais entreprises et POS
      final localEnterprises = await _repository.getAllEnterprises();

      // Dédupliquer par ID au cas où (sécurité supplémentaire)
      final uniqueEnterprises = <String, Enterprise>{};
      for (final enterprise in localEnterprises) {
        if (!uniqueEnterprises.containsKey(enterprise.id)) {
          uniqueEnterprises[enterprise.id] = enterprise;
        }
      }

      return uniqueEnterprises.values.toList();
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error getting all enterprises: ${appException.message}',
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
        throw AuthorizationException(
          'Permission denied: Cannot create enterprises',
          'PERMISSION_DENIED',
        );
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
      } catch (e, stackTrace) {
        final appException = ErrorHandler.instance.handleError(e, stackTrace);
        AppLogger.warning(
          'Error fetching user for audit log: ${appException.message}',
          name: 'enterprise.controller',
          error: e,
          stackTrace: stackTrace,
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
        throw AuthorizationException(
          'Permission denied: Cannot update enterprises',
          'PERMISSION_DENIED',
        );
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
      } catch (e, stackTrace) {
        final appException = ErrorHandler.instance.handleError(e, stackTrace);
        AppLogger.warning(
          'Error fetching user for audit log: ${appException.message}',
          name: 'enterprise.controller',
          error: e,
          stackTrace: stackTrace,
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
        throw AuthorizationException(
          'Permission denied: Cannot delete enterprises',
          'PERMISSION_DENIED',
        );
      }
    }
    // Get enterprise data if not provided
    final enterprise =
        enterpriseData ?? await _repository.getEnterpriseById(enterpriseId);
    if (enterprise == null) return;

    try {
      // 1. Supprimer toutes les données liées à cette entreprise dans OfflineRecords
      // et SyncOperations (cascade delete)
      await DriftService.instance.clearEnterpriseData(enterpriseId);
      developer.log(
        'Données de l\'entreprise $enterpriseId supprimées de Drift',
        name: 'enterprise.controller',
      );

      // 2. Supprimer les EnterpriseModuleUser liés à cette entreprise
      if (adminRepository != null) {
        try {
          final assignments = await adminRepository!.getEnterpriseUsers(enterpriseId);
          for (final assignment in assignments) {
            await adminRepository!.removeUserFromEnterprise(
              assignment.userId,
              assignment.enterpriseId,
              assignment.moduleId,
            );
          }
          developer.log(
            '${assignments.length} assignations supprimées pour l\'entreprise $enterpriseId',
            name: 'enterprise.controller',
          );
        } catch (e, stackTrace) {
          final appException = ErrorHandler.instance.handleError(e, stackTrace);
          AppLogger.warning(
            'Erreur lors de la suppression des assignations: ${appException.message}',
            name: 'enterprise.controller',
            error: e,
            stackTrace: stackTrace,
          );
          // Continuer même si la suppression des assignations échoue
        }
      }

      // 3. Supprimer l'entreprise elle-même
      await _repository.deleteEnterprise(enterpriseId);
      developer.log(
        'Entreprise $enterpriseId supprimée avec succès',
        name: 'enterprise.controller',
      );
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Erreur lors de la suppression de l\'entreprise $enterpriseId: ${appException.message}',
        name: 'enterprise.controller',
        error: e,
        stackTrace: stackTrace,
      );
      
      // Fournir un message d'erreur plus clair
      if (e.toString().contains('2067') || e.toString().contains('FOREIGN KEY')) {
        throw ValidationException(
          'Impossible de supprimer l\'entreprise "${enterprise.name}". '
          'Elle contient encore des données liées (ventes, stocks, utilisateurs, etc.). '
          'Veuillez supprimer ou transférer ces données avant de supprimer l\'entreprise.',
          'ENTERPRISE_HAS_RELATED_DATA',
        );
      }
      rethrow;
    }

    // Note: La synchronisation vers Firestore est gérée automatiquement par le repository
    // via la queue de sync (SyncManager). Pas besoin d'appel manuel ici.

    // Récupérer le nom de l'utilisateur pour l'audit trail
    String? userDisplayName;
    if (currentUserId != null && userRepository != null) {
      try {
        final user = await userRepository!.getUserById(currentUserId);
        userDisplayName = user?.fullName;
      } catch (e, stackTrace) {
        final appException = ErrorHandler.instance.handleError(e, stackTrace);
        AppLogger.warning(
          'Error fetching user for audit log: ${appException.message}',
          name: 'enterprise.controller',
          error: e,
          stackTrace: stackTrace,
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
        throw AuthorizationException(
          'Permission denied: Cannot toggle enterprise status',
          'PERMISSION_DENIED',
        );
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

  /// Surveille toutes les entreprises (Stream).
  Stream<List<Enterprise>> watchAllEnterprises() {
    return _repository.watchAllEnterprises();
  }

  /// Récupère explicitement des entreprises manquantes depuis Firestore.
  ///
  /// Utile pour la synchronisation initiale ou lorsqu'une assignation existe
  /// mais que le document entreprise n'est pas encore présent localement.
  Future<List<Enterprise>> fetchMissingEnterprises(List<String> enterpriseIds) async {
    if (enterpriseIds.isEmpty || firestoreSync == null) return [];

    final fetchedEnterprises = <Enterprise>[];

    try {
      AppLogger.info(
        'Fetching ${enterpriseIds.length} missing enterprises from Firestore: ${enterpriseIds.join(", ")}',
        name: 'enterprise.controller',
      );

      for (final id in enterpriseIds) {
        try {
          // Utiliser le service de synchro qui gère maintenant les sous-collections
          await firestoreSync!.syncSpecificEnterprise(id);
          
          // Récupérer depuis le repository local pour obtenir l'objet Enterprise complet
          final enterprise = await _repository.getEnterpriseById(id);
          if (enterprise != null) {
            fetchedEnterprises.add(enterprise);
            developer.log(
              'Fetched and saved missing enterprise: ${enterprise.name} (${enterprise.id})',
              name: 'enterprise.controller',
            );
          }
        } catch (e) {
          developer.log(
            'Error fetching enterprise $id: $e',
            name: 'enterprise.controller',
          );
        }
      }
    } catch (e, stackTrace) {
       final appException = ErrorHandler.instance.handleError(e, stackTrace);
       AppLogger.error(
        'Error in fetchMissingEnterprises: ${appException.message}',
        name: 'enterprise.controller',
        error: e,
        stackTrace: stackTrace,
      );
    }

    return fetchedEnterprises;
  }
}
