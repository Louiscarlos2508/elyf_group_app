import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/presentation/widgets/adaptive_navigation_scaffold.dart';
import '../../../../shared/presentation/widgets/module_loading_animation.dart';
import '../../../../shared/presentation/widgets/profile/profile_screen.dart' as shared;
import '../../../../shared/presentation/widgets/treasury/treasury_screen.dart' as shared_treasury;
import 'sections/catalog_screen.dart';
import 'sections/dashboard_screen.dart';
import 'sections/expenses_screen.dart';
import 'sections/pos_screen.dart';
import 'sections/purchases_screen.dart';
import 'sections/reports_screen.dart';
import 'sections/sales_history_screen.dart';
import 'sections/stock_screen.dart';

class BoutiqueShellScreen extends ConsumerStatefulWidget {
  const BoutiqueShellScreen({
    super.key,
    required this.enterpriseId,
    required this.moduleId,
  });

  final String enterpriseId;
  final String moduleId;

  @override
  ConsumerState<BoutiqueShellScreen> createState() =>
      _BoutiqueShellScreenState();
}

class _BoutiqueShellScreenState extends ConsumerState<BoutiqueShellScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Simulate module initialization
    Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  List<NavigationSection> _buildSections() {
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
        label: 'Point de Vente',
        icon: Icons.point_of_sale,
        builder: () => const PosScreen(),
        isPrimary: true,
        enterpriseId: widget.enterpriseId,
        moduleId: widget.moduleId,
      ),
      NavigationSection(
        label: 'Catalogue',
        icon: Icons.inventory_2_outlined,
        builder: () => const CatalogScreen(),
        isPrimary: true,
        enterpriseId: widget.enterpriseId,
        moduleId: widget.moduleId,
      ),
      NavigationSection(
        label: 'Stock',
        icon: Icons.warehouse_outlined,
        builder: () => const StockScreen(),
        isPrimary: true,
        enterpriseId: widget.enterpriseId,
        moduleId: widget.moduleId,
      ),
      NavigationSection(
        label: 'Ventes',
        icon: Icons.receipt_long,
        builder: () => const SalesHistoryScreen(),
        isPrimary: true,
        enterpriseId: widget.enterpriseId,
        moduleId: widget.moduleId,
      ),
      NavigationSection(
        label: 'Achats',
        icon: Icons.shopping_bag,
        builder: () => const PurchasesScreen(),
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
        label: 'Trésorerie',
        icon: Icons.account_balance,
        builder: () => shared_treasury.TreasuryScreen(
          moduleId: widget.moduleId,
          moduleName: 'Boutique',
        ),
        isPrimary: true,
        enterpriseId: widget.enterpriseId,
        moduleId: widget.moduleId,
      ),
      NavigationSection(
        label: 'Profil',
        icon: Icons.person_outline,
        builder: () => const shared.ProfileScreen(),
        enterpriseId: widget.enterpriseId,
        moduleId: widget.moduleId,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveNavigationScaffold(
      sections: _buildSections(),
      appTitle: 'Boutique • Vente physique',
      selectedIndex: _selectedIndex,
      onIndexChanged: (index) {
        setState(() => _selectedIndex = index);
      },
      isLoading: _isLoading,
      loadingWidget: const ModuleLoadingAnimation(
        moduleName: 'Boutique',
        moduleIcon: Icons.store,
        message: 'Chargement du catalogue...',
      ),
      enterpriseId: widget.enterpriseId,
      moduleId: widget.moduleId,
    );
  }
}

