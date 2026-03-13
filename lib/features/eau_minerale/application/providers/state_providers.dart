/// Barrel file for state providers in the eau_minerale module.
///
/// This file exports all thematic state providers that were previously
/// in this single monolithic file.
library;

// Thematic State Providers
import 'package:flutter_riverpod/flutter_riverpod.dart';
export 'credit_state_providers.dart';
export 'dashboard_state_providers.dart';
export 'production_state_providers.dart';
export 'stock_state_providers.dart';
export 'treasury_state_providers.dart';
export 'legacy_state_providers.dart';
export 'navigation_state_providers.dart';

import '../../domain/entities/eau_minerale_settings.dart';
import '../../domain/entities/electricity_meter_type.dart';
import 'repository_providers.dart';
import 'service_providers.dart';

// Legacy providers kept here to avoid breaking changes if they don't fit perfectly elsewhere,
// or for backward compatibility if they are widely used from this file natively.

/// Provider pour observer les réglages du module.
final eauMineraleSettingsProvider = StreamProvider<EauMineraleSettings>((ref) {
  return ref.watch(eauMineraleSettingsRepositoryProvider).watchSettings().map(
        (settings) => settings ?? EauMineraleSettings.defaultSettings('default'),
      );
});

/// Provider pour récupérer le type de compteur configuré
final electricityMeterTypeProvider =
    FutureProvider.autoDispose<ElectricityMeterType>(
  (ref) async =>
      ref.watch(electricityMeterConfigServiceProvider).getMeterType(),
);

/// Provider pour récupérer le taux d'électricité (CFA/kWh) configuré
final electricityRateProvider = FutureProvider.autoDispose<double>(
  (ref) async =>
      ref.watch(electricityMeterConfigServiceProvider).getElectricityRate(),
);
