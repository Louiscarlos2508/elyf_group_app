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

  Future<void> updateNotifications(
    String enterpriseId, {
    bool? enableLiquidityAlerts,
    bool? enableCommissionReminders,
    bool? enableCheckpointReminders,
    bool? enableTransactionAlerts,
  }) async {
    return await _repository.updateNotifications(
      enterpriseId,
      enableLiquidityAlerts: enableLiquidityAlerts,
      enableCommissionReminders: enableCommissionReminders,
      enableCheckpointReminders: enableCheckpointReminders,
      enableTransactionAlerts: enableTransactionAlerts,
    );
  }

  Future<void> updateThresholds(
    String enterpriseId, {
    int? criticalLiquidityThreshold,
    double? checkpointDiscrepancyThreshold,
    int? commissionReminderDays,
    int? largeTransactionThreshold,
  }) async {
    return await _repository.updateThresholds(
      enterpriseId,
      criticalLiquidityThreshold: criticalLiquidityThreshold,
      checkpointDiscrepancyThreshold: checkpointDiscrepancyThreshold,
      commissionReminderDays: commissionReminderDays,
      largeTransactionThreshold: largeTransactionThreshold,
    );
  }

  Future<void> updateSimNumber(String enterpriseId, String simNumber) async {
    return await _repository.updateSimNumber(enterpriseId, simNumber);
  }
}
