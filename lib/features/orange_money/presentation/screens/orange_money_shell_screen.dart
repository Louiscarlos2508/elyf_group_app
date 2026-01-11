import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart' as shared;
import 'sections/agents_screen.dart';
import 'package:elyf_groupe_app/shared/presentation/widgets/base_module_shell_screen.dart';
import 'sections/commissions_screen.dart';
import 'sections/liquidity_screen.dart';
import 'sections/reports_screen.dart';
import 'sections/settings_screen.dart';
import 'sections/transactions_v2_screen.dart';

class OrangeMoneyShellScreen extends BaseModuleShellScreen {
  const OrangeMoneyShellScreen({
    super.key,
    required super.enterpriseId,
    required super.moduleId,
  });

  @override
  BaseModuleShellScreenState<OrangeMoneyShellScreen> createState() =>
      _OrangeMoneyShellScreenState();
}

class _OrangeMoneyShellScreenState
    extends BaseModuleShellScreenState<OrangeMoneyShellScreen> {
  @override
  String get moduleName => 'Orange Money';

  @override
  IconData get moduleIcon => Icons.account_balance_wallet_outlined;

  @override
  String get appTitle => 'Orange Money';

  @override
  List<NavigationSection> buildSections() {
    return [
      NavigationSection(
        label: 'Transactions',
        icon: Icons.swap_horiz,
        builder: () => const TransactionsV2Screen(),
        isPrimary: true,
      ),
      NavigationSection(
        label: 'Agents Affiliés',
        icon: Icons.people_outline,
        builder: () => AgentsScreen(enterpriseId: widget.enterpriseId),
        isPrimary: true,
      ),
      NavigationSection(
        label: 'Liquidité',
        icon: Icons.wallet,
        builder: () => LiquidityScreen(enterpriseId: widget.enterpriseId),
        isPrimary: true,
      ),
      NavigationSection(
        label: 'Commissions',
        icon: Icons.account_balance_wallet,
        builder: () => CommissionsScreen(enterpriseId: widget.enterpriseId),
        isPrimary: true,
      ),
      NavigationSection(
        label: 'Rapports',
        icon: Icons.description,
        builder: () => ReportsScreen(enterpriseId: widget.enterpriseId),
        isPrimary: false,
      ),
      NavigationSection(
        label: 'Paramètres',
        icon: Icons.settings,
        builder: () => SettingsScreen(enterpriseId: widget.enterpriseId),
        isPrimary: false,
      ),
      NavigationSection(
        label: 'Profil',
        icon: Icons.person_outline,
        builder: () => const shared.ProfileScreen(),
        isPrimary: false,
      ),
    ];
  }
}

