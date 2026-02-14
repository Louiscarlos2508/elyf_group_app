import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/boutique/application/providers.dart';
import '../../../../core/printing/printer_provider.dart';

class BoutiqueShellScreen extends BaseModuleShellScreen {
  const BoutiqueShellScreen({
    super.key,
    required super.enterpriseId,
    required super.moduleId,
  });

  @override
  BaseModuleShellScreenState<BoutiqueShellScreen> createState() =>
      _BoutiqueShellScreenState();
}

class _BoutiqueShellScreenState
    extends BaseModuleShellScreenState<BoutiqueShellScreen> {
  @override
  String get moduleName => 'Boutique';

  @override
  IconData get moduleIcon => Icons.store;

  @override
  String get appTitle => 'Boutique • Vente physique';

  @override
  Widget buildLoading() {
    return const ModuleLoadingAnimation(
      moduleName: 'Boutique',
      moduleIcon: Icons.store,
      message: 'Chargement du catalogue...',
    );
  }

  @override
  AsyncValue<List<NavigationSection>>? getSectionsAsync() {
    // Retourner le provider async pour les sections filtrées par permissions
    return ref.watch(accessibleBoutiqueSectionsProvider);
  }

  @override
  List<NavigationSection> buildSections() {
    // Cette méthode doit être implémentée mais n'est pas utilisée
    // car getSectionsAsync retourne une valeur non-nulle.
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        printerConfigProvider.overrideWith(
          (ref) => ref.watch(boutiquePrinterConfigProvider),
        ),
      ],
      child: super.build(context),
    );
  }
}
