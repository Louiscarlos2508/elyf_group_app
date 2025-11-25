import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/presentation/widgets/profile/profile_screen.dart' as shared;
import '../../application/providers.dart';
import 'sections/catalog_screen.dart';
import 'sections/dashboard_screen.dart';
import 'sections/expenses_screen.dart';
import 'sections/pos_screen.dart';
import 'sections/purchases_screen.dart';
import 'sections/reports_screen.dart';
import 'sections/sales_history_screen.dart';
import 'sections/stock_screen.dart';

class BoutiqueShellScreen extends ConsumerStatefulWidget {
  const BoutiqueShellScreen({super.key});

  @override
  ConsumerState<BoutiqueShellScreen> createState() =>
      _BoutiqueShellScreenState();
}

class _BoutiqueShellScreenState extends ConsumerState<BoutiqueShellScreen> {
  int _selectedIndex = 0;

  final _sections = [
    _SectionConfig(
      label: 'Tableau',
      icon: Icons.dashboard_outlined,
      builder: () => const DashboardScreen(),
    ),
    _SectionConfig(
      label: 'Point de Vente',
      icon: Icons.point_of_sale,
      builder: () => const PosScreen(),
    ),
    _SectionConfig(
      label: 'Catalogue',
      icon: Icons.inventory_2_outlined,
      builder: () => const CatalogScreen(),
    ),
    _SectionConfig(
      label: 'Stock',
      icon: Icons.warehouse_outlined,
      builder: () => const StockScreen(),
    ),
    _SectionConfig(
      label: 'Ventes',
      icon: Icons.receipt_long,
      builder: () => const SalesHistoryScreen(),
    ),
    _SectionConfig(
      label: 'Achats',
      icon: Icons.shopping_bag,
      builder: () => const PurchasesScreen(),
    ),
    _SectionConfig(
      label: 'Dépenses',
      icon: Icons.receipt_long_outlined,
      builder: () => const ExpensesScreen(),
    ),
    _SectionConfig(
      label: 'Rapports',
      icon: Icons.assessment,
      builder: () => const ReportsScreen(),
    ),
    _SectionConfig(
      label: 'Profil',
      icon: Icons.person_outline,
      builder: () => const shared.ProfileScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    
    if (isWideScreen) {
      // Utiliser NavigationRail pour les écrans larges
      return Scaffold(
        appBar: AppBar(
          title: const Text('Boutique • Vente physique'),
          centerTitle: true,
        ),
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              labelType: NavigationRailLabelType.all,
              destinations: _sections
                  .map(
                    (s) => NavigationRailDestination(
                      icon: Icon(s.icon),
                      selectedIcon: Icon(s.icon),
                      label: Text(s.label),
                    ),
                  )
                  .toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: _sections.map((s) => s.builder()).toList(),
              ),
            ),
          ],
        ),
      );
    }
    
    // Utiliser NavigationBar pour les petits écrans
    return Scaffold(
      appBar: AppBar(
        title: const Text('Boutique • Vente physique'),
        centerTitle: true,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _sections.map((s) => s.builder()).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: _sections
            .map(
              (s) => NavigationDestination(
                icon: Icon(s.icon),
                selectedIcon: Icon(s.icon),
                label: s.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SectionConfig {
  const _SectionConfig({
    required this.label,
    required this.icon,
    required this.builder,
  });

  final String label;
  final IconData icon;
  final Widget Function() builder;
}

