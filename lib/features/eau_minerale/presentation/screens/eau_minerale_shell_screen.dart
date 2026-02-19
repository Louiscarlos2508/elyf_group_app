import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';

class EauMineraleShellScreen extends BaseModuleShellScreen {
  const EauMineraleShellScreen({
    super.key,
    required super.enterpriseId,
    required super.moduleId,
  });

  @override
  BaseModuleShellScreenState<EauMineraleShellScreen> createState() =>
      _EauMineraleShellScreenState();
}

class _EauMineraleShellScreenState
    extends BaseModuleShellScreenState<EauMineraleShellScreen> {
  @override
  String get moduleName => 'Eau Minérale';

  @override
  IconData get moduleIcon => Icons.water_drop_outlined;

  @override
  String get appTitle => 'Eau Minérale • Module';

  @override
  AsyncValue<List<NavigationSection>>? getSectionsAsync() {
    return ref.watch(navigationSectionsProvider((
      enterpriseId: widget.enterpriseId,
      moduleId: widget.moduleId,
    )));
  }

  @override
  List<NavigationSection> buildSections() {
    return [];
  }
}
