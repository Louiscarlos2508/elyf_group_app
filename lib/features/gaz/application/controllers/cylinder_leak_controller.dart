import '../../domain/entities/cylinder.dart';
import '../../domain/entities/cylinder_leak.dart';
import '../../domain/repositories/cylinder_leak_repository.dart';
import '../../domain/repositories/cylinder_stock_repository.dart';

/// Contrôleur pour la gestion des bouteilles avec fuites.
class CylinderLeakController {
  CylinderLeakController(this._leakRepository, this._stockRepository);

  final CylinderLeakRepository _leakRepository;
  final CylinderStockRepository _stockRepository;

  /// Récupère les fuites.
  Future<List<CylinderLeak>> getLeaks(
    String enterpriseId, {
    LeakStatus? status,
  }) async {
    return _leakRepository.getLeaks(enterpriseId, status: status);
  }

  /// Observe les fuites en temps réel.
  Stream<List<CylinderLeak>> watchLeaks(
    String enterpriseId, {
    LeakStatus? status,
  }) {
    return _leakRepository.watchLeaks(enterpriseId, status: status);
  }

  /// Récupère une fuite par ID.
  Future<CylinderLeak?> getLeakById(String id) async {
    return _leakRepository.getLeakById(id);
  }

  /// Signale une fuite (workflow: Identification -> Enregistrement).
  Future<String> reportLeak(
    String cylinderId,
    int weight,
    String enterpriseId, {
    String? tourId,
    String? notes,
  }) async {
    // Créer l'enregistrement de fuite
    final leak = CylinderLeak(
      id: '',
      enterpriseId: enterpriseId,
      cylinderId: cylinderId,
      weight: weight,
      reportedDate: DateTime.now(),
      status: LeakStatus.reported,
      tourId: tourId,
      notes: notes,
    );

    final leakId = await _leakRepository.reportLeak(leak);

    // Workflow: Sortie du stock "Pleines" (sans vente)
    // On cherche le stock pleines correspondant et on le marque comme leak
    final stocks = await _stockRepository.getStocksByWeight(
      enterpriseId,
      weight,
    );

    final fullStocks = stocks
        .where((s) => s.status == CylinderStatus.full && s.quantity > 0)
        .toList();

    if (fullStocks.isNotEmpty) {
      // On diminue la quantité du premier stock trouvé
      final stock = fullStocks.first;
      await _stockRepository.updateStockQuantity(stock.id, stock.quantity - 1);
    }

    return leakId;
  }

  /// Marque une fuite comme envoyée pour échange.
  Future<void> markAsSentForExchange(String leakId) async {
    await _leakRepository.markAsSentForExchange(leakId);
  }

  /// Marque une fuite comme échangée.
  Future<void> markAsExchanged(String leakId) async {
    final leak = await _leakRepository.getLeakById(leakId);
    if (leak != null) {
      await _leakRepository.markAsExchanged(leakId, DateTime.now());

      // Workflow: Réception échange gratuit
      // Le stock redevient "Pleines" (sera géré lors de l'implémentation réelle)
    }
  }
}
