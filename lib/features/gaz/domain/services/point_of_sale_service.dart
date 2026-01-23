import 'dart:developer' as developer;

import '../entities/point_of_sale.dart';
import '../repositories/point_of_sale_repository.dart';

/// Service pour créer un point de vente.
///
/// Les points de vente sont stockés dans enterprises/{parentEnterpriseId}/pointofsale/
/// dans Firestore. Ils ne sont PAS des entreprises séparées dans la collection globale.
class PointOfSaleService {
  PointOfSaleService({
    required this.pointOfSaleRepository,
  });

  final PointOfSaleRepository pointOfSaleRepository;

  /// Crée un point de vente.
  ///
  /// Le point de vente sera synchronisé vers enterprises/{parentEnterpriseId}/pointofsale/{pointOfSaleId}
  /// dans Firestore.
  ///
  /// ⚠️ IMPORTANT: `parentEnterpriseId` doit être l'ID de l'entreprise mère (ex: 'gaz_1'),
  /// pas l'ID d'un point de vente existant.
  Future<PointOfSale> createPointOfSaleWithEnterprise({
    required String name,
    required String address,
    required String contact,
    required String parentEnterpriseId,
    required String createdByUserId,
    List<String>? cylinderIds,
  }) async {
    developer.log(
      'Création d\'un point de vente avec Enterprise: $name, parentEnterpriseId=$parentEnterpriseId',
      name: 'PointOfSaleService.createPointOfSaleWithEnterprise',
    );

    // Vérifier que parentEnterpriseId n'est pas un point de vente (ne commence pas par 'pos_')
    if (parentEnterpriseId.startsWith('pos_')) {
      developer.log(
        'ATTENTION: parentEnterpriseId commence par "pos_", ce qui suggère qu\'il s\'agit d\'un point de vente, pas de l\'entreprise mère. '
        'parentEnterpriseId=$parentEnterpriseId',
        name: 'PointOfSaleService.createPointOfSaleWithEnterprise',
      );
    }

    // ⚠️ IMPORTANT: Les points de vente sont stockés dans enterprises/{parentEnterpriseId}/pointofsale/
    // Ils ne sont PAS des entreprises séparées dans la collection globale enterprises/
    // Générer un ID unique pour le point de vente
    final pointOfSaleId = 'pos_${parentEnterpriseId}_${DateTime.now().millisecondsSinceEpoch}';

    // Créer le PointOfSale (sera synchronisé vers enterprises/{parentEnterpriseId}/pointofsale/{pointOfSaleId})
    final pointOfSale = PointOfSale(
      id: pointOfSaleId,
      name: name,
      address: address,
      contact: contact,
      parentEnterpriseId: parentEnterpriseId, // Entreprise mère (gaz_1)
      moduleId: 'gaz',
      cylinderIds: cylinderIds ?? [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await pointOfSaleRepository.addPointOfSale(pointOfSale);
    developer.log(
      '✅ PointOfSale créé: id=${pointOfSale.id}, parentEnterpriseId=$parentEnterpriseId',
      name: 'PointOfSaleService.createPointOfSaleWithEnterprise',
    );
    developer.log(
      '📍 Le point de vente sera synchronisé vers: enterprises/$parentEnterpriseId/pointofsale/${pointOfSale.id}',
      name: 'PointOfSaleService.createPointOfSaleWithEnterprise',
    );

    // Note: Les accès utilisateur pour les points de vente doivent être gérés séparément
    // car les points de vente ne sont pas des entreprises séparées dans la collection globale
    // L'accès se fait via l'entreprise mère (parentEnterpriseId) avec des permissions spécifiques
    developer.log(
      'ℹ️ Les accès utilisateur pour ce point de vente doivent être gérés via l\'entreprise mère ($parentEnterpriseId)',
      name: 'PointOfSaleService.createPointOfSaleWithEnterprise',
    );

    return pointOfSale;
  }
}
