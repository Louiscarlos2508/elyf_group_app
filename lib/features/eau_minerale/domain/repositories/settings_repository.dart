import '../entities/eau_minerale_settings.dart';

abstract class EauMineraleSettingsRepository {
  /// Fetches the settings for the module.
  Future<EauMineraleSettings?> getSettings();

  /// Watches settings changes.
  Stream<EauMineraleSettings?> watchSettings();

  /// Updates or creates the settings.
  Future<void> saveSettings(EauMineraleSettings settings);
}
