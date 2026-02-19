import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart' as shared;
import 'package:elyf_groupe_app/shared.dart' show NavigationSection;
import 'package:elyf_groupe_app/core/permissions/modules/immobilier_permissions.dart';
import '../../../../../core/tenant/tenant_provider.dart'
    show activeEnterpriseProvider;
import '../../presentation/screens/sections/contracts_screen.dart';
import '../../presentation/screens/sections/dashboard_screen.dart';
import '../../presentation/screens/sections/payments_screen.dart';
import '../../presentation/screens/sections/properties_screen.dart';
import '../../presentation/screens/sections/reports_screen.dart';
import '../../presentation/screens/sections/tenants_screen.dart';
import '../../presentation/screens/sections/maintenance_screen.dart';
import '../../presentation/screens/sections/treasury_screen.dart';
import '../../presentation/screens/sections/z_report_screen.dart';
import 'permission_providers.dart';

import '../../presentation/screens/settings/immobilier_settings_screen.dart';

/// Provider pour récupérer les sections accessibles selon les permissions.
///
/// Filtre les sections de navigation en fonction des permissions de l'utilisateur.
final accessibleImmobilierSectionsProvider =
    FutureProvider<List<NavigationSection>>((ref) async {
  final adapter = ref.watch(immobilierPermissionAdapterProvider);
  final enterpriseId =
      ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
  final moduleId = 'immobilier';

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
      requiredPermissions: {ImmobilierPermissions.viewDashboard.id},
    ),
    (
      section: NavigationSection(
        label: 'Paiements',
        icon: Icons.payment_outlined,
        builder: () => const PaymentsScreen(),
        isPrimary: true,
        enterpriseId: enterpriseId,
        moduleId: moduleId,
      ),
      requiredPermissions: {ImmobilierPermissions.viewPayments.id},
    ),
    (
      section: NavigationSection(
        label: 'Maintenance',
        icon: Icons.handyman_outlined,
        builder: () => const MaintenanceScreen(),
        enterpriseId: enterpriseId,
        moduleId: moduleId,
      ),
      requiredPermissions: {ImmobilierPermissions.viewMaintenance.id},
    ),
    (
      section: NavigationSection(
        label: 'Trésorerie',
        icon: Icons.account_balance_wallet_outlined,
        builder: () => const TreasuryScreen(),
        enterpriseId: enterpriseId,
        moduleId: moduleId,
      ),
      requiredPermissions: {ImmobilierPermissions.viewTreasury.id},
    ),
    (
      section: NavigationSection(
        label: 'Locataires',
        icon: Icons.people_outlined,
        builder: () => const TenantsScreen(),
        isPrimary: true,
        enterpriseId: enterpriseId,
        moduleId: moduleId,
      ),
      requiredPermissions: {ImmobilierPermissions.viewTenants.id},
    ),
    (
      section: NavigationSection(
        label: 'Contrats',
        icon: Icons.description_outlined,
        builder: () => const ContractsScreen(),
        isPrimary: true,
        enterpriseId: enterpriseId,
        moduleId: moduleId,
      ),
      requiredPermissions: {ImmobilierPermissions.viewContracts.id},
    ),
    (
      section: NavigationSection(
        label: 'Propriétés',
        icon: Icons.home_outlined,
        builder: () => const PropertiesScreen(),
        isPrimary: true,
        enterpriseId: enterpriseId,
        moduleId: moduleId,
      ),
      requiredPermissions: {ImmobilierPermissions.viewProperties.id},
    ),
    (
      section: NavigationSection(
        label: 'Rapports',
        icon: Icons.assessment_outlined,
        builder: () => const ReportsScreen(),
        enterpriseId: enterpriseId,
        moduleId: moduleId,
      ),
      requiredPermissions: {ImmobilierPermissions.viewReports.id},
    ),
    (
      section: NavigationSection(
        label: 'Rapport Z',
        icon: Icons.history_edu_outlined,
        builder: () => const ZReportScreen(),
        enterpriseId: enterpriseId,
        moduleId: moduleId,
      ),
      requiredPermissions: {ImmobilierPermissions.viewTreasury.id},
    ),
    (
      section: NavigationSection(
        label: 'Paramètres',
        icon: Icons.settings_outlined,
        builder: () => const ImmobilierSettingsScreen(),
        enterpriseId: enterpriseId,
        moduleId: moduleId,
      ),
      requiredPermissions: {ImmobilierPermissions.manageSettings.id},
    ),
    (
      section: NavigationSection(
        label: 'Profil',
        icon: Icons.person_outline,
        builder: () => const shared.ProfileScreen(),
        enterpriseId: enterpriseId,
        moduleId: moduleId,
      ),
      requiredPermissions: {ImmobilierPermissions.viewProfile.id},
    ),
  ];

  // Filtrer les sections selon les permissions
  final accessibleSections = <NavigationSection>[];

  for (final item in allSections) {
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
