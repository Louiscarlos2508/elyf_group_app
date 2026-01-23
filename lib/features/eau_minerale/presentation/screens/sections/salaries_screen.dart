import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../widgets/fixed_employee_form.dart';
import '../../widgets/fixed_employees_content.dart';
// Already imported via widgets.dart
import '../../widgets/production_payment_form.dart';
import '../../widgets/production_payments_content.dart';
import '../../widgets/salary_history_content.dart';
import '../../widgets/salary_summary_cards.dart';
import '../../widgets/salary_tabs.dart';
import '../../widgets/salary_analysis_content.dart';
import 'payment_reconciliation_screen.dart';

class SalariesScreen extends ConsumerStatefulWidget {
  const SalariesScreen({super.key});

  @override
  ConsumerState<SalariesScreen> createState() => _SalariesScreenState();
}

class _SalariesScreenState extends ConsumerState<SalariesScreen> {
  int _selectedTab = 0;

  void _showEmployeeForm(BuildContext context) {
    final formKey = GlobalKey<FixedEmployeeFormState>();
    showDialog(
      context: context,
      builder: (context) => FormDialog(
        title: 'Nouvel Employé Fixe',
        child: FixedEmployeeForm(key: formKey),
        onSave: () async {
          final state = formKey.currentState;
          if (state != null) {
            await state.submit();
          }
        },
      ),
    );
  }

  void _showProductionPaymentForm(BuildContext context) {
    final formKey = GlobalKey<ProductionPaymentFormState>();
    showDialog(
      context: context,
      builder: (context) => FormDialog(
        title: 'Nouveau Paiement Production',
        onSave: () async {
          final state = formKey.currentState;
          if (state != null) {
            await state.submit();
          }
        },
        saveLabel: 'Enregistrer les Paiements',
        child: ProductionPaymentForm(key: formKey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(
              'Gestion Salaires',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            centerTitle: false,
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PaymentReconciliationScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.account_balance_wallet_outlined),
                tooltip: 'Réconciliation',
              ),
              IconButton(
                onPressed: () => ref.invalidate(salaryStateProvider),
                icon: const Icon(Icons.refresh),
                tooltip: 'Actualiser',
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: SalarySummaryCards(
                onNewPayment: () => _showProductionPaymentForm(context),
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverSalaryTabsDelegate(
              SalaryTabs(
                selectedTab: _selectedTab,
                onTabChanged: (index) => setState(() => _selectedTab = index),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: _selectedTab == 0
                  ? FixedEmployeesContent(
                      onNewEmployee: () => _showEmployeeForm(context),
                    )
                  : _selectedTab == 1
                      ? ProductionPaymentsContent(
                          onNewPayment: () => _showProductionPaymentForm(context),
                        )
                      : _selectedTab == 2
                          ? const SalaryHistoryContent()
                          : const SalaryAnalysisContent(),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }
}

class _SliverSalaryTabsDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverSalaryTabsDelegate(this.child);

  @override
  double get minExtent => 60.0;
  @override
  double get maxExtent => 60.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    );
  }

  @override
  bool shouldRebuild(_SliverSalaryTabsDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}
