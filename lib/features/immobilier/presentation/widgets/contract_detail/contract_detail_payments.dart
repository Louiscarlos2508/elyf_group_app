import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/features/immobilier/application/providers.dart';
import '../../../domain/entities/payment.dart';
import '../contract_card_helpers.dart';
import 'contract_detail_components.dart';

/// Section des paiements du contrat.
class ContractPaymentsSection extends ConsumerWidget {
  const ContractPaymentsSection({
    super.key,
    required this.contractId,
    this.onPaymentTap,
  });

  final String contractId;
  final void Function(Payment)? onPaymentTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentsByContractProvider((contractId)));
    final theme = Theme.of(context);

    return ContractSectionCard(
      title: 'Paiements',
      icon: Icons.payment,
      child: paymentsAsync.when(
        data: (payments) {
          if (payments.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Aucun paiement enregistré',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }

          // Afficher les 5 derniers paiements
          final recentPayments = payments.take(5).toList();
          return Column(
            children: [
              ...recentPayments.map(
                (p) => ContractPaymentListTile(
                  payment: p,
                  onTap: onPaymentTap != null ? () => onPaymentTap!(p) : null,
                ),
              ),
              if (payments.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '+ ${payments.length - 5} autres paiements',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (e, _) => Text('Erreur: $e'),
      ),
    );
  }
}

/// Widget pour un paiement dans la liste.
class ContractPaymentListTile extends StatelessWidget {
  const ContractPaymentListTile({super.key, required this.payment, this.onTap});

  final Payment payment;
  final VoidCallback? onTap;

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return Colors.green;
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.overdue:
        return Colors.red;
      case PaymentStatus.cancelled:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(payment.status);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 32,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                ContractCardHelpers.formatDate(payment.paymentDate),
                style: theme.textTheme.bodyMedium,
              ),
            ),
            Text(
              ContractCardHelpers.formatCurrency(payment.amount),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
