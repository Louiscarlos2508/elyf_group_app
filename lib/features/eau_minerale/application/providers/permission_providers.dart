import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/administration/application/providers.dart' show permissionServiceProvider;
import '../../../../core/permissions/services/permission_service.dart';
import '../../domain/adapters/eau_minerale_permission_adapter.dart';
import '../../domain/entities/eau_minerale_section.dart';
import '../../presentation/screens/sections/clients_screen.dart';
import '../../presentation/screens/sections/dashboard_screen.dart';
import '../../presentation/screens/sections/finances_screen.dart';
import '../../presentation/screens/sections/profile_screen.dart';
import '../../presentation/screens/sections/production_sessions_screen.dart';
import '../../presentation/screens/sections/reports_screen.dart';
import '../../presentation/screens/sections/salaries_screen.dart';
import '../../presentation/screens/sections/sales_screen.dart';
import '../../presentation/screens/sections/settings_screen.dart';
import '../../presentation/screens/sections/stock_screen.dart';

/// Initialize permissions when module loads
void _initializeEauMineralePermissions() {
  EauMineralePermissionAdapter.initialize();
}

/// Provider for centralized permission service.
/// Uses the shared permission service from administration module.
final centralizedPermissionServiceProvider = Provider<PermissionService>(
  (ref) {
    // Initialize permissions on first access
    _initializeEauMineralePermissions();
    return ref.watch(permissionServiceProvider);
  },
);

/// Provider for current user ID.
/// In development, uses default user with full access for the module.
/// TODO: Replace with actual auth system when available
final currentUserIdProvider = Provider<String>(
  (ref) => 'default_user_eau_minerale', // Default user with full access
);

/// Provider for eau_minerale permission adapter.
final eauMineralePermissionAdapterProvider = Provider<EauMineralePermissionAdapter>(
  (ref) => EauMineralePermissionAdapter(
    permissionService: ref.watch(centralizedPermissionServiceProvider),
    userId: ref.watch(currentUserIdProvider),
  ),
);

/// Configuration for a section in the module shell.
class EauMineraleSectionConfig {
  const EauMineraleSectionConfig({
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

final _allSections = [
  EauMineraleSectionConfig(
    id: EauMineraleSection.activity,
    label: 'Tableau',
    icon: Icons.dashboard_outlined,
    builder: () => const DashboardScreen(),
  ),
  EauMineraleSectionConfig(
    id: EauMineraleSection.production,
    label: 'Production',
    icon: Icons.factory_outlined,
    builder: () => const ProductionSessionsScreen(),
  ),
  EauMineraleSectionConfig(
    id: EauMineraleSection.sales,
    label: 'Ventes',
    icon: Icons.point_of_sale,
    builder: () => const SalesScreen(),
  ),
  EauMineraleSectionConfig(
    id: EauMineraleSection.stock,
    label: 'Stock',
    icon: Icons.inventory_2_outlined,
    builder: () => const StockScreen(),
  ),
  EauMineraleSectionConfig(
    id: EauMineraleSection.clients,
    label: 'Crédits',
    icon: Icons.credit_card,
    builder: () => const ClientsScreen(),
  ),
  EauMineraleSectionConfig(
    id: EauMineraleSection.finances,
    label: 'Dépenses',
    icon: Icons.receipt_long,
    builder: () => const FinancesScreen(),
  ),
  EauMineraleSectionConfig(
    id: EauMineraleSection.salaries,
    label: 'Salaires',
    icon: Icons.people,
    builder: () => const SalariesScreen(),
  ),
  EauMineraleSectionConfig(
    id: EauMineraleSection.reports,
    label: 'Rapports',
    icon: Icons.description,
    builder: () => const ReportsScreen(),
  ),
  EauMineraleSectionConfig(
    id: EauMineraleSection.profile,
    label: 'Profil',
    icon: Icons.person,
    builder: () => const ProfileScreen(),
  ),
  EauMineraleSectionConfig(
    id: EauMineraleSection.settings,
    label: 'Paramètres',
    icon: Icons.settings,
    builder: () => const SettingsScreen(),
  ),
];

/// Provider that caches accessible sections for the module shell.
/// Uses autoDispose to allow reloading when navigating away and back.
final accessibleSectionsProvider = FutureProvider.autoDispose<List<EauMineraleSectionConfig>>(
  (ref) async {
    // Ensure minimum loading time to show animation
    final loadingStart = DateTime.now();
    
    final adapter = ref.watch(eauMineralePermissionAdapterProvider);
    final accessible = <EauMineraleSectionConfig>[];
    
    for (final section in _allSections) {
      if (await adapter.canAccessSection(section.id)) {
        accessible.add(section);
      }
    }
    
    // Ensure animation is visible for at least 1.2 seconds
    final elapsed = DateTime.now().difference(loadingStart);
    const minimumDuration = Duration(milliseconds: 1200);
    if (elapsed < minimumDuration) {
      await Future.delayed(minimumDuration - elapsed);
    }
    
    return accessible;
  },
);

