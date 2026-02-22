

import '../../../../core/logging/app_logger.dart';
import '../entities/gas_sale.dart';
import '../entities/wholesaler.dart';
import '../repositories/gas_repository.dart';
import '../repositories/wholesaler_repository.dart';

/// Service pour gérer les grossistes.
class WholesalerService {
  WholesalerService({
    required this.gasRepository,
    required this.wholesalerRepository,
  });

  final GasRepository gasRepository;
  final WholesalerRepository wholesalerRepository;

  /// Récupère tous les grossistes formels depuis le repository.
  Future<List<Wholesaler>> getWholesalers(String enterpriseId) async {
    return wholesalerRepository.getWholesalers(enterpriseId);
  }

  /// Récupère tous les grossistes uniques (formels + découverts depuis l'historique).
  Future<List<Wholesaler>> getAllWholesalers(String enterpriseId) async {
    try {
      // 1. Récupérer les grossistes formels
      final formalWholesalers = await wholesalerRepository.getWholesalers(enterpriseId);
      final wholesalersMap = {for (var w in formalWholesalers) w.id: w};

      // 2. Récupérer toutes les ventes en gros pour extraire les grossistes (Discovery)
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
}
