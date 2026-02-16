
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/wholesaler.dart';
import '../../domain/services/wholesaler_service.dart';

/// Contrôleur pour gérer les grossistes.
class WholesalerController {
  WholesalerController({
    required this.service,
  });

  final WholesalerService service;

  /// Récupère tous les grossistes formels.
  Future<List<Wholesaler>> getWholesalers(String enterpriseId) async {
    return service.getWholesalers(enterpriseId);
  }

  /// Récupère tous les grossistes (formels + découverts).
  Future<List<Wholesaler>> getAllWholesalers(String enterpriseId) async {
    return service.getAllWholesalers(enterpriseId);
  }

  /// Enregistre un grossiste.
  Future<void> registerWholesaler(Wholesaler wholesaler) async {
    await service.registerWholesaler(wholesaler);
  }

  /// Met à jour un grossiste.
  Future<void> updateWholesaler(Wholesaler wholesaler) async {
    await service.updateWholesaler(wholesaler);
  }

  /// Supprime un grossiste.
  Future<void> deleteWholesaler(String id) async {
    await service.deleteWholesaler(id);
  }
}
