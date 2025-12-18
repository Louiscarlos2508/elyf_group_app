import 'package:flutter/material.dart';

import 'sections/dashboard_screen.dart';
import 'sections/depots_screen.dart';
import 'sections/expenses_screen.dart';
import 'sections/profile_screen.dart';
import 'sections/reports_screen.dart';
import 'sections/retail_screen.dart';
import 'sections/settings_screen.dart';
import 'sections/stock_screen.dart';
import 'sections/wholesale_screen.dart';

/// Écran principal du module Gaz avec navigation.
class GazShellScreen extends StatefulWidget {
  const GazShellScreen({
    super.key,
    required this.enterpriseId,
    required this.moduleId,
  });

  final String enterpriseId;
  final String moduleId;

  @override
  State<GazShellScreen> createState() => _GazShellScreenState();
}

class _GazShellScreenState extends State<GazShellScreen> {
  int _selectedIndex = 0;

  static const _destinations = [
    NavigationRailDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: Text('Tableau de bord'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.store_outlined),
      selectedIcon: Icon(Icons.store),
      label: Text('Détail'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.local_shipping_outlined),
      selectedIcon: Icon(Icons.local_shipping),
      label: Text('Gros'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.warehouse_outlined),
      selectedIcon: Icon(Icons.warehouse),
      label: Text('Dépôts'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.inventory_2_outlined),
      selectedIcon: Icon(Icons.inventory_2),
      label: Text('Stock'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.receipt_long_outlined),
      selectedIcon: Icon(Icons.receipt_long),
      label: Text('Dépenses'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.description_outlined),
      selectedIcon: Icon(Icons.description),
      label: Text('Rapports'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: Text('Paramètres'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: Text('Profil'),
    ),
  ];

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const GazDashboardScreen();
      case 1:
        return const GazRetailScreen();
      case 2:
        return const GazWholesaleScreen();
      case 3:
        return const DepotsScreen();
      case 4:
        return const GazStockScreen();
      case 5:
        return const GazExpensesScreen();
      case 6:
        return GazReportsScreen();
      case 7:
        return const GazSettingsScreen();
      case 8:
        return const GazProfileScreen();
      default:
        return const GazDashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gaz • Détail et gros'),
        centerTitle: true,
      ),
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              labelType: NavigationRailLabelType.all,
              destinations: _destinations,
            ),
          if (isWide) const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _buildBody()),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Accueil',
                ),
                NavigationDestination(
                  icon: Icon(Icons.store_outlined),
                  selectedIcon: Icon(Icons.store),
                  label: 'Détail',
                ),
                NavigationDestination(
                  icon: Icon(Icons.local_shipping_outlined),
                  selectedIcon: Icon(Icons.local_shipping),
                  label: 'Gros',
                ),
                NavigationDestination(
                  icon: Icon(Icons.warehouse_outlined),
                  selectedIcon: Icon(Icons.warehouse),
                  label: 'Dépôts',
                ),
                NavigationDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2),
                  label: 'Stock',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long),
                  label: 'Dépenses',
                ),
                NavigationDestination(
                  icon: Icon(Icons.description_outlined),
                  selectedIcon: Icon(Icons.description),
                  label: 'Rapports',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: 'Paramètres',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profil',
                ),
              ],
            ),
    );
  }
}
