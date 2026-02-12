import '../entities/orange_money_settings.dart';

/// Repository for managing Orange Money settings per enterprise.
abstract class SettingsRepository {
  /// Récupère les paramètres pour une entreprise
  Future<OrangeMoneySettings?> getSettings(String enterpriseId);

  /// Crée ou met à jour les paramètres
  Future<void> saveSettings(OrangeMoneySettings settings);

  /// Crée les paramètres par défaut pour une nouvelle entreprise
  Future<OrangeMoneySettings> createDefaultSettings(String enterpriseId);

  /// Met à jour les notifications
  Future<void> updateNotifications(
    String enterpriseId, {
    bool? enableLiquidityAlerts,
    bool? enableCommissionReminders,
    bool? enableCheckpointReminders,
    bool? enableTransactionAlerts,
  });

  /// Met à jour les seuils
  Future<void> updateThresholds(
    String enterpriseId, {
    int? criticalLiquidityThreshold,
    double? checkpointDiscrepancyThreshold,
    int? commissionReminderDays,
    int? largeTransactionThreshold,
  });

  /// Met à jour les barèmes de commission
  Future<void> updateCommissionTiers(
    String enterpriseId, {
    List<CommissionTier>? cashInTiers,
    List<CommissionTier>? cashOutTiers,
  });

  /// Met à jour les paramètres de validation des commissions
  Future<void> updateCommissionValidation(
    String enterpriseId, {
    double? commissionDiscrepancyMinor,
    double? commissionDiscrepancySignificant,
    bool? autoValidateConformeCommissions,
  });

  /// Met à jour le numéro SIM
  Future<void> updateSimNumber(String enterpriseId, String simNumber);

  /// Écoute les changements de paramètres
  Stream<OrangeMoneySettings?> watchSettings(String enterpriseId);
}
