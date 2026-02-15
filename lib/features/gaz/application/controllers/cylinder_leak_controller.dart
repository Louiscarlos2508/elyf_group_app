import '../../domain/entities/cylinder_leak.dart';
import '../../domain/repositories/cylinder_leak_repository.dart';
import '../../domain/repositories/cylinder_stock_repository.dart';
import '../../domain/services/transaction_service.dart';

/// Contrôleur pour la gestion des bouteilles avec fuites.
class CylinderLeakController {
  CylinderLeakController(this._leakRepository, this._stockRepository, this._transactionService);

  final CylinderLeakRepository _leakRepository;
  final CylinderStockRepository _stockRepository;
  final TransactionService _transactionService;

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
    LeakSource source = LeakSource.store,
    bool isFullLoss = true,
    double? estimatedLossVolume,
    String? userId,
  }) async {
    // Créer l'enregistrement de fuite
    final leak = CylinderLeak(
      id: '',
      enterpriseId: enterpriseId,
      cylinderId: cylinderId,
      weight: weight,
      reportedDate: DateTime.now(),
      status: LeakStatus.reported,
      source: source,
      isFullLoss: isFullLoss,
      estimatedLossVolume: estimatedLossVolume,
      tourId: tourId,
      notes: notes,
      reportedBy: userId,
    );

    // Utiliser la transaction atomique du service
    await _transactionService.executeLeakDeclaration(
      leak: leak,
      userId: userId ?? '',
    );

    return leak.id; 
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
    }
  }
}
