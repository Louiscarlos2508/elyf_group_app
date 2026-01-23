import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/logging/app_logger.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/drift_service.dart';
import '../../../../core/offline/offline_repository.dart';
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

      // Récupérer aussi les points de vente
      // Essayer d'abord depuis Drift, puis depuis Firestore si nécessaire
      final driftService = (_repository as OfflineRepository<Enterprise>).driftService;
      
      developer.log(
        'EnterpriseController.getAllEnterprises: Recherche des points de vente',
        name: 'enterprise.controller',
      );
      
      List<Map<String, dynamic>> posDataList = [];
      
      // 1. Essayer de récupérer depuis Drift
      try {
        final posRecords = await driftService.records.listForCollection(
          collectionName: 'pointOfSale',
          moduleType: 'gaz',
        );
        
        AppLogger.debug(
          'EnterpriseController.getAllEnterprises: ${posRecords.length} enregistrements pointOfSale trouvés dans Drift',
          name: 'enterprise.controller',
        );
        developer.log(
          'EnterpriseController.getAllEnterprises: ${posRecords.length} enregistrements pointOfSale trouvés dans Drift',
          name: 'enterprise.controller',
        );
        
        for (final record in posRecords) {
          try {
            final map = jsonDecode(record.dataJson) as Map<String, dynamic>;
            posDataList.add(map);
            developer.log(
              'EnterpriseController.getAllEnterprises: POS depuis Drift - id=${map['id']}, name=${map['name']}, parentEnterpriseId=${map['parentEnterpriseId']}',
              name: 'enterprise.controller',
            );
          } catch (e, stackTrace) {
            final appException = ErrorHandler.instance.handleError(e, stackTrace);
            AppLogger.warning(
              'EnterpriseController.getAllEnterprises: Erreur parsing record Drift: ${appException.message}',
              name: 'enterprise.controller',
              error: e,
              stackTrace: stackTrace,
            );
          }
        }
      } catch (e, stackTrace) {
        final appException = ErrorHandler.instance.handleError(e, stackTrace);
        AppLogger.warning(
          'EnterpriseController.getAllEnterprises: Erreur lors de la récupération depuis Drift: ${appException.message}',
          name: 'enterprise.controller',
          error: e,
          stackTrace: stackTrace,
        );
      }
      
      // 2. Récupérer aussi depuis Firestore pour compléter Drift
      // NOTE: On récupère aussi depuis Firestore même si Drift contient des données,
      // pour s'assurer qu'on a tous les points de vente (au cas où certains ne seraient pas encore synchronisés)
      if (firestoreSync != null) {
        AppLogger.debug(
          'EnterpriseController.getAllEnterprises: Récupération des points de vente depuis Firestore...',
          name: 'enterprise.controller',
        );
        try {
          developer.log(
            'EnterpriseController.getAllEnterprises: Récupération des points de vente depuis Firestore (pour compléter Drift)',
            name: 'enterprise.controller',
          );
          
          // Récupérer toutes les entreprises pour connaître leurs IDs
          final allEnterpriseIds = uniqueEnterprises.values.map((e) => e.id).toList();
          AppLogger.debug(
            'EnterpriseController.getAllEnterprises: Recherche des points de vente pour ${allEnterpriseIds.length} entreprises: ${allEnterpriseIds.join(", ")}',
            name: 'enterprise.controller',
          );
          
          // Pour chaque entreprise, récupérer ses points de vente
          for (final enterpriseId in allEnterpriseIds) {
            try {
              final posCollection = FirebaseFirestore.instance
                  .collection('enterprises')
                  .doc(enterpriseId)
                  .collection('pointsOfSale');
              
              final posSnapshot = await posCollection.get();
              
              AppLogger.debug(
                'EnterpriseController.getAllEnterprises: ${posSnapshot.docs.length} points de vente trouvés dans Firestore pour entreprise $enterpriseId',
                name: 'enterprise.controller',
              );
              developer.log(
                'EnterpriseController.getAllEnterprises: ${posSnapshot.docs.length} points de vente trouvés dans Firestore pour entreprise $enterpriseId',
                name: 'enterprise.controller',
              );
              
              for (final doc in posSnapshot.docs) {
                try {
                  final data = doc.data();
                  final posData = Map<String, dynamic>.from(data)
                    ..['id'] = doc.id
                    ..['parentEnterpriseId'] = enterpriseId;
                  
                  posDataList.add(posData);
                  
                  developer.log(
                    'EnterpriseController.getAllEnterprises: POS depuis Firestore - id=${doc.id}, name=${data['name']}, parentEnterpriseId=$enterpriseId',
                    name: 'enterprise.controller',
                  );
                } catch (e, stackTrace) {
                  final appException = ErrorHandler.instance.handleError(e, stackTrace);
                  AppLogger.warning(
                    'EnterpriseController.getAllEnterprises: Erreur parsing doc Firestore: ${appException.message}',
                    name: 'enterprise.controller',
                    error: e,
                    stackTrace: stackTrace,
                  );
                }
              }
            } catch (e, stackTrace) {
              final appException = ErrorHandler.instance.handleError(e, stackTrace);
              AppLogger.warning(
                'EnterpriseController.getAllEnterprises: Erreur récupération POS pour entreprise $enterpriseId: ${appException.message}',
                name: 'enterprise.controller',
                error: e,
                stackTrace: stackTrace,
              );
            }
          }
        } catch (e, stackTrace) {
          final appException = ErrorHandler.instance.handleError(e, stackTrace);
          AppLogger.warning(
            'EnterpriseController.getAllEnterprises: Erreur lors de la récupération depuis Firestore: ${appException.message}',
            name: 'enterprise.controller',
            error: e,
            stackTrace: stackTrace,
          );
        }
      }
      
      // Dédupliquer les points de vente par ID pour éviter les doublons
      final uniquePosData = <String, Map<String, dynamic>>{};
      for (final posData in posDataList) {
        final posId = posData['id'] as String?;
        if (posId != null && !uniquePosData.containsKey(posId)) {
          uniquePosData[posId] = posData;
        }
      }
      posDataList = uniquePosData.values.toList();
      
      AppLogger.debug(
        'EnterpriseController.getAllEnterprises: Total de ${posDataList.length} points de vente récupérés (Drift + Firestore, après déduplication)',
        name: 'enterprise.controller',
      );
      developer.log(
        'EnterpriseController.getAllEnterprises: Total de ${posDataList.length} points de vente récupérés (Drift + Firestore, après déduplication)',
        name: 'enterprise.controller',
      );

      // Créer une map des entreprises pour trouver les entreprises mères
      final enterprisesMap = {for (var e in uniqueEnterprises.values) e.id: e};
      
      developer.log(
        'EnterpriseController.getAllEnterprises: Map des entreprises créée avec ${enterprisesMap.length} entreprises (IDs: ${enterprisesMap.keys.toList()})',
        name: 'enterprise.controller',
      );

      int posAdded = 0;
      int posSkipped = 0;
      int posErrors = 0;

      // Convertir les points de vente en Enterprise et les ajouter
      for (final map in posDataList) {
        try {
          final posId = map['id'] as String?;
          
          if (posId == null) {
            developer.log(
              'EnterpriseController.getAllEnterprises: Point de vente sans ID, ignoré',
              name: 'enterprise.controller',
            );
            posSkipped++;
            continue;
          }
          
          developer.log(
            'EnterpriseController.getAllEnterprises: Traitement point de vente: id=$posId, parentEnterpriseId=${map['parentEnterpriseId']}, enterpriseId=${map['enterpriseId']}',
            name: 'enterprise.controller',
          );
          
          // Vérifier si ce point de vente n'est pas déjà dans la liste (éviter doublons)
          if (uniqueEnterprises.containsKey(posId)) {
            developer.log(
              'EnterpriseController.getAllEnterprises: Point de vente $posId déjà présent, ignoré',
              name: 'enterprise.controller',
            );
            posSkipped++;
            continue;
          }

          // Essayer plusieurs façons de trouver le parentEnterpriseId
          final parentEnterpriseId = map['parentEnterpriseId'] as String? ?? 
                                     map['enterpriseId'] as String?;
          
          if (parentEnterpriseId == null) {
            developer.log(
              'EnterpriseController.getAllEnterprises: ⚠️ Point de vente $posId sans parentEnterpriseId, ignoré',
              name: 'enterprise.controller',
            );
            posSkipped++;
            continue;
          }
          
          developer.log(
            'EnterpriseController.getAllEnterprises: parentEnterpriseId déterminé: $parentEnterpriseId',
            name: 'enterprise.controller',
          );
          
          // Trouver l'entreprise mère
          final parentEnterprise = enterprisesMap[parentEnterpriseId];
          
          if (parentEnterprise == null) {
            developer.log(
              'EnterpriseController.getAllEnterprises: ⚠️ Entreprise mère non trouvée pour point de vente $posId (parentEnterpriseId=$parentEnterpriseId). Entreprises disponibles: ${enterprisesMap.keys.join(", ")}',
              name: 'enterprise.controller',
            );
            posSkipped++;
            continue;
          }

          // Convertir les Timestamp Firestore en DateTime si nécessaire
          DateTime? createdAt;
          DateTime? updatedAt;
          
          if (map['createdAt'] != null) {
            if (map['createdAt'] is Timestamp) {
              createdAt = (map['createdAt'] as Timestamp).toDate();
            } else if (map['createdAt'] is String) {
              createdAt = DateTime.tryParse(map['createdAt'] as String);
            }
          }
          
          if (map['updatedAt'] != null) {
            if (map['updatedAt'] is Timestamp) {
              updatedAt = (map['updatedAt'] as Timestamp).toDate();
            } else if (map['updatedAt'] is String) {
              updatedAt = DateTime.tryParse(map['updatedAt'] as String);
            }
          }

          // Créer un Enterprise-like object pour le point de vente
          final posEnterprise = Enterprise(
            id: posId,
            name: (map['name'] as String?) ?? 'Point de vente',
            type: parentEnterprise.type,
            description: 'Point de vente de ${parentEnterprise.name} - ${(map['address'] as String?) ?? ''}',
            address: (map['address'] as String?) ?? '',
            phone: (map['contact'] as String?) ?? '',
            isActive: (map['isActive'] as bool?) ?? true,
            createdAt: createdAt,
            updatedAt: updatedAt,
          );

          uniqueEnterprises[posId] = posEnterprise;
          posAdded++;
          developer.log(
            'EnterpriseController.getAllEnterprises: ✅ Point de vente ajouté: ${posEnterprise.name} (id: $posId, parent: ${parentEnterprise.name})',
            name: 'enterprise.controller',
          );
        } catch (e, stackTrace) {
          posErrors++;
          final appException = ErrorHandler.instance.handleError(e, stackTrace);
          AppLogger.warning(
            'EnterpriseController.getAllEnterprises: ❌ Erreur lors de la conversion d\'un point de vente: ${appException.message}',
            name: 'enterprise.controller',
            error: e,
            stackTrace: stackTrace,
          );
        }
      }
      
      developer.log(
        'EnterpriseController.getAllEnterprises: Résumé points de vente - Ajoutés: $posAdded, Ignorés: $posSkipped, Erreurs: $posErrors',
        name: 'enterprise.controller',
      );

      final result = uniqueEnterprises.values.toList();
      developer.log(
        'EnterpriseController.getAllEnterprises: Total de ${result.length} entreprises (dont $posAdded points de vente ajoutés, $posSkipped ignorés, $posErrors erreurs)',
        name: 'enterprise.controller',
      );

      return result;
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error getting all enterprises from local database: ${appException.message}',
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
}
