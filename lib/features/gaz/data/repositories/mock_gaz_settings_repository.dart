import '../../domain/entities/gaz_settings.dart';
import '../../domain/repositories/gaz_settings_repository.dart';

/// Implémentation mock du repository des paramètres Gaz.
class MockGazSettingsRepository implements GazSettingsRepository {
  final Map<String, GazSettings> _settings = {};

  String _getKey(String enterpriseId, String moduleId) {
    return '$enterpriseId:$moduleId';
  }

  @override
  Future<GazSettings?> getSettings({
    required String enterpriseId,
    required String moduleId,
  }) async {
    final key = _getKey(enterpriseId, moduleId);
    return _settings[key];
  }

  @override
  Future<void> saveSettings(GazSettings settings) async {
    final key = _getKey(settings.enterpriseId, settings.moduleId);
    _settings[key] = settings;
  }

  @override
  Future<void> deleteSettings({
    required String enterpriseId,
    required String moduleId,
  }) async {
    final key = _getKey(enterpriseId, moduleId);
    _settings.remove(key);
  }
}
