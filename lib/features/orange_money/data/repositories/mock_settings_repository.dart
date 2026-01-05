import 'dart:async';

import '../../domain/entities/settings.dart';
import '../../domain/repositories/settings_repository.dart';

/// Mock implementation of SettingsRepository for development.
class MockSettingsRepository implements SettingsRepository {
  final _settings = <String, OrangeMoneySettings>{};

  MockSettingsRepository() {
    // Initialize with default settings
    _settings['orange_money_1'] = OrangeMoneySettings(
      enterpriseId: 'orange_money_1',
      notifications: const NotificationSettings(
        lowLiquidityAlert: true,
        monthlyCommissionReminder: true,
        paymentDueAlert: true,
      ),
      thresholds: const ThresholdSettings(
        criticalLiquidityThreshold: 50000,
        paymentDueDaysBefore: 3,
      ),
      simNumber: 'sim_123456789',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<OrangeMoneySettings?> getSettings(String enterpriseId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return _settings[enterpriseId];
  }

  @override
  Future<void> saveSettings(OrangeMoneySettings settings) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _settings[settings.enterpriseId] = settings;
  }

  @override
  Future<void> updateNotifications(
    String enterpriseId,
    NotificationSettings notifications,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final current = _settings[enterpriseId];
    if (current != null) {
      _settings[enterpriseId] = OrangeMoneySettings(
        enterpriseId: current.enterpriseId,
        notifications: notifications,
        thresholds: current.thresholds,
        simNumber: current.simNumber,
        createdAt: current.createdAt,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> updateThresholds(
    String enterpriseId,
    ThresholdSettings thresholds,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final current = _settings[enterpriseId];
    if (current != null) {
      _settings[enterpriseId] = OrangeMoneySettings(
        enterpriseId: current.enterpriseId,
        notifications: current.notifications,
        thresholds: thresholds,
        simNumber: current.simNumber,
        createdAt: current.createdAt,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> updateSimNumber(String enterpriseId, String simNumber) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final current = _settings[enterpriseId];
    if (current != null) {
      _settings[enterpriseId] = OrangeMoneySettings(
        enterpriseId: current.enterpriseId,
        notifications: current.notifications,
        thresholds: current.thresholds,
        simNumber: simNumber,
        createdAt: current.createdAt,
        updatedAt: DateTime.now(),
      );
    }
  }
}

