import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../widgets/fixed_employee_form.dart';
import '../../widgets/fixed_employees_content.dart';
import 'package:elyf_groupe_app/shared/presentation/widgets/refresh_button.dart';
import 'package:elyf_groupe_app/shared/presentation/widgets/form_dialog.dart';
// Already imported via widgets.dart
import '../../widgets/production_payment_form.dart';
import '../../widgets/production_payments_content.dart';
import '../../widgets/salary_history_content.dart';
import '../../widgets/salary_summary_cards.dart';
import '../../widgets/salary_tabs.dart';

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
        child: ProductionPaymentForm(key: formKey),
        onSave: () async {
          final state = formKey.currentState;
          if (state != null) {
            await state.submit();
          }
        },
        saveLabel: 'Enregistrer les Paiements',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  isWide ? 24 : 16,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.people,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Salaires & Indemnités',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    RefreshButton(
                      onRefresh: () => ref.invalidate(salaryStateProvider),
                      tooltip: 'Actualiser les salaires',
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SalarySummaryCards(
                  onNewPayment: () => _showProductionPaymentForm(context),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: SalaryTabs(
                  selectedTab: _selectedTab,
                  onTabChanged: (index) => setState(() => _selectedTab = index),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _selectedTab == 0
                    ? FixedEmployeesContent(
                        onNewEmployee: () => _showEmployeeForm(context),
                      )
                    : _selectedTab == 1
                        ? ProductionPaymentsContent(
                            onNewPayment: () => _showProductionPaymentForm(context),
                          )
                        : const SalaryHistoryContent(),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),
          ],
        );
      },
    );
  }
}

