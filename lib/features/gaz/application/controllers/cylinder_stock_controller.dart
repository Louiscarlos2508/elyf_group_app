import '../../domain/entities/cylinder.dart';
import '../../domain/entities/cylinder_stock.dart';
import '../../domain/repositories/cylinder_stock_repository.dart';
import '../../domain/services/stock_service.dart';
import '../../domain/services/transaction_service.dart';

/// Contrôleur pour la gestion des stocks de bouteilles.
class CylinderStockController {
  CylinderStockController(this._repository, this._stockService, this._transactionService);

  final CylinderStockRepository _repository;
  final StockService _stockService;
  final TransactionService _transactionService;

  /// Récupère les stocks par statut.
  Future<List<CylinderStock>> getStocksByStatus(
    String enterpriseId,
    CylinderStatus status, {
    String? siteId,
  }) async {
    return _repository.getStocksByStatus(enterpriseId, status, siteId: siteId);
  }

  /// Observe les stocks en temps réel.
  Stream<List<CylinderStock>> watchStocks(
    String enterpriseId, {
    CylinderStatus? status,
    String? siteId,
    List<String>? enterpriseIds,
  }) {
    if (enterpriseIds != null && enterpriseIds.isNotEmpty) {
      return _repository.watchStocksForEnterprises(
        enterpriseIds,
        status: status,
      );
    }
    return _repository.watchStocks(
      enterpriseId,
      status: status,
      siteId: siteId,
    );
  }

  /// Récupère les stocks par poids.
  Future<List<CylinderStock>> getStocksByWeight(
    String enterpriseId,
    int weight, {
    String? siteId,
  }) async {
    return _repository.getStocksByWeight(enterpriseId, weight, siteId: siteId);
  }

  /// Récupère un stock par ID.
  Future<CylinderStock?> getStockById(String id) async {
    return _repository.getStockById(id);
  }

  /// Change le statut d'un stock.
  Future<void> changeStockStatus(
    String stockId,
    CylinderStatus newStatus,
  ) async {
    await _stockService.changeStockStatus(stockId, newStatus);
  }

  /// Ajuste la quantité d'un stock avec log d'audit.
  Future<void> adjustStockQuantity(
    String stockId,
    int newQuantity, {
    required String userId,
    String? reason,
  }) async {
    final stock = await _repository.getStockById(stockId);
    if (stock == null) return;

    await _transactionService.executeStockAdjustment(
      stock: stock,
      newQuantity: newQuantity,
      userId: userId,
      reason: reason,
    );
  }

  /// Récupère le stock disponible (pleines) pour un format.
  Future<int> getAvailableStock(
    String enterpriseId,
    int weight, {
    String? siteId,
  }) async {
    return _stockService.getAvailableStock(
      enterpriseId,
      weight,
      siteId: siteId,
    );
  }

  /// Récupère les stocks par site.
  Future<List<CylinderStock>> getStockBySite(
    String enterpriseId,
    String siteId,
  ) async {
    return _repository.getStockBySite(enterpriseId, siteId);
  }

  /// Ajoute un nouveau stock.
  Future<void> addStock(CylinderStock stock) async {
    await _repository.addStock(stock);
  }

  /// Met à jour un stock.
  Future<void> updateStock(CylinderStock stock) async {
    await _repository.updateStock(stock);
  }

  /// Réception de stock (Réapprovisionnement) avec enregistrement comptable.
  Future<void> replenishStock({
    required String enterpriseId,
    required String cylinderId,
    required int weight,
    required int quantity,
    required double unitCost,
    required String userId,
    int leakySwappedQuantity = 0, // Nombre de bouteilles de fuite échangées gratuitement
    String? siteId,
    String? supplierName,
  }) async {
    await _transactionService.executeReplenishmentTransaction(
      enterpriseId: enterpriseId,
      cylinderId: cylinderId,
      weight: weight,
      quantity: quantity,
      unitCost: unitCost,
      userId: userId,
      leakySwappedQuantity: leakySwappedQuantity,
      siteId: siteId,
      supplierName: supplierName,
    );
  }

  /// Remboursement de consigné (Retour bouteille vide).
  Future<void> refundDeposit({
    required String enterpriseId,
    required String cylinderId,
    required int weight,
    required int quantity,
    required String userId,
    String? siteId,
  }) async {
    await _transactionService.executeDepositRefund(
      enterpriseId: enterpriseId,
      cylinderId: cylinderId,
      weight: weight,
      quantity: quantity,
      userId: userId,
      siteId: siteId,
    );
  }

  /// Exécute l'opération de remplissage interne (vides -> pleines).
  Future<void> fillCylinders({
    required String enterpriseId,
    required String userId,
    required Map<int, int> quantities,
    String? notes,
  }) async {
    await _transactionService.executeFillingTransaction(
      enterpriseId: enterpriseId,
      userId: userId,
      quantities: quantities,
      notes: notes,
    );
  }
}
