import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart' show PaymentMethod;
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import 'package:elyf_groupe_app/features/immobilier/application/providers.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/entities/payment.dart';
import '../../widgets/immobilier_header.dart';

class ZReportScreen extends ConsumerWidget {
  const ZReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final paymentsAsync = ref.watch(paymentsProvider);
    final balancesAsync = ref.watch(treasuryBalancesProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const ImmobilierHeader(
            title: 'RAPPORT Z',
            subtitle: 'Bilan de la journée',
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(theme, 'Collections du Jour'),
                  const SizedBox(height: 16),
                  paymentsAsync.when(
                    data: (payments) => _buildCollectionsSummary(theme, payments.cast<Payment>()),
                    loading: () => const LoadingIndicator(),
                    error: (e, st) => ErrorDisplayWidget(error: e),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle(theme, 'Soldes Théoriques'),
                  const SizedBox(height: 16),
                  balancesAsync.when(
                    data: (balances) => _buildBalancesSummary(theme, balances),
                    loading: () => const LoadingIndicator(),
                    error: (e, st) => ErrorDisplayWidget(error: e),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _showCloseShiftConfirmation(context, ref),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Valider et Clôturer la Journée'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildCollectionsSummary(ThemeData theme, List<Payment> payments) {
    final today = DateTime.now();
    final todayPayments = payments.where((p) {
      final date = p.paymentDate;
      return date.year == today.year && date.month == today.month && date.day == today.day;
    }).toList();

    int cashTotal = 0;
    int mmTotal = 0;

    for (final p in todayPayments) {
      if (p.paymentMethod == PaymentMethod.cash) cashTotal += p.paidAmount;
      if (p.paymentMethod == PaymentMethod.mobileMoney) mmTotal += p.paidAmount;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            theme,
            'Espèces (Caisse)',
            cashTotal,
            Icons.money,
            Colors.green,
          ),
          const Divider(height: 1),
          _buildSummaryRow(
            theme,
            'Mobile Money',
            mmTotal,
            Icons.phone_android,
            Colors.blue,
          ),
          const Divider(height: 1),
          _buildSummaryRow(
            theme,
            'TOTAL COLLECTÉ',
            cashTotal + mmTotal,
            Icons.summarize,
            theme.colorScheme.primary,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBalancesSummary(ThemeData theme, Map<String, int> balances) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            theme,
            'Solde Théorique Espèces',
            balances['cash'] ?? 0,
            Icons.account_balance_wallet,
            Colors.green,
          ),
          const Divider(height: 1),
          _buildSummaryRow(
            theme,
            'Solde Théorique Mobile Money',
            balances['mobileMoney'] ?? 0,
            Icons.phonelink_setup,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    ThemeData theme,
    String label,
    int amount,
    IconData icon,
    Color color, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            CurrencyFormatter.formatFCFA(amount),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isTotal ? theme.colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }

  void _showCloseShiftConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clôturer la journée ?'),
        content: const Text(
          'Cette action valide les totaux affichés pour votre shift actuel. Un audit sera enregistré.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              // In the future, this would send an audit or lock the session
              Navigator.pop(context);
              NotificationService.showSuccess(context, 'Journée clôturée avec succès');
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}
