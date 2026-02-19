import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart' show PaymentMethod;
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import 'package:elyf_groupe_app/features/immobilier/application/providers.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/entities/payment.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/features/audit_trail/application/providers.dart';
import '../../widgets/immobilier_header.dart';

class ZReportScreen extends ConsumerWidget {
  const ZReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final paymentsAsync = ref.watch(paymentsProvider);
    final balancesAsync = ref.watch(treasuryBalancesProvider);

    // Calculate Collections
    final payments = paymentsAsync.value ?? [];
    final today = DateTime.now();
    final List<Payment> todayPayments = payments.where((p) {
      final date = p.paymentDate;
      return date.year == today.year && date.month == today.month && date.day == today.day;
    }).toList();

    int cashCollected = 0;
    int mmCollected = 0;
    for (final p in todayPayments) {
      if (p.paymentMethod == PaymentMethod.cash) {
        cashCollected += p.paidAmount.toInt();
      } else if (p.paymentMethod == PaymentMethod.mobileMoney) {
        mmCollected += p.paidAmount.toInt();
      }
    }

    // Get Balances
    final Map<String, int> balances = balancesAsync.value ?? {};
    final theoreticalCash = balances['cash'] ?? 0;
    final theoreticalMM = balances['mobileMoney'] ?? 0;

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
                    data: (payments) => _buildCollectionsSummary(theme, cashCollected, mmCollected),
                    loading: () => const LoadingIndicator(),
                    error: (e, st) => ErrorDisplayWidget(error: e),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle(theme, 'Soldes Théoriques'),
                  const SizedBox(height: 16),
                  balancesAsync.when(
                    data: (balances) => _buildBalancesSummary(theme, theoreticalCash, theoreticalMM),
                    loading: () => const LoadingIndicator(),
                    error: (e, st) => ErrorDisplayWidget(error: e),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _showCloseShiftConfirmation(
                        context,
                        ref,
                        cashCollected: cashCollected,
                        mmCollected: mmCollected,
                        theoreticalCash: theoreticalCash,
                        theoreticalMM: theoreticalMM,
                      ),
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

  Widget _buildCollectionsSummary(ThemeData theme, int cashTotal, int mmTotal) {
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

  Widget _buildBalancesSummary(ThemeData theme, int cashBalance, int mmBalance) {
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
            cashBalance,
            Icons.account_balance_wallet,
            Colors.green,
          ),
          const Divider(height: 1),
          _buildSummaryRow(
            theme,
            'Solde Théorique Mobile Money',
            mmBalance,
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

  void _showCloseShiftConfirmation(
    BuildContext context,
    WidgetRef ref, {
    required int cashCollected,
    required int mmCollected,
    required int theoreticalCash,
    required int theoreticalMM,
  }) {
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
            onPressed: () async {
              try {
                final auditService = ref.read(auditTrailServiceProvider);
                final enterpriseId = ref.read(activeEnterpriseProvider).value?.id ?? 'default';
                final userId = ref.read(currentUserIdProvider) ?? 'unknown';

                await auditService.logAction(
                  enterpriseId: enterpriseId,
                  userId: userId,
                  module: 'immobilier',
                  action: 'close_day',
                  entityId: DateTime.now().toIso8601String().split('T').first,
                  entityType: 'z_report',
                  metadata: {
                    'cashCollected': cashCollected,
                    'mmCollected': mmCollected,
                    'theoreticalCash': theoreticalCash,
                    'theoreticalMM': theoreticalMM,
                    'totalCollected': cashCollected + mmCollected,
                    'timestamp': DateTime.now().toIso8601String(),
                  },
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  NotificationService.showSuccess(context, 'Journée clôturée avec succès (Audit enregistré)');
                }
              } catch (e) {
                if (context.mounted) {
                  NotificationService.showError(context, 'Erreur lors de la clôture: $e');
                }
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}
