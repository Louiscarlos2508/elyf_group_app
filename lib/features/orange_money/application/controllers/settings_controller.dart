import '../../domain/entities/settings.dart';
import '../../domain/repositories/settings_repository.dart';

/// Controller for managing Orange Money settings.
class SettingsController {
  SettingsController(this._repository);

  final SettingsRepository _repository;

  Future<OrangeMoneySettings?> getSettings(String enterpriseId) async {
    return await _repository.getSettings(enterpriseId);
  }

  Future<void> saveSettings(OrangeMoneySettings settings) async {
    return await _repository.saveSettings(settings);
  }

  Future<void> updateNotifications(
    String enterpriseId,
    NotificationSettings notifications,
  ) async {
    return await _repository.updateNotifications(enterpriseId, notifications);
  }

  Future<void> updateThresholds(
    String enterpriseId,
    ThresholdSettings thresholds,
  ) async {
    return await _repository.updateThresholds(enterpriseId, thresholds);
  }

  Future<void> updateSimNumber(String enterpriseId, String simNumber) async {
    return await _repository.updateSimNumber(enterpriseId, simNumber);
  }
}
