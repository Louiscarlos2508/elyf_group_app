import '../../domain/entities/gaz_settings.dart';
import '../../domain/repositories/gaz_settings_repository.dart';

/// Contrôleur pour gérer les paramètres du module Gaz.
class GazSettingsController {
  const GazSettingsController({required this.repository});

  final GazSettingsRepository repository;

  /// Récupère les paramètres pour une entreprise et un module.
  Future<GazSettings?> getSettings({
    required String enterpriseId,
    required String moduleId,
  }) async {
    return await repository.getSettings(
      enterpriseId: enterpriseId,
      moduleId: moduleId,
    );
  }

  /// Observe les paramètres en temps réel.
  Stream<GazSettings?> watchSettings({
    required String enterpriseId,
    required String moduleId,
  }) {
    return repository.watchSettings(
      enterpriseId: enterpriseId,
      moduleId: moduleId,
    );
  }

  /// Crée ou met à jour les paramètres.
  Future<void> saveSettings(GazSettings settings) async {
    await repository.saveSettings(settings);
  }
  
  /// Définit le prix détail pour un poids donné.
  Future<void> setRetailPrice({
    required String enterpriseId,
    required String moduleId,
    required int weight,
    required double price,
  }) async {
    final existing = await repository.getSettings(
      enterpriseId: enterpriseId,
      moduleId: moduleId,
    );

    final updated = existing != null
        ? existing.setRetailPrice(weight, price)
        : GazSettings(
            enterpriseId: enterpriseId,
            moduleId: moduleId,
          ).setRetailPrice(weight, price);

    await repository.saveSettings(updated);
  }

  /// Définit le prix d'achat pour un poids donné.
  Future<void> setPurchasePrice({
    required String enterpriseId,
    required String moduleId,
    required int weight,
    required double price,
  }) async {
    final existing = await repository.getSettings(
      enterpriseId: enterpriseId,
      moduleId: moduleId,
    );

    final updated = existing != null
        ? existing.setPurchasePrice(weight, price)
        : GazSettings(
            enterpriseId: enterpriseId,
            moduleId: moduleId,
          ).setPurchasePrice(weight, price);

    await repository.saveSettings(updated);
  }

  /// Définit le prix en gros pour un poids donné.
  Future<void> setWholesalePrice({
    required String enterpriseId,
    required String moduleId,
    required int weight,
    required double price,
  }) async {
    final existing = await repository.getSettings(
      enterpriseId: enterpriseId,
      moduleId: moduleId,
    );

    final updated = existing != null
        ? existing.setWholesalePrice(weight, price)
        : GazSettings(
            enterpriseId: enterpriseId,
            moduleId: moduleId,
          ).setWholesalePrice(weight, price);

    await repository.saveSettings(updated);
  }

  /// Supprime le prix en gros pour un poids donné.
  Future<void> removeWholesalePrice({
    required String enterpriseId,
    required String moduleId,
    required int weight,
  }) async {
    final existing = await repository.getSettings(
      enterpriseId: enterpriseId,
      moduleId: moduleId,
    );

    if (existing != null) {
      final updated = Map<int, double>.from(existing.wholesalePrices);
      updated.remove(weight);
      await repository.saveSettings(existing.copyWith(
        wholesalePrices: updated,
        updatedAt: DateTime.now(),
      ));
    }
  }

  /// Récupère le prix en gros pour un poids donné.
  Future<double?> getWholesalePrice({
    required String enterpriseId,
    required String moduleId,
    required int weight,
  }) async {
    final settings = await repository.getSettings(
      enterpriseId: enterpriseId,
      moduleId: moduleId,
    );
    return settings?.getWholesalePrice(weight);
  }

  /// Définit le seuil d'alerte pour un poids donné.
  Future<void> setLowStockThreshold({
    required String enterpriseId,
    required String moduleId,
    required int weight,
    required int threshold,
  }) async {
    final existing = await repository.getSettings(
      enterpriseId: enterpriseId,
      moduleId: moduleId,
    );

    final updated = existing != null
        ? existing.setLowStockThreshold(weight, threshold)
        : GazSettings(
            enterpriseId: enterpriseId,
            moduleId: moduleId,
          ).setLowStockThreshold(weight, threshold);

    await repository.saveSettings(updated);
  }

  /// Définit le taux de consigne pour un poids donné.
  Future<void> setDepositRate({
    required String enterpriseId,
    required String moduleId,
    required int weight,
    required double rate,
  }) async {
    final existing = await repository.getSettings(
      enterpriseId: enterpriseId,
      moduleId: moduleId,
    );

    final updated = existing != null
        ? existing.setDepositRate(weight, rate)
        : GazSettings(
            enterpriseId: enterpriseId,
            moduleId: moduleId,
          ).setDepositRate(weight, rate);

    await repository.saveSettings(updated);
  }

  /// Définit le stock nominal pour un poids donné.
  Future<void> setNominalStock({
    required String enterpriseId,
    required String moduleId,
    required int weight,
    required int quantity,
  }) async {
    final existing = await repository.getSettings(
      enterpriseId: enterpriseId,
      moduleId: moduleId,
    );

    final updated = existing != null
        ? existing.setNominalStock(weight, quantity)
        : GazSettings(
            enterpriseId: enterpriseId,
            moduleId: moduleId,
          ).setNominalStock(weight, quantity);

    await repository.saveSettings(updated);
  }

  /// Définit le frais de chargement par défaut.
  Future<void> setLoadingFee({
    required String enterpriseId,
    required String moduleId,
    required int weight,
    required double fee,
  }) async {
    final existing = await repository.getSettings(
      enterpriseId: enterpriseId,
      moduleId: moduleId,
    );

    final updated = existing != null
        ? existing.setLoadingFee(weight, fee)
        : GazSettings(
            enterpriseId: enterpriseId,
            moduleId: moduleId,
          ).setLoadingFee(weight, fee);

    await repository.saveSettings(updated);
  }

  /// Définit le frais de déchargement par défaut.
  Future<void> setUnloadingFee({
    required String enterpriseId,
    required String moduleId,
    required int weight,
    required double fee,
  }) async {
    final existing = await repository.getSettings(
      enterpriseId: enterpriseId,
      moduleId: moduleId,
    );

    final updated = existing != null
        ? existing.setUnloadingFee(weight, fee)
        : GazSettings(
            enterpriseId: enterpriseId,
            moduleId: moduleId,
          ).setUnloadingFee(weight, fee);

    await repository.saveSettings(updated);
  }

  /// Active/Désactive l'impression automatique des reçus.
  Future<void> setAutoPrintReceipt({
    required String enterpriseId,
    required String moduleId,
    required bool enabled,
  }) async {
    final existing = await repository.getSettings(
      enterpriseId: enterpriseId,
      moduleId: moduleId,
    );

    final updated = existing != null
        ? existing.copyWith(autoPrintReceipt: enabled, updatedAt: DateTime.now())
        : GazSettings(
            enterpriseId: enterpriseId,
            moduleId: moduleId,
            autoPrintReceipt: enabled,
          );

    await repository.saveSettings(updated);
  }
}
