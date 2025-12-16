import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/presentation/widgets/adaptive_navigation_scaffold.dart';
import '../../../../shared/presentation/widgets/profile/profile_screen.dart' as shared;
import '../../../../shared/presentation/widgets/treasury/treasury_screen.dart' as shared_treasury;
import 'sections/dashboard_screen.dart';
import 'sections/transactions_screen.dart';
import 'sections/cash_in_screen.dart';
import 'sections/cash_out_screen.dart';
import 'sections/reports_screen.dart';

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
        label: 'Tableau',
        icon: Icons.dashboard_outlined,
        builder: () => const DashboardScreen(),
        isPrimary: true,
      ),
      NavigationSection(
        label: 'Transactions',
        icon: Icons.history,
        builder: () => const TransactionsScreen(),
        isPrimary: true,
      ),
      NavigationSection(
        label: 'Cash-In',
        icon: Icons.arrow_downward,
        builder: () => const CashInScreen(),
        isPrimary: true,
      ),
      NavigationSection(
        label: 'Cash-Out',
        icon: Icons.arrow_upward,
        builder: () => const CashOutScreen(),
        isPrimary: true,
      ),
      NavigationSection(
        label: 'Rapports',
        icon: Icons.description,
        builder: () => const ReportsScreen(),
        isPrimary: false,
      ),
      NavigationSection(
        label: 'Trésorerie',
        icon: Icons.account_balance,
        builder: () => shared_treasury.TreasuryScreen(
          moduleId: widget.moduleId,
          moduleName: 'Orange Money',
        ),
        isPrimary: true,
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

