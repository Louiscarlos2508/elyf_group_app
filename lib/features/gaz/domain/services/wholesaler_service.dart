

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../entities/collection.dart';
import '../entities/gas_sale.dart';
import '../entities/wholesaler.dart';
import '../repositories/gas_repository.dart';
import '../repositories/tour_repository.dart';
import '../repositories/wholesaler_repository.dart';

/// Service pour gérer les grossistes.
class WholesalerService {
  WholesalerService({
    required this.tourRepository,
    required this.gasRepository,
    required this.wholesalerRepository,
  });

  final TourRepository tourRepository;
  final GasRepository gasRepository;
  final WholesalerRepository wholesalerRepository;

  /// Récupère tous les grossistes formels depuis le repository.
  Future<List<Wholesaler>> getWholesalers(String enterpriseId) async {
    return wholesalerRepository.getWholesalers(enterpriseId);
  }

  /// Récupère tous les grossistes uniques (formels + découverts depuis l'historique).
  ///
  /// Utile pour la migration ou pour suggérer des clients non encore enregistrés.
  Future<List<Wholesaler>> getAllWholesalers(String enterpriseId) async {
    try {
      // 1. Récupérer les grossistes formels
      final formalWholesalers = await wholesalerRepository.getWholesalers(enterpriseId);
      final wholesalersMap = {for (var w in formalWholesalers) w.id: w};

      // 2. Récupérer tous les tours pour extraire les grossistes des collections (Discovery)
      final tours = await tourRepository.getTours(enterpriseId);
      for (final tour in tours) {
        final wholesalerCollections = tour.collections
            .where((c) => c.type == CollectionType.wholesaler)
            .toList();

        for (final collection in wholesalerCollections) {
          if (!wholesalersMap.containsKey(collection.clientId)) {
            wholesalersMap[collection.clientId] = Wholesaler(
              id: collection.clientId,
              enterpriseId: enterpriseId,
              name: collection.clientName,
              phone: collection.clientPhone.isNotEmpty
                  ? collection.clientPhone
                  : null,
              address: collection.clientAddress,
            );
          }
        }
      }

      // 3. Récupérer toutes les ventes en gros pour extraire les grossistes (Discovery)
      final wholesaleSales = await gasRepository.getSales();
      final wholesaleSalesFiltered = wholesaleSales
          .where((sale) =>
              sale.saleType == SaleType.wholesale &&
              sale.wholesalerId != null &&
              sale.wholesalerName != null)
          .toList();

      for (final sale in wholesaleSalesFiltered) {
        if (sale.wholesalerId != null && sale.wholesalerName != null) {
          if (!wholesalersMap.containsKey(sale.wholesalerId!)) {
            wholesalersMap[sale.wholesalerId!] = Wholesaler(
              id: sale.wholesalerId!,
              enterpriseId: enterpriseId,
              name: sale.wholesalerName!,
              phone: sale.customerPhone,
            );
          }
        }
      }

      // Trier par nom
      final sortedWholesalers = wholesalersMap.values.toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      AppLogger.info(
        'Found ${sortedWholesalers.length} total wholesalers (formal + discovered)',
        name: 'WholesalerService',
      );

      return sortedWholesalers;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error getting all wholesalers',
        name: 'WholesalerService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Enregistre formellement un grossiste.
  Future<void> registerWholesaler(Wholesaler wholesaler) async {
    await wholesalerRepository.createWholesaler(wholesaler);
  }

  /// Met à jour un grossiste.
  Future<void> updateWholesaler(Wholesaler wholesaler) async {
    await wholesalerRepository.updateWholesaler(wholesaler);
  }

  /// Supprime un grossiste.
  Future<void> deleteWholesaler(String id) async {
    await wholesalerRepository.deleteWholesaler(id);
  }

  /// Récupère les grossistes d'un tour spécifique.
  Future<List<Wholesaler>> getWholesalersForTour(
    String enterpriseId,
    String tourId,
  ) async {
    try {
      final tour = await tourRepository.getTourById(tourId);
      if (tour == null) return [];

      final wholesalerCollections = tour.collections
          .where((c) => c.type == CollectionType.wholesaler)
          .toList();

      return wholesalerCollections
          .map(
            (c) => Wholesaler(
              id: c.clientId,
              enterpriseId: enterpriseId,
              name: c.clientName,
              phone: c.clientPhone.isNotEmpty ? c.clientPhone : null,
              address: c.clientAddress,
            ),
          )
          .toList();
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error getting wholesalers for tour: $tourId - ${appException.message}',
        name: 'WholesalerService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
