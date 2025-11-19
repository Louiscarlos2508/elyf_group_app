import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/controllers/finances_controller.dart';
import '../../../application/providers.dart';
import '../../widgets/enhanced_list_card.dart';
import '../../widgets/expense_form.dart';
import '../../widgets/form_dialog.dart';
import '../../widgets/section_placeholder.dart';

class FinancesScreen extends ConsumerWidget {
  const FinancesScreen({super.key});

  void _showForm(BuildContext context) {
    final formKey = GlobalKey<ExpenseFormState>();
    showDialog(
      context: context,
      builder: (context) => FormDialog(
        title: 'Nouvelle dépense',
        child: ExpenseForm(key: formKey),
        onSave: () async {
          final state = formKey.currentState;
          if (state != null) {
            await state.submit();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financesStateProvider);
    return Scaffold(
      body: state.when(
        data: (data) => _FinancesContent(state: data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => SectionPlaceholder(
          icon: Icons.account_balance,
          title: 'Charges indisponibles',
          subtitle: 'Impossible de charger les dernières dépenses.',
          primaryActionLabel: 'Réessayer',
          onPrimaryAction: () => ref.invalidate(financesStateProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'finances_fab',
        onPressed: () => _showForm(context),
        icon: const Icon(Icons.add_card),
        label: const Text('Nouvelle dépense'),
      ),
    );
  }
}

class _FinancesContent extends StatelessWidget {
  const _FinancesContent({required this.state});

  final FinancesState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.red.withValues(alpha: 0.2),
                Colors.red.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                Icons.trending_down,
                size: 32,
                color: theme.colorScheme.onSurface,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total charges',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${state.totalCharges} CFA',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: state.expenses.length,
            itemBuilder: (context, index) {
              final expense = state.expenses[index];
              return EnhancedListCard(
                title: expense.label,
                subtitle: expense.category.name,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.receipt_long, color: Colors.red, size: 20),
                ),
                trailing: Text(
                  '${expense.amountCfa} CFA',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
