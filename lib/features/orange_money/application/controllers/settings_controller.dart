import '../../domain/entities/orange_money_settings.dart';
import '../../domain/repositories/settings_repository.dart';

/// Controller for managing Orange Money settings.
class SettingsController {
  SettingsController(this._repository, this.userId);

  final SettingsRepository _repository;
  final String userId;

  Future<OrangeMoneySettings?> getSettings(String enterpriseId) async {
    return await _repository.getSettings(enterpriseId);
  }

  Stream<OrangeMoneySettings?> watchSettings(String enterpriseId) {
    return _repository.watchSettings(enterpriseId);
  }

  Future<void> saveSettings(OrangeMoneySettings settings) async {
    return await _repository.saveSettings(settings);
  }

  /// Met à jour les notifications
  Future<void> updateNotifications(
    String enterpriseId, {
    bool? enableCommissionReminders,
    bool? enableCheckpointReminders,
  }) async {
    return await _repository.updateNotifications(
      enterpriseId,
      enableCommissionReminders: enableCommissionReminders,
      enableCheckpointReminders: enableCheckpointReminders,
    );
  }

}
