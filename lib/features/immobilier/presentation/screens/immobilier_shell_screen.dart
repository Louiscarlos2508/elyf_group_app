import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart'
    show
        BaseModuleShellScreen,
        BaseModuleShellScreenState,
        NavigationSection,
        ModuleLoadingAnimation;
import 'package:elyf_groupe_app/features/immobilier/application/providers.dart';

class ImmobilierShellScreen extends BaseModuleShellScreen {
  const ImmobilierShellScreen({
    super.key,
    required super.enterpriseId,
    required super.moduleId,
  });

  @override
  BaseModuleShellScreenState<ImmobilierShellScreen> createState() =>
      _ImmobilierShellScreenState();
}

class _ImmobilierShellScreenState
    extends BaseModuleShellScreenState<ImmobilierShellScreen> {
  @override
  String get moduleName => 'Immobilier';

  @override
  IconData get moduleIcon => Icons.home_work_outlined;

  @override
  String get appTitle => 'Immobilier • Maisons';

  @override
  Widget buildLoading() {
    return ModuleLoadingAnimation(
      moduleName: 'Immobilier',
      moduleIcon: Icons.home_work_outlined,
      message: 'Chargement des données...',
    );
  }

  @override
  AsyncValue<List<NavigationSection>>? getSectionsAsync() {
    // Retourner le provider async pour les sections filtrées par permissions
    return ref.watch(accessibleImmobilierSectionsProvider);
  }

  @override
  List<NavigationSection> buildSections() {
    // Cette méthode n'est plus utilisée car on utilise getSectionsAsync()
    return [];
  }
}
