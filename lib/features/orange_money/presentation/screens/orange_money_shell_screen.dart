import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/presentation/widgets/adaptive_navigation_scaffold.dart';
import '../../../../shared/presentation/widgets/profile/profile_screen.dart' as shared;
import 'sections/agents_screen.dart';
import 'sections/commissions_screen.dart';
import 'sections/liquidity_screen.dart';
import 'sections/reports_screen.dart';
import 'sections/settings_screen.dart';
import 'sections/transactions_v2_screen.dart';

class OrangeMoneyShellScreen extends ConsumerStatefulWidget {
  const OrangeMoneyShellScreen({
    super.key,
    required this.enterpriseId,
    required this.moduleId,
  });

  final String enterpriseId;
  final String moduleId;

  @override
  ConsumerState<OrangeMoneyShellScreen> createState() =>
      _OrangeMoneyShellScreenState();
}

class _OrangeMoneyShellScreenState
    extends ConsumerState<OrangeMoneyShellScreen> {
  int _index = 0;

  List<NavigationSection> _buildSections() {
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

  @override
  Widget build(BuildContext context) {
    return AdaptiveNavigationScaffold(
      appTitle: 'Orange Money',
      sections: _buildSections(),
      selectedIndex: _index,
      onIndexChanged: (index) => setState(() => _index = index),
      enterpriseId: widget.enterpriseId,
      moduleId: widget.moduleId,
    );
  }
}

