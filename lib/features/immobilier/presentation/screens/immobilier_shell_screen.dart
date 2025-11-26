import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/presentation/widgets/profile/profile_screen.dart'
    as shared;
import '../../application/providers.dart';
import 'sections/contracts_screen.dart';
import 'sections/dashboard_screen.dart';
import 'sections/expenses_screen.dart';
import 'sections/payments_screen.dart';
import 'sections/properties_screen.dart';
import 'sections/reports_screen.dart';
import 'sections/tenants_screen.dart';

class ImmobilierShellScreen extends ConsumerStatefulWidget {
  const ImmobilierShellScreen({super.key});

  @override
  ConsumerState<ImmobilierShellScreen> createState() =>
      _ImmobilierShellScreenState();
}

class _ImmobilierShellScreenState
    extends ConsumerState<ImmobilierShellScreen> {
  int _selectedIndex = 0;

  final _sections = [
    _SectionConfig(
      label: 'Tableau',
      icon: Icons.dashboard_outlined,
      builder: () => const DashboardScreen(),
    ),
    _SectionConfig(
      label: 'Propriétés',
      icon: Icons.home_outlined,
      builder: () => const PropertiesScreen(),
    ),
    _SectionConfig(
      label: 'Locataires',
      icon: Icons.people_outlined,
      builder: () => const TenantsScreen(),
    ),
    _SectionConfig(
      label: 'Contrats',
      icon: Icons.description_outlined,
      builder: () => const ContractsScreen(),
    ),
    _SectionConfig(
      label: 'Paiements',
      icon: Icons.payment_outlined,
      builder: () => const PaymentsScreen(),
    ),
    _SectionConfig(
      label: 'Dépenses',
      icon: Icons.receipt_long_outlined,
      builder: () => const ExpensesScreen(),
    ),
    _SectionConfig(
      label: 'Rapports',
      icon: Icons.assessment_outlined,
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
    final isWide = MediaQuery.of(context).size.width >= 600;

    if (isWide) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Immobilier • Maisons'),
          centerTitle: true,
        ),
        body: Row(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: NavigationRail(
                        selectedIndex: _selectedIndex,
                        onDestinationSelected: (index) {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                        labelType: NavigationRailLabelType.all,
                        destinations: _sections
                            .map(
                              (section) => NavigationRailDestination(
                                icon: Icon(section.icon),
                                selectedIcon: Icon(section.icon),
                                label: Text(section.label),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                );
              },
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Immobilier • Maisons'),
        centerTitle: true,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _sections.map((s) => s.builder()).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: _sections
            .map(
              (section) => NavigationDestination(
                icon: Icon(section.icon),
                selectedIcon: Icon(section.icon),
                label: section.label,
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

