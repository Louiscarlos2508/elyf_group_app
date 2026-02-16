import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/core/logging/app_logger.dart';
import 'package:elyf_groupe_app/core/permissions/modules/gaz_permissions.dart';
import '../../../../../core/tenant/tenant_provider.dart'
    show activeEnterpriseProvider;
import '../../presentation/screens/sections/approvisionnement_screen.dart';
import '../../presentation/screens/sections/cylinder_leak_screen.dart';
import '../../presentation/screens/sections/dashboard_screen.dart';
import '../../presentation/screens/sections/expenses_screen.dart';
import '../../presentation/screens/sections/profile_screen.dart';
import '../../presentation/screens/sections/reports_screen.dart';
import '../../presentation/screens/sections/retail_screen.dart';
import '../../presentation/screens/sections/settings_screen.dart';
import '../../presentation/screens/sections/stock_screen.dart';
import '../../presentation/screens/sections/wholesale_screen.dart';
import '../../presentation/screens/sections/inventory_screen.dart';
import 'permission_providers.dart';

/// Provider pour récupérer les sections accessibles selon les permissions.
///
/// Filtre les sections de navigation en fonction des permissions de l'utilisateur.
final accessibleGazSectionsProvider = FutureProvider<List<NavigationSection>>((
  ref,
) async {
  final adapter = ref.watch(gazPermissionAdapterProvider);

  // Attendre que l'entreprise active soit chargée
  final activeEnterprise = await ref.read(activeEnterpriseProvider.future);
  if (activeEnterprise == null) {
    return [];
  }

  final enterpriseId = activeEnterprise.id;
  final moduleId = 'gaz';

  // Toutes les sections possibles avec leurs permissions requises
  final allSections =
      <({NavigationSection section, Set<String> requiredPermissions})>[
        (
          section: NavigationSection(
            label: 'Tableau',
            icon: Icons.dashboard_outlined,
            builder: () => const GazDashboardScreen(),
            isPrimary: true,
            enterpriseId: enterpriseId,
            moduleId: moduleId,
          ),
          requiredPermissions: {GazPermissions.viewDashboard.id},
        ),
        (
          section: NavigationSection(
            label: 'Détail',
            icon: Icons.store_outlined,
            builder: () => const GazRetailScreen(),
            isPrimary: true,
            enterpriseId: enterpriseId,
            moduleId: moduleId,
          ),
          requiredPermissions: {GazPermissions.viewSales.id},
        ),
        (
          section: NavigationSection(
            label: 'En gros',
            icon: Icons.local_shipping_outlined,
            builder: () => const GazWholesaleScreen(),
            isPrimary: true,
            enterpriseId: enterpriseId,
            moduleId: moduleId,
          ),
          requiredPermissions: {GazPermissions.viewWholesale.id},
        ),
        (
          section: NavigationSection(
            label: 'Stock',
            icon: Icons.inventory_2_outlined,
            builder: () => const GazStockScreen(),
            isPrimary: true,
            enterpriseId: enterpriseId,
            moduleId: moduleId,
          ),
          requiredPermissions: {GazPermissions.viewStock.id},
        ),
        (
          section: NavigationSection(
            label: 'Appro',
            icon: Icons.inventory_outlined,
            builder: () => const ApprovisionnementScreen(),
            isPrimary: true,
            enterpriseId: enterpriseId,
            moduleId: moduleId,
          ),
          requiredPermissions: {GazPermissions.viewTours.id},
        ),
        (
          section: NavigationSection(
            label: 'Fuites',
            icon: Icons.warning_outlined,
            builder: () => CylinderLeakScreen(
              enterpriseId: enterpriseId,
              moduleId: moduleId,
            ),
            enterpriseId: enterpriseId,
            moduleId: moduleId,
          ),
          requiredPermissions: {GazPermissions.viewLeaks.id},
        ),
        (
          section: NavigationSection(
            label: 'Dépenses',
            icon: Icons.receipt_long_outlined,
            builder: () => const GazExpensesScreen(),
            enterpriseId: enterpriseId,
            moduleId: moduleId,
          ),
          requiredPermissions: {GazPermissions.viewExpenses.id},
        ),
        (
          section: NavigationSection(
            label: 'Rapports',
            icon: Icons.description_outlined,
            builder: () => const GazReportsScreen(),
            enterpriseId: enterpriseId,
            moduleId: moduleId,
          ),
          requiredPermissions: {GazPermissions.viewReports.id},
        ),
        (
          section: NavigationSection(
            label: 'Paramètres',
            icon: Icons.settings_outlined,
            builder: () => const GazSettingsScreen(),
            enterpriseId: enterpriseId,
            moduleId: moduleId,
          ),
          requiredPermissions: {GazPermissions.viewSettings.id},
        ),
        (
          section: NavigationSection(
            label: 'Profil',
            icon: Icons.person_outline,
            builder: () => const GazProfileScreen(),
            enterpriseId: enterpriseId,
            moduleId: moduleId,
          ),
          requiredPermissions: {GazPermissions.viewProfile.id},
        ),
        (
          section: NavigationSection(
            label: 'Inventaire',
            icon: Icons.fact_check_outlined,
            builder: () => const GazInventoryScreen(),
            enterpriseId: enterpriseId,
            moduleId: moduleId,
          ),
          requiredPermissions: {GazPermissions.manageInventory.id},
        ),
      ];

  // Filtrer les sections selon les permissions
  final accessibleSections = <NavigationSection>[];

  for (final item in allSections) {
    // Vérifier si l'utilisateur a au moins une des permissions requises
    final hasAccess = await adapter.hasAnyPermission(item.requiredPermissions);

    // Log pour déboguer les permissions
    AppLogger.debug(
      'Section "${item.section.label}": permissions requises=${item.requiredPermissions}, hasAccess=$hasAccess',
      name: 'gaz.sections',
    );

    if (hasAccess) {
      accessibleSections.add(item.section);
    } else {
      AppLogger.debug(
        'Section "${item.section.label}" exclue: pas de permission',
        name: 'gaz.sections',
      );
    }
  }

  AppLogger.debug(
    'Sections accessibles: ${accessibleSections.map((s) => s.label).join(", ")}',
    name: 'gaz.sections',
  );

  return accessibleSections;
});
