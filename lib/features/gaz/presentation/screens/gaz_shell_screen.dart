import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';

/// Écran principal du module Gaz avec navigation.
class GazShellScreen extends BaseModuleShellScreen {
  const GazShellScreen({
    super.key,
    required super.enterpriseId,
    required super.moduleId,
  });

  @override
  BaseModuleShellScreenState<GazShellScreen> createState() =>
      _GazShellScreenState();
}

class _GazShellScreenState
    extends BaseModuleShellScreenState<GazShellScreen> {
  @override
  String get moduleName => 'Gaz';

  @override
  IconData get moduleIcon => Icons.local_gas_station_outlined;

  @override
  String get appTitle => 'Gaz • Détail et gros';

  @override
  AsyncValue<List<NavigationSection>>? getSectionsAsync() {
    // Retourner le provider async pour les sections filtrées par permissions
    return ref.watch(accessibleGazSectionsProvider);
  }

  @override
  List<NavigationSection> buildSections() {
    // Cette méthode n'est plus utilisée car on utilise getSectionsAsync()
    return [];
  }
}
