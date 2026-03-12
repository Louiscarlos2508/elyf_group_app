import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
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

    return CustomScrollView(
        slivers: [
          // Premium Header
          ElyfModuleHeader(
            title: "Salaires",
            subtitle: "Employés & Paiements",
            module: EnterpriseModule.eau,
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PaymentReconciliationScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.white),
                tooltip: 'Réconciliation',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              RefreshButton(
                onRefresh: () async {
                  ref.invalidate(salaryStateProvider);
                },
                tooltip: 'Actualiser',
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
              child: _SalariesTabContent(
                selectedTab: _selectedTab,
                onNewEmployee: () => _showEmployeeForm(context),
                onNewPayment: () => _showProductionPaymentForm(context),
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
    );
  }
}

/// Isolated widget for tab content to avoid rebuilding everything on tab switch.
class _SalariesTabContent extends StatelessWidget {
  const _SalariesTabContent({
    required this.selectedTab,
    required this.onNewEmployee,
    required this.onNewPayment,
  });

  final int selectedTab;
  final VoidCallback onNewEmployee;
  final VoidCallback onNewPayment;

  @override
  Widget build(BuildContext context) {
    switch (selectedTab) {
      case 0:
        return FixedEmployeesContent(
          onNewEmployee: onNewEmployee,
        );
      case 1:
        return ProductionPaymentsContent(
          onNewPayment: onNewPayment,
        );
      case 2:
        return const SalaryHistoryContent();
      case 3:
        return const SalaryAnalysisContent();
      default:
        return const SizedBox.shrink();
    }
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
