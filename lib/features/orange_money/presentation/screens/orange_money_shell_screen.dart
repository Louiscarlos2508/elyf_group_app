import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart'
    show BaseModuleShellScreen, BaseModuleShellScreenState, NavigationSection;
import 'package:elyf_groupe_app/features/orange_money/application/providers.dart';

class OrangeMoneyShellScreen extends BaseModuleShellScreen {
  const OrangeMoneyShellScreen({
    super.key,
    required super.enterpriseId,
    required super.moduleId,
  });

  @override
  BaseModuleShellScreenState<OrangeMoneyShellScreen> createState() =>
      _OrangeMoneyShellScreenState();
}

class _OrangeMoneyShellScreenState
    extends BaseModuleShellScreenState<OrangeMoneyShellScreen> {
  @override
  String get moduleName => 'Orange Money';

  @override
  IconData get moduleIcon => Icons.account_balance_wallet_outlined;

  @override
  String get appTitle => 'Orange Money';

  @override
  AsyncValue<List<NavigationSection>>? getSectionsAsync() {
    // Retourner le provider async pour les sections filtrées par permissions
    return ref.watch(accessibleOrangeMoneySectionsProvider);
  }

  @override
  List<NavigationSection> buildSections() {
    // Cette méthode n'est plus utilisée car on utilise getSectionsAsync()
    return [];
  }
}
