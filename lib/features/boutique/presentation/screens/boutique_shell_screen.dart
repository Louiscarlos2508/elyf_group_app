import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'sections/catalog_screen.dart';
import 'sections/dashboard_screen.dart';
import 'sections/expenses_screen.dart';
import 'sections/pos_screen.dart';
import 'sections/reports_screen.dart';

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
  List<NavigationSection> buildSections() {
    // TODO: Adapter les écrans de sections pour accepter enterpriseId et moduleId
    // Pour l'instant, on passe les paramètres au widget mais les sections
    // devront être adaptées individuellement pour les utiliser
    return [
      NavigationSection(
        label: 'Tableau',
        icon: Icons.dashboard_outlined,
        builder: () => const DashboardScreen(),
        isPrimary: true,
        enterpriseId: widget.enterpriseId,
        moduleId: widget.moduleId,
      ),
      NavigationSection(
        label: 'Caisse',
        icon: Icons.point_of_sale,
        builder: () => const PosScreen(),
        isPrimary: true,
        enterpriseId: widget.enterpriseId,
        moduleId: widget.moduleId,
      ),
      NavigationSection(
        label: 'Produits',
        icon: Icons.inventory_2_outlined,
        builder: () => const CatalogScreen(),
        isPrimary: true,
        enterpriseId: widget.enterpriseId,
        moduleId: widget.moduleId,
      ),
      NavigationSection(
        label: 'Dépenses',
        icon: Icons.receipt_long_outlined,
        builder: () => const ExpensesScreen(),
        enterpriseId: widget.enterpriseId,
        moduleId: widget.moduleId,
      ),
      NavigationSection(
        label: 'Rapports',
        icon: Icons.assessment,
        builder: () => const ReportsScreen(),
        enterpriseId: widget.enterpriseId,
        moduleId: widget.moduleId,
      ),
      NavigationSection(
        label: 'Profil',
        icon: Icons.person_outline,
        builder: () => const ProfileScreen(),
        enterpriseId: widget.enterpriseId,
        moduleId: widget.moduleId,
      ),
    ];
  }
}

