import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';

import '../../domain/entities/contract.dart';
import '../../domain/entities/payment.dart';

/// Section displaying alerts for immobilier dashboard.
class DashboardAlertsSection extends StatelessWidget {
  const DashboardAlertsSection({
    super.key,
    required this.unpaidPayments,
    required this.expiringContracts,
    this.onPaymentTap,
    this.onContractTap,
  });

  final List<Payment> unpaidPayments;
  final List<Contract> expiringContracts;
  final void Function(Payment)? onPaymentTap;
  final void Function(Contract)? onContractTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAlerts = unpaidPayments.isNotEmpty || expiringContracts.isNotEmpty;

    if (!hasAlerts) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Aucune alerte - Tout est en ordre !',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Loyers impayés
        if (unpaidPayments.isNotEmpty) ...[
          _AlertCard(
            title: 'Loyers en attente',
            count: unpaidPayments.length,
            icon: Icons.warning_amber_rounded,
            color: Colors.orange,
            items: unpaidPayments.take(3).map((p) {
              return _AlertItem(
                title: 'Loyer ${_formatMonthYear(p.paymentDate)}',
                subtitle: CurrencyFormatter.formatFCFA(p.amount),
                onTap: () => onPaymentTap?.call(p),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],

        // Contrats expirant bientôt
        if (expiringContracts.isNotEmpty)
          _AlertCard(
            title: 'Contrats expirant bientôt',
            count: expiringContracts.length,
            icon: Icons.event_busy,
            color: Colors.red,
            items: expiringContracts.take(3).map((c) {
              final daysLeft = c.endDate.difference(DateTime.now()).inDays;
              return _AlertItem(
                title: c.property?.address ?? 'Contrat',
                subtitle: '$daysLeft jours restants',
                onTap: () => onContractTap?.call(c),
              );
            }).toList(),
          ),
      ],
    );
  }

  String _formatMonthYear(DateTime date) {
    const months = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Août',
      'Sep',
      'Oct',
      'Nov',
      'Déc',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.items,
  });

  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final List<_AlertItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    count.toString(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...items,
        ],
      ),
    );
  }
}

class _AlertItem extends StatelessWidget {
  const _AlertItem({required this.title, required this.subtitle, this.onTap});

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }
}
