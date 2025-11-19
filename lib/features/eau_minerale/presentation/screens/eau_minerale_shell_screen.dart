import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import 'sections/dashboard_screen.dart';
import 'sections/clients_screen.dart';
import 'sections/finances_screen.dart';
import 'sections/production_screen.dart';
import 'sections/sales_screen.dart';
import 'sections/settings_screen.dart';
import 'sections/stock_screen.dart';

class EauMineraleShellScreen extends ConsumerStatefulWidget {
  const EauMineraleShellScreen({super.key});

  @override
  ConsumerState<EauMineraleShellScreen> createState() =>
      _EauMineraleShellScreenState();
}

class _EauMineraleShellScreenState
    extends ConsumerState<EauMineraleShellScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final sections = _sections;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eau Minérale • Module'),
        actions: [
          IconButton(icon: const Icon(Icons.print_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.sync), onPressed: () {}),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: sections.map((s) => s.builder()).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: sections
            .map(
              (s) => NavigationDestination(icon: Icon(s.icon), label: s.label),
            )
            .toList(),
      ),
    );
  }
}

class _SectionConfig {
  const _SectionConfig({
    required this.id,
    required this.label,
    required this.icon,
    required this.builder,
  });

  final EauMineraleSection id;
  final String label;
  final IconData icon;
  final Widget Function() builder;
}

const _sections = [
  _SectionConfig(
    id: EauMineraleSection.activity,
    label: 'Tableau',
    icon: Icons.dashboard_outlined,
    builder: DashboardScreen.new,
  ),
  _SectionConfig(
    id: EauMineraleSection.production,
    label: 'Production',
    icon: Icons.factory_outlined,
    builder: ProductionScreen.new,
  ),
  _SectionConfig(
    id: EauMineraleSection.sales,
    label: 'Ventes',
    icon: Icons.point_of_sale,
    builder: SalesScreen.new,
  ),
  _SectionConfig(
    id: EauMineraleSection.stock,
    label: 'Stock',
    icon: Icons.inventory_2_outlined,
    builder: StockScreen.new,
  ),
  _SectionConfig(
    id: EauMineraleSection.clients,
    label: 'Clients',
    icon: Icons.people_alt_outlined,
    builder: ClientsScreen.new,
  ),
  _SectionConfig(
    id: EauMineraleSection.finances,
    label: 'Finances',
    icon: Icons.account_balance,
    builder: FinancesScreen.new,
  ),
  _SectionConfig(
    id: EauMineraleSection.settings,
    label: 'Paramètres',
    icon: Icons.settings,
    builder: SettingsScreen.new,
  ),
];
