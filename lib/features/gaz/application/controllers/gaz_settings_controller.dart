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
      final updated = existing.removeWholesalePrice(weight);
      await repository.saveSettings(updated);
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
}
