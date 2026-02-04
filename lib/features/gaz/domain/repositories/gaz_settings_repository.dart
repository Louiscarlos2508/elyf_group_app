import '../entities/gaz_settings.dart';

/// Repository pour gérer les paramètres du module Gaz.
abstract class GazSettingsRepository {
  /// Récupère les paramètres pour une entreprise et un module.
  Future<GazSettings?> getSettings({
    required String enterpriseId,
    required String moduleId,
  });

  Stream<GazSettings?> watchSettings({
    required String enterpriseId,
    required String moduleId,
  });

  /// Sauvegarde les paramètres.
  Future<void> saveSettings(GazSettings settings);

  /// Supprime les paramètres.
  Future<void> deleteSettings({
    required String enterpriseId,
    required String moduleId,
  });
}
