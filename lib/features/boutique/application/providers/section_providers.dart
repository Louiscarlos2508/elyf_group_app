import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/core/permissions/modules/boutique_permissions.dart';
import '../../../../../core/tenant/tenant_provider.dart'
    show activeEnterpriseProvider;
import '../../presentation/screens/sections/catalog_screen.dart';
import '../../presentation/screens/sections/dashboard_screen.dart';
import '../../presentation/screens/sections/expenses_screen.dart';
import '../../presentation/screens/sections/purchases_screen.dart';
import 'package:elyf_groupe_app/features/boutique/presentation/screens/sections/pos_screen.dart';
import 'package:elyf_groupe_app/features/boutique/presentation/screens/sections/reports_screen.dart';
import 'package:elyf_groupe_app/features/boutique/presentation/screens/sections/treasury_screen.dart';
import 'package:elyf_groupe_app/features/boutique/presentation/screens/sections/suppliers_screen.dart';
import 'package:elyf_groupe_app/features/boutique/presentation/screens/sections/stock_screen.dart';
import 'package:elyf_groupe_app/features/boutique/presentation/screens/sections/settings_screen.dart';
import 'package:elyf_groupe_app/features/boutique/presentation/screens/sections/sales_screen.dart';
import 'permission_providers.dart';

/// Provider pour récupérer les sections accessibles selon les permissions.
///
/// Filtre les sections de navigation en fonction des permissions de l'utilisateur.
final accessibleBoutiqueSectionsProvider =
    FutureProvider<List<NavigationSection>>((ref) async {
      final adapter = ref.watch(boutiquePermissionAdapterProvider);
      final enterpriseId =
          ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
      final moduleId = 'boutique';

      // Toutes les sections possibles avec leurs permissions requises
      final allSections =
          <({NavigationSection section, Set<String> requiredPermissions})>[
            (
              section: NavigationSection(
                label: 'Tableau',
                icon: Icons.dashboard_outlined,
                builder: () => const DashboardScreen(),
                isPrimary: true,
                enterpriseId: enterpriseId,
                moduleId: moduleId,
              ),
              requiredPermissions: {BoutiquePermissions.viewDashboard.id},
            ),
            (
              section: NavigationSection(
                label: 'Caisse',
                icon: Icons.point_of_sale,
                builder: () => const PosScreen(),
                isPrimary: true,
                enterpriseId: enterpriseId,
                moduleId: moduleId,
              ),
              requiredPermissions: {
                BoutiquePermissions.usePos.id,
                BoutiquePermissions.viewSales.id,
              },
            ),
            (
              section: NavigationSection(
                label: 'Catalogue',
                icon: Icons.inventory_2_outlined,
                builder: () => const CatalogScreen(),
                isPrimary: true,
                enterpriseId: enterpriseId,
                moduleId: moduleId,
              ),
              requiredPermissions: {BoutiquePermissions.viewProducts.id},
            ),
            (
              section: NavigationSection(
                label: 'Inventaire',
                icon: Icons.inventory_outlined,
                builder: () => const StockScreen(),
                isPrimary: true,
                enterpriseId: enterpriseId,
                moduleId: moduleId,
              ),
              requiredPermissions: {BoutiquePermissions.viewStock.id},
            ),
            (
              section: NavigationSection(
                label: 'Achats',
                icon: Icons.shopping_bag_outlined,
                builder: () => const PurchasesScreen(),
                enterpriseId: enterpriseId,
                moduleId: moduleId,
              ),
              requiredPermissions: {BoutiquePermissions.viewPurchases.id},
            ),
            (
              section: NavigationSection(
                label: 'Dépenses',
                icon: Icons.receipt_long_outlined,
                builder: () => const ExpensesScreen(),
                enterpriseId: enterpriseId,
                moduleId: moduleId,
              ),
              requiredPermissions: {BoutiquePermissions.viewExpenses.id},
            ),
            (
              section: NavigationSection(
                label: 'Trésorerie',
                icon: Icons.account_balance_wallet_outlined,
                builder: () => const TreasuryScreen(),
                enterpriseId: enterpriseId,
                moduleId: moduleId,
              ),
              requiredPermissions: {BoutiquePermissions.viewTreasury.id},
            ),
            (
              section: NavigationSection(
                label: 'Fournisseurs',
                icon: Icons.local_shipping_outlined,
                builder: () => const SuppliersScreen(),
                enterpriseId: enterpriseId,
                moduleId: moduleId,
              ),
              requiredPermissions: {BoutiquePermissions.viewSuppliers.id},
            ),
            (
              section: NavigationSection(
                label: 'Rapports',
                icon: Icons.assessment_outlined,
                builder: () => const ReportsScreen(),
                enterpriseId: enterpriseId,
                moduleId: moduleId,
              ),
              requiredPermissions: {BoutiquePermissions.viewReports.id},
            ),
            (
              section: NavigationSection(
                label: 'Journal',
                icon: Icons.history_outlined,
                builder: () => const SalesScreen(),
                enterpriseId: enterpriseId,
                moduleId: moduleId,
              ),
              requiredPermissions: {BoutiquePermissions.viewSales.id},
            ),
            (
              section: NavigationSection(
                label: 'Paramètres',
                icon: Icons.settings_outlined,
                builder: () => const SettingsScreen(),
                enterpriseId: enterpriseId,
                moduleId: moduleId,
              ),
              requiredPermissions: {BoutiquePermissions.viewSettings.id},
            ),
            (
              section: NavigationSection(
                label: 'Profil',
                icon: Icons.person_outline,
                builder: () => const ProfileScreen(),
                enterpriseId: enterpriseId,
                moduleId: moduleId,
              ),
              requiredPermissions: {BoutiquePermissions.viewProfile.id},
            ),
          ];

      // Filtrer les sections selon les permissions
      final accessibleSections = <NavigationSection>[];

      for (final item in allSections) {
        // En développement, on affiche tout pour l'utilisateur par défaut
        if (ref.read(currentUserIdProvider) == 'default_user_boutique') {
          accessibleSections.add(item.section);
          continue;
        }

        // Vérifier si l'utilisateur a au moins une des permissions requises
        final hasAccess = await adapter.hasAnyPermission(
          item.requiredPermissions,
        );

        if (hasAccess) {
          accessibleSections.add(item.section);
        }
      }

      return accessibleSections;
    });
