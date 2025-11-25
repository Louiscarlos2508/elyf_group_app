import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/adapters/eau_minerale_permission_adapter.dart';
import '../../application/providers.dart';
import 'sections/dashboard_screen.dart';
import 'sections/clients_screen.dart';
import 'sections/finances_screen.dart';
import 'sections/production_screen.dart';
import 'sections/profile_screen.dart';
import 'sections/reports_screen.dart';
import 'sections/salaries_screen.dart';
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
    final adapter = ref.watch(eauMineralePermissionAdapterProvider);
    
    return FutureBuilder<List<_SectionConfig>>(
      future: _getAccessibleSections(adapter),
      builder: (context, snapshot) {
        final accessibleSections = snapshot.data ?? [];

        // Adjust index if current section is not accessible
        if (_index >= accessibleSections.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _index = 0);
            }
          });
        }

        final currentIndex = _index < accessibleSections.length ? _index : 0;

        // Show message if no sections accessible
        if (accessibleSections.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Eau Minérale • Module'),
            ),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Aucun accès',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Vous n\'avez pas accès à ce module.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Show navigation only if 2+ sections
        return Scaffold(
          appBar: AppBar(
            title: const Text('Eau Minérale • Module'),
          ),
          body: IndexedStack(
            index: currentIndex,
            children: accessibleSections.map((s) => s.builder()).toList(),
          ),
          bottomNavigationBar: accessibleSections.length >= 2
              ? NavigationBar(
                  selectedIndex: currentIndex,
                  onDestinationSelected: (i) {
                    if (i < accessibleSections.length) {
                      setState(() => _index = i);
                    }
                  },
                  destinations: accessibleSections
                      .map(
                        (s) => NavigationDestination(
                          icon: Icon(s.icon),
                          label: s.label,
                        ),
                      )
                      .toList(),
                )
              : null,
        );
      },
    );
  }

  Future<List<_SectionConfig>> _getAccessibleSections(
    EauMineralePermissionAdapter adapter,
  ) async {
    final accessible = <_SectionConfig>[];
    for (final section in _sections) {
      if (await adapter.canAccessSection(section.id)) {
        accessible.add(section);
      }
    }
    return accessible;
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
    label: 'Crédits',
    icon: Icons.credit_card,
    builder: ClientsScreen.new,
  ),
  _SectionConfig(
    id: EauMineraleSection.finances,
    label: 'Dépenses',
    icon: Icons.receipt_long,
    builder: FinancesScreen.new,
  ),
  _SectionConfig(
    id: EauMineraleSection.salaries,
    label: 'Salaires',
    icon: Icons.people,
    builder: SalariesScreen.new,
  ),
  _SectionConfig(
    id: EauMineraleSection.reports,
    label: 'Rapports',
    icon: Icons.description,
    builder: ReportsScreen.new,
  ),
  _SectionConfig(
    id: EauMineraleSection.profile,
    label: 'Profil',
    icon: Icons.person,
    builder: ProfileScreen.new,
  ),
  _SectionConfig(
    id: EauMineraleSection.settings,
    label: 'Paramètres',
    icon: Icons.settings,
    builder: SettingsScreen.new,
  ),
];
