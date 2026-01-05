import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/presentation/widgets/adaptive_navigation_scaffold.dart';
import '../../../../shared/presentation/widgets/base_module_shell_screen.dart';
import 'sections/approvisionnement_screen.dart';
import 'sections/cylinder_leak_screen.dart';
import 'sections/dashboard_screen.dart';
import 'sections/expenses_screen.dart';
import 'sections/profile_screen.dart';
import 'sections/reports_screen.dart';
import 'sections/retail_screen.dart';
import 'sections/settings_screen.dart';
import 'sections/stock_screen.dart';
import 'sections/wholesale_screen.dart';

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
  List<NavigationSection> buildSections() {
    return [
      NavigationSection(
        label: 'Tableau',
        icon: Icons.dashboard_outlined,
        builder: () => const GazDashboardScreen(),
        isPrimary: true,
        enterpriseId: widget.enterpriseId,
        moduleId: widget.moduleId,
      ),
      NavigationSection(
        label: 'Détail',
        icon: Icons.store_outlined,
        builder: () => const GazRetailScreen(),
        isPrimary: true,
        enterpriseId: widget.enterpriseId,
        moduleId: widget.moduleId,
      ),
      NavigationSection(
        label: 'En gros',
        icon: Icons.local_shipping_outlined,
        builder: () => const GazWholesaleScreen(),
        isPrimary: true,
        enterpriseId: widget.enterpriseId,
        moduleId: widget.moduleId,
      ),
      NavigationSection(
        label: 'Stock',
        icon: Icons.inventory_2_outlined,
        builder: () => const GazStockScreen(),
        isPrimary: true,
        enterpriseId: widget.enterpriseId,
        moduleId: widget.moduleId,
      ),
      NavigationSection(
        label: 'Appro',
        icon: Icons.inventory_outlined,
        builder: () => const ApprovisionnementScreen(),
        isPrimary: true,
        enterpriseId: widget.enterpriseId,
        moduleId: widget.moduleId,
      ),
      NavigationSection(
        label: 'Fuites',
        icon: Icons.warning_outlined,
        builder: () => CylinderLeakScreen(
          enterpriseId: widget.enterpriseId,
          moduleId: widget.moduleId,
        ),
        enterpriseId: widget.enterpriseId,
        moduleId: widget.moduleId,
      ),
      NavigationSection(
        label: 'Dépenses',
        icon: Icons.receipt_long_outlined,
        builder: () => const GazExpensesScreen(),
        enterpriseId: widget.enterpriseId,
        moduleId: widget.moduleId,
      ),
      NavigationSection(
        label: 'Rapports',
        icon: Icons.description_outlined,
        builder: () => const GazReportsScreen(),
        enterpriseId: widget.enterpriseId,
        moduleId: widget.moduleId,
      ),
      NavigationSection(
        label: 'Paramètres',
        icon: Icons.settings_outlined,
        builder: () => const GazSettingsScreen(),
        enterpriseId: widget.enterpriseId,
        moduleId: widget.moduleId,
      ),
      NavigationSection(
        label: 'Profil',
        icon: Icons.person_outline,
        builder: () => const GazProfileScreen(),
        enterpriseId: widget.enterpriseId,
        moduleId: widget.moduleId,
      ),
    ];
  }
}
