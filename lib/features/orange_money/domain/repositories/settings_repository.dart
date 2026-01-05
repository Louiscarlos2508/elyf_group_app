import '../entities/settings.dart';

/// Repository for managing Orange Money settings.
abstract class SettingsRepository {
  Future<OrangeMoneySettings?> getSettings(String enterpriseId);

  Future<void> saveSettings(OrangeMoneySettings settings);

  Future<void> updateNotifications(
    String enterpriseId,
    NotificationSettings notifications,
  );

  Future<void> updateThresholds(
    String enterpriseId,
    ThresholdSettings thresholds,
  );

  Future<void> updateSimNumber(String enterpriseId, String simNumber);
}

