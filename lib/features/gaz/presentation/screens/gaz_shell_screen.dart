import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/presentation/widgets/adaptive_navigation_scaffold.dart';
import '../../../../shared/presentation/widgets/profile/profile_screen.dart' as shared;
import '../../../../shared/presentation/widgets/treasury/treasury_screen.dart' as shared_treasury;
import 'sections/dashboard_screen.dart';
import 'sections/retail_screen.dart';
import 'sections/wholesale_screen.dart';
import 'sections/stock_screen.dart';
import 'sections/depots_screen.dart';
import 'sections/reports_screen.dart';

class GazShellScreen extends ConsumerStatefulWidget {
  const GazShellScreen({
    super.key,
    required this.enterpriseId,
    required this.moduleId,
  });

  final String enterpriseId;
  final String moduleId;

  @override
  ConsumerState<GazShellScreen> createState() => _GazShellScreenState();
}

class _GazShellScreenState extends ConsumerState<GazShellScreen> {
  int _index = 0;

  List<NavigationSection> _buildSections() {
    return [
      NavigationSection(
        label: 'Tableau',
        icon: Icons.dashboard_outlined,
        builder: () => const DashboardScreen(),
        isPrimary: true,
      ),
      NavigationSection(
        label: 'Vente Détail',
        icon: Icons.shopping_cart,
        builder: () => const RetailScreen(),
        isPrimary: true,
      ),
      NavigationSection(
        label: 'Vente Gros',
        icon: Icons.local_shipping,
        builder: () => const WholesaleScreen(),
        isPrimary: true,
      ),
      NavigationSection(
        label: 'Stock',
        icon: Icons.inventory_2_outlined,
        builder: () => const StockScreen(),
        isPrimary: true,
      ),
      NavigationSection(
        label: 'Dépôts',
        icon: Icons.warehouse,
        builder: () => const DepotsScreen(),
        isPrimary: false,
      ),
      NavigationSection(
        label: 'Rapports',
        icon: Icons.description,
        builder: () => const ReportsScreen(),
        isPrimary: false,
      ),
      NavigationSection(
        label: 'Trésorerie',
        icon: Icons.account_balance,
        builder: () => shared_treasury.TreasuryScreen(
          moduleId: widget.moduleId,
          moduleName: 'Gaz',
        ),
        isPrimary: true,
      ),
      NavigationSection(
        label: 'Profil',
        icon: Icons.person_outline,
        builder: () => const shared.ProfileScreen(),
        isPrimary: false,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveNavigationScaffold(
      appTitle: 'Gaz',
      sections: _buildSections(),
      selectedIndex: _index,
      onIndexChanged: (index) => setState(() => _index = index),
      enterpriseId: widget.enterpriseId,
      moduleId: widget.moduleId,
    );
  }
}

