import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/contract.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/tenant.dart';
import 'contract_card_helpers.dart';
import 'contract_form_dialog.dart';

/// Dialog de détails d'un contrat avec liens vers locataire et propriété.
class ContractDetailDialog extends ConsumerWidget {
  const ContractDetailDialog({
    super.key,
    required this.contract,
    this.onTenantTap,
    this.onPropertyTap,
    this.onPaymentTap,
    this.onDelete,
  });

  final Contract contract;
  final void Function(Tenant)? onTenantTap;
  final void Function(Property)? onPropertyTap;
  final void Function(Payment)? onPaymentTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusColor = ContractCardHelpers.getStatusColor(contract.status);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context, theme, statusColor, ref),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusBanner(theme, statusColor),
                    const SizedBox(height: 16),
                    _buildDatesSection(theme),
                    const SizedBox(height: 16),
                    _buildFinancialSection(theme),
                    const SizedBox(height: 16),
                    _buildLinkedEntitiesSection(context, theme),
                    const SizedBox(height: 16),
                    _PaymentsSection(
                      contractId: contract.id,
                      onPaymentTap: onPaymentTap,
                    ),
                    if (contract.notes != null && contract.notes!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildNotesSection(theme),
                    ],
                  ],
                ),
              ),
            ),
            _buildActions(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    Color statusColor,
    WidgetRef ref,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.description, color: statusColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contrat ${contract.id.substring(0, 8)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  contract.property?.address ?? 'Propriété non définie',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(ThemeData theme, Color statusColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: statusColor, size: 20),
          const SizedBox(width: 12),
          Text(
            'Statut: ${ContractCardHelpers.getStatusLabel(contract.status)}',
            style: theme.textTheme.titleSmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatesSection(ThemeData theme) {
    final duration = contract.endDate.difference(contract.startDate).inDays;
    final months = (duration / 30).round();

    return _SectionCard(
      title: 'Période du contrat',
      icon: Icons.calendar_month,
      child: Column(
        children: [
            Row(
            children: [
              Expanded(
                child: _InfoColumn(
                  label: 'Date de début',
                  value: ContractCardHelpers.formatDate(contract.startDate),
                ),
              ),
              Expanded(
                child: _InfoColumn(
                  label: 'Date de fin',
                  value: ContractCardHelpers.formatDate(contract.endDate),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InfoColumn(
                  label: 'Durée',
                  value: '$months mois',
                ),
              ),
              if (contract.paymentDay != null)
                Expanded(
                  child: _InfoColumn(
                    label: 'Jour de paiement',
                    value: 'Le ${contract.paymentDay} de chaque mois',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSection(ThemeData theme) {
    return _SectionCard(
      title: 'Informations financières',
      icon: Icons.attach_money,
      child: Row(
        children: [
          Expanded(
            child: _InfoColumn(
              label: 'Loyer mensuel',
              value: ContractCardHelpers.formatCurrency(contract.monthlyRent),
              valueStyle: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Expanded(
            child: _InfoColumn(
              label: 'Caution',
              value: ContractCardHelpers.formatCurrency(contract.calculatedDeposit),
              subtitle: contract.depositInMonths != null
                  ? '(${contract.depositInMonths} mois)'
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedEntitiesSection(BuildContext context, ThemeData theme) {
    return _SectionCard(
      title: 'Entités liées',
      icon: Icons.link,
      child: Column(
        children: [
          if (contract.tenant != null)
            _EntityLinkTile(
              icon: Icons.person,
              label: 'Locataire',
              value: contract.tenant!.fullName,
              subtitle: contract.tenant!.phone,
              onTap: onTenantTap != null
                  ? () {
                      Navigator.of(context).pop();
                      onTenantTap!(contract.tenant!);
                    }
                  : null,
            ),
          if (contract.property != null) ...[
            const Divider(height: 16),
            _EntityLinkTile(
              icon: Icons.home,
              label: 'Propriété',
              value: contract.property!.address,
              subtitle: '${contract.property!.city} - ${contract.property!.rooms} pièces',
              onTap: onPropertyTap != null
                  ? () {
                      Navigator.of(context).pop();
                      onPropertyTap!(contract.property!);
                    }
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesSection(ThemeData theme) {
    return _SectionCard(
      title: 'Notes',
      icon: Icons.note,
      child: Text(contract.notes!),
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (onDelete != null)
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onDelete!();
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Supprimer'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                showDialog(
                  context: context,
                  builder: (context) => ContractFormDialog(contract: contract),
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text('Modifier'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  const _InfoColumn({
    required this.label,
    required this.value,
    this.subtitle,
    this.valueStyle,
  });

  final String label;
  final String value;
  final String? subtitle;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: valueStyle ?? theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _EntityLinkTile extends StatelessWidget {
  const _EntityLinkTile({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(icon, size: 20, color: theme.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}

class _PaymentsSection extends ConsumerWidget {
  const _PaymentsSection({
    required this.contractId,
    this.onPaymentTap,
  });

  final String contractId;
  final void Function(Payment)? onPaymentTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentsByContractProvider(contractId));
    final theme = Theme.of(context);

    return _SectionCard(
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
              ...recentPayments.map((p) => _PaymentListTile(
                payment: p,
                onTap: onPaymentTap != null ? () => onPaymentTap!(p) : null,
              )),
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

class _PaymentListTile extends StatelessWidget {
  const _PaymentListTile({
    required this.payment,
    this.onTap,
  });

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
