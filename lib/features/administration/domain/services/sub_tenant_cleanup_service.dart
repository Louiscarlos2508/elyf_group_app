// lib/features/administration/domain/services/sub_tenant_cleanup_service.dart

import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../entities/enterprise.dart';
import '../repositories/enterprise_repository.dart';
import '../../../../core/logging/app_logger.dart';

/// Service pour migrer les Sous-tenants (POS Gaz et Agences OM) vers leur emplacement hiérarchique correct.
/// 
/// L'architecture cible est : 
/// - Gaz : /enterprises/{id}/pointsOfSale/{posId}
/// - Orange Money : /enterprises/{id}/agences/{agenceId}
/// 
/// Certains sous-tenants peuvent se trouver par erreur à la racine : /enterprises/{id}
class SubTenantCleanupService {
  SubTenantCleanupService(this._repository);

  final EnterpriseRepository _repository;
  final _firestore = FirebaseFirestore.instance;

  /// Lance la migration des sous-tenants détectés à la racine.
  Future<void> migrateRootSubTenantsToSubCollections() async {
    try {
      AppLogger.info('Démarrage de la migration des sous-tenants orphelins...', name: 'subtenant.cleanup');
      
      // 1. Récupérer toutes les entreprises de la racine
      final rootSnapshot = await _firestore.collection('enterprises').get();
      
      int migratedCount = 0;
      int errorCount = 0;

      for (final doc in rootSnapshot.docs) {
        final data = doc.data();
        final typeId = data['type'] as String?;
        final parentId = data['parentEnterpriseId'] as String?;
        
        if (typeId == null || parentId == null || parentId.isEmpty) continue;

        final type = EnterpriseType.fromId(typeId);
        
        // Identifier si c'est un sous-tenant orphelin (à la racine mais ayant un parentId)
        final bool isSubTenant = type.module.id == 'gaz' || type.module.id == 'mobile_money';
        final bool shouldBeInSubCollection = (type.id == 'gas_pos') || (type.id == 'mobile_money_agence');

        if (shouldBeInSubCollection) {
          try {
            final subCollectionName = type.id == 'gas_pos' ? 'pointsOfSale' : 'agences';
            
            developer.log('Migration détectée pour ${type.id}: ${doc.id} (${data['name']}) vers parent: $parentId ($subCollectionName)');
            
            // A. Copier vers la sous-collection du parent
            await _firestore
                .collection('enterprises')
                .doc(parentId)
                .collection(subCollectionName)
                .doc(doc.id)
                .set(data, SetOptions(merge: true));

            // B. Supprimer de la racine
            await _firestore.collection('enterprises').doc(doc.id).delete();
            
            migratedCount++;
            developer.log('Migration réussie pour ${doc.id}');
          } catch (e) {
            errorCount++;
            AppLogger.error('Erreur migration sous-tenant ${doc.id}: $e', name: 'subtenant.cleanup');
          }
        }
      }

      AppLogger.info('Migration terminée. Succès: $migratedCount, Erreurs: $errorCount', name: 'subtenant.cleanup');
    } catch (e, stackTrace) {
      AppLogger.error('Erreur critique pendant la migration des sous-tenants: $e', name: 'subtenant.cleanup', error: e, stackTrace: stackTrace);
    }
  }

  /// Nettoie les doublons locaux dans Drift.
  Future<void> cleanupLocalDuplicates() async {
    AppLogger.info('Nettoyage des doublons locaux (Drift) géré par les repositories.', name: 'subtenant.cleanup');
  }
}
