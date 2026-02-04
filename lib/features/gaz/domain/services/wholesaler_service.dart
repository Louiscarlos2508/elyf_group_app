import 'dart:developer' as developer;


import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../entities/collection.dart';
import '../entities/gas_sale.dart';
import '../repositories/gas_repository.dart';
import '../repositories/tour_repository.dart';

/// Représente un grossiste avec ses informations.
class Wholesaler {
  const Wholesaler({
    required this.id,
    required this.name,
    this.phone,
    this.address,
  });

  final String id;
  final String name;
  final String? phone;
  final String? address;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Wholesaler && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Service pour gérer les grossistes.
///
/// Récupère tous les grossistes depuis :
/// - Les collections des tours précédents
/// - Les ventes en gros précédentes
class WholesalerService {
  WholesalerService({
    required this.tourRepository,
    required this.gasRepository,
  });

  final TourRepository tourRepository;
  final GasRepository gasRepository;

  /// Récupère tous les grossistes uniques depuis la base de données.
  ///
  /// Combine les grossistes des tours et des ventes en gros.
  Future<List<Wholesaler>> getAllWholesalers(String enterpriseId) async {
    try {
      final wholesalers = <String, Wholesaler>{};

      // 1. Récupérer tous les tours pour extraire les grossistes des collections
      final tours = await tourRepository.getTours(enterpriseId);
      for (final tour in tours) {
        final wholesalerCollections = tour.collections
            .where((c) => c.type == CollectionType.wholesaler)
            .toList();

        for (final collection in wholesalerCollections) {
          if (!wholesalers.containsKey(collection.clientId)) {
            wholesalers[collection.clientId] = Wholesaler(
              id: collection.clientId,
              name: collection.clientName,
              phone: collection.clientPhone.isNotEmpty
                  ? collection.clientPhone
                  : null,
              address: collection.clientAddress,
            );
          }
        }
      }

      // 2. Récupérer toutes les ventes en gros pour extraire les grossistes
      final wholesaleSales = await gasRepository.getSales();
      final wholesaleSalesFiltered = wholesaleSales
          .where((sale) =>
              sale.saleType == SaleType.wholesale &&
              sale.wholesalerId != null &&
              sale.wholesalerName != null)
          .toList();

      for (final sale in wholesaleSalesFiltered) {
        if (sale.wholesalerId != null && sale.wholesalerName != null) {
          if (!wholesalers.containsKey(sale.wholesalerId!)) {
            wholesalers[sale.wholesalerId!] = Wholesaler(
              id: sale.wholesalerId!,
              name: sale.wholesalerName!,
              phone: sale.customerPhone,
            );
          }
        }
      }

      // Trier par nom
      final sortedWholesalers = wholesalers.values.toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      developer.log(
        'Found ${sortedWholesalers.length} unique wholesalers',
        name: 'WholesalerService',
      );

      return sortedWholesalers;
    } catch (e, stackTrace) {
      developer.log(
        'Error getting all wholesalers',
        name: 'WholesalerService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
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
