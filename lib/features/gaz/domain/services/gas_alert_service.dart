import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../entities/cylinder.dart';
import '../entities/cylinder_stock.dart';
import '../entities/gaz_settings.dart';
import '../entities/stock_alert.dart';
import '../repositories/gaz_settings_repository.dart';
import '../repositories/cylinder_stock_repository.dart';

/// Service responsable de surveiller les niveaux de stock et de déclencher des alertes.
class GasAlertService {
  const GasAlertService({
    required this.settingsRepository,
    required this.stockRepository,
  });

  final GazSettingsRepository settingsRepository;
  final CylinderStockRepository stockRepository;

  /// Vérifie si le stock d'un cylindre est passé sous le seuil d'alerte.
  /// 
  /// Retourne un [StockAlert] si le seuil est franchi, sinon null.
  Future<StockAlert?> checkStockLevel({
    required String enterpriseId,
    required String? cylinderId,
    required int weight,
    required CylinderStatus status,
  }) async {
    // 1. Récupérer les paramètres pour obtenir le seuil
    final settings = await settingsRepository.getSettings(
      enterpriseId: enterpriseId,
      moduleId: 'gaz',
    );

    if (settings == null) return null;

    final threshold = settings.getLowStockThreshold(weight);
    if (threshold <= 0) return null; // Pas de seuil configuré

    // 2. Récupérer le stock actuel (Total par poids si cylinderId est nul ou vide)
    final stocks = await stockRepository.getStocksByWeight(enterpriseId, weight);
    final currentStock = stocks
        .where((s) => 
            s.status == status && 
            (cylinderId == null || cylinderId.isEmpty || s.cylinderId == cylinderId))
        .fold<int>(0, (sum, s) => sum + s.quantity);

    // 3. Comparer et créer l'alerte si nécessaire
    if (currentStock < threshold) {
      return StockAlert(
        cylinderId: cylinderId ?? '',
        weight: weight,
        currentStock: currentStock,
        threshold: threshold,
        timestamp: DateTime.now(),
        isFullStock: status == CylinderStatus.full,
      );
    }

    return null;
  }

  /// Affiche une notification d'alerte si nécessaire.
  void notifyIfLowStock(BuildContext context, StockAlert? alert) {
    if (alert != null) {
      NotificationService.showWarning(context, alert.message);
    }
  }

  /// Vérifie les alertes de stock (signature attendue par TransactionService si besoin)
  Future<StockAlert?> checkStockAlerts({
    required String enterpriseId,
    required String? cylinderId,
    required int weight,
    required CylinderStatus status,
  }) {
    return checkStockLevel(
      enterpriseId: enterpriseId,
      cylinderId: cylinderId,
      weight: weight,
      status: status,
    );
  }
}
