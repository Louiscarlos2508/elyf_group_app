import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart' as shared;
import 'package:elyf_groupe_app/shared.dart' show NavigationSection;
import 'package:elyf_groupe_app/core/permissions/modules/orange_money_permissions.dart';
import '../../../../../core/tenant/tenant_provider.dart' show activeEnterpriseProvider;
import '../../presentation/screens/sections/agents_screen.dart';
import '../../presentation/screens/sections/commissions_screen.dart';
import '../../presentation/screens/sections/liquidity_screen.dart';
import '../../presentation/screens/sections/reports_screen.dart';
import '../../presentation/screens/sections/settings_screen.dart';
import '../../presentation/screens/sections/transactions_v2_screen.dart';
import 'permission_providers.dart';

/// Provider pour récupérer les sections accessibles selon les permissions.
/// 
/// Filtre les sections de navigation en fonction des permissions de l'utilisateur.
final accessibleOrangeMoneySectionsProvider = FutureProvider<List<NavigationSection>>((ref) async {
  final adapter = ref.watch(orangeMoneyPermissionAdapterProvider);
  final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
  final moduleId = 'orange_money';

  // Toutes les sections possibles avec leurs permissions requises
  final allSections = <({NavigationSection section, Set<String> requiredPermissions})>[
    (
      section: NavigationSection(
        label: 'Transactions',
        icon: Icons.swap_horiz,
        builder: () => const TransactionsV2Screen(),
        isPrimary: true,
        enterpriseId: enterpriseId,
        moduleId: moduleId,
      ),
      requiredPermissions: {OrangeMoneyPermissions.viewTransactions.id},
    ),
    (
      section: NavigationSection(
        label: 'Agents Affiliés',
        icon: Icons.people_outline,
        builder: () => AgentsScreen(enterpriseId: enterpriseId),
        isPrimary: true,
        enterpriseId: enterpriseId,
        moduleId: moduleId,
      ),
      requiredPermissions: {OrangeMoneyPermissions.viewAgents.id},
    ),
    (
      section: NavigationSection(
        label: 'Liquidité',
        icon: Icons.wallet,
        builder: () => LiquidityScreen(enterpriseId: enterpriseId),
        isPrimary: true,
        enterpriseId: enterpriseId,
        moduleId: moduleId,
      ),
      requiredPermissions: {OrangeMoneyPermissions.viewLiquidity.id},
    ),
    (
      section: NavigationSection(
        label: 'Commissions',
        icon: Icons.account_balance_wallet,
        builder: () => CommissionsScreen(enterpriseId: enterpriseId),
        isPrimary: true,
        enterpriseId: enterpriseId,
        moduleId: moduleId,
      ),
      requiredPermissions: {OrangeMoneyPermissions.viewCommissions.id},
    ),
    (
      section: NavigationSection(
        label: 'Rapports',
        icon: Icons.description,
        builder: () => ReportsScreen(enterpriseId: enterpriseId),
        isPrimary: false,
        enterpriseId: enterpriseId,
        moduleId: moduleId,
      ),
      requiredPermissions: {OrangeMoneyPermissions.viewReports.id},
    ),
    (
      section: NavigationSection(
        label: 'Paramètres',
        icon: Icons.settings,
        builder: () => SettingsScreen(enterpriseId: enterpriseId),
        isPrimary: false,
        enterpriseId: enterpriseId,
        moduleId: moduleId,
      ),
      requiredPermissions: {OrangeMoneyPermissions.viewSettings.id},
    ),
    (
      section: NavigationSection(
        label: 'Profil',
        icon: Icons.person_outline,
        builder: () => const shared.ProfileScreen(),
        isPrimary: false,
        enterpriseId: enterpriseId,
        moduleId: moduleId,
      ),
      requiredPermissions: {OrangeMoneyPermissions.viewProfile.id},
    ),
  ];

  // Filtrer les sections selon les permissions
  final accessibleSections = <NavigationSection>[];

  for (final item in allSections) {
    // Vérifier si l'utilisateur a au moins une des permissions requises
    final hasAccess = await adapter.hasAnyPermission(item.requiredPermissions);
    
    if (hasAccess) {
      accessibleSections.add(item.section);
    }
  }

  return accessibleSections;
});

