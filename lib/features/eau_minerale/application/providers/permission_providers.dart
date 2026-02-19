import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart' hide ProfileScreen;

import 'package:elyf_groupe_app/features/administration/application/providers.dart'
    show permissionServiceProvider;
import '../../../../core/permissions/services/permission_service.dart';
import '../../../../core/auth/providers.dart' as auth;
import '../../domain/adapters/eau_minerale_permission_adapter.dart';
import '../../domain/entities/eau_minerale_section.dart';
import '../../presentation/screens/sections/catalog_screen.dart';
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
import '../../presentation/screens/sections/suppliers_screen.dart';
import '../../presentation/screens/sections/purchases_screen.dart';
import '../../presentation/screens/sections/treasury_screen.dart';

/// Provider for centralized permission service.
/// Uses the shared permission service from administration module.
final centralizedPermissionServiceProvider = Provider<PermissionService>((ref) {
  return ref.watch(permissionServiceProvider);
});

/// Provider for current user ID.
/// Uses the authenticated user ID from auth service, or falls back to default user for development.
final currentUserIdProvider = Provider<String>((ref) {
  final authUserId = ref.watch(auth.currentUserIdProvider);
  if (authUserId != null && authUserId.isNotEmpty) {
    return authUserId;
  }
  return 'default_user_eau_minerale';
});

/// Provider for eau_minerale permission adapter.
final eauMineralePermissionAdapterProvider =
    Provider<EauMineralePermissionAdapter>(
      (ref) => EauMineralePermissionAdapter(
        permissionService: ref.watch(centralizedPermissionServiceProvider),
        userId: ref.watch(currentUserIdProvider),
      ),
    );

/// Provider to check a specific permission.
/// Results are cached and properly handled via AsyncValue.
final hasPermissionProvider =
    FutureProvider.family<bool, String>((ref, permissionId) async {
      final adapter = ref.watch(eauMineralePermissionAdapterProvider);
      return await adapter.hasPermission(permissionId);
    });

/// Provider to check if user has any of the specified permissions.
final hasAnyPermissionProvider =
    FutureProvider.family<bool, Set<String>>((ref, permissionIds) async {
      final adapter = ref.watch(eauMineralePermissionAdapterProvider);
      return await adapter.hasAnyPermission(permissionIds);
    });

/// Provider to check if user has all specified permissions.
final hasAllPermissionsProvider =
    FutureProvider.family<bool, Set<String>>((ref, permissionIds) async {
      final adapter = ref.watch(eauMineralePermissionAdapterProvider);
      return await adapter.hasAllPermissions(permissionIds);
    });

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
    id: EauMineraleSection.sales,
    label: 'Ventes',
    icon: Icons.point_of_sale,
    builder: () => const SalesScreen(),
  ),
  EauMineraleSectionConfig(
    id: EauMineraleSection.production,
    label: 'Production',
    icon: Icons.factory_outlined,
    builder: () => const ProductionSessionsScreen(),
  ),
  EauMineraleSectionConfig(
    id: EauMineraleSection.stock,
    label: 'Stock',
    icon: Icons.inventory_2_outlined,
    builder: () => const StockScreen(),
  ),
  EauMineraleSectionConfig(
    id: EauMineraleSection.purchases,
    label: 'Achats',
    icon: Icons.add_shopping_cart,
    builder: () => const PurchasesScreen(),
  ),
  EauMineraleSectionConfig(
    id: EauMineraleSection.suppliers,
    label: 'Fournisseurs',
    icon: Icons.local_shipping_outlined,
    builder: () => const SuppliersScreen(),
  ),
  EauMineraleSectionConfig(
    id: EauMineraleSection.treasury,
    label: 'Trésorerie',
    icon: Icons.account_balance_wallet_outlined,
    builder: () => const TreasuryScreen(),
  ),
  EauMineraleSectionConfig(
    id: EauMineraleSection.finances,
    label: 'Dépenses',
    icon: Icons.receipt_long,
    builder: () => const FinancesScreen(),
  ),
  EauMineraleSectionConfig(
    id: EauMineraleSection.clients,
    label: 'Crédits',
    icon: Icons.credit_card,
    builder: () => const ClientsScreen(),
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
    id: EauMineraleSection.catalog,
    label: 'Catalogue',
    icon: Icons.inventory_2_outlined,
    builder: () => const CatalogScreen(),
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
final accessibleSectionsProvider =
    FutureProvider.autoDispose<List<EauMineraleSectionConfig>>((ref) async {
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
    });

/// Provider for navigation sections used in the shell.
/// Memoizes the conversion from EauMineraleSectionConfig to NavigationSection.
final navigationSectionsProvider = FutureProvider.family<
  List<NavigationSection>,
  ({String enterpriseId, String moduleId})
>((ref, params) async {
  final configs = await ref.watch(accessibleSectionsProvider.future);

  final primarySectionIds = {
    EauMineraleSection.activity,
    EauMineraleSection.sales,
    EauMineraleSection.production,
    EauMineraleSection.stock,
    EauMineraleSection.purchases,
    EauMineraleSection.treasury,
    EauMineraleSection.finances,
    EauMineraleSection.clients,
  };

  return configs.map((config) {
    return NavigationSection(
      label: config.label,
      icon: config.icon,
      builder: config.builder,
      isPrimary: primarySectionIds.contains(config.id),
      enterpriseId: params.enterpriseId,
      moduleId: params.moduleId,
    );
  }).toList();
});
