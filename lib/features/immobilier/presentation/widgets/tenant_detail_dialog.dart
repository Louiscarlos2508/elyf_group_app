import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/immobilier/application/providers.dart';
import '../../domain/entities/contract.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/tenant.dart';
import 'contract_card_helpers.dart';
import 'tenant_form_dialog.dart';

/// Dialog de détails d'un locataire avec onglets.
class TenantDetailDialog extends ConsumerWidget {
  const TenantDetailDialog({
    super.key,
    required this.tenant,
    this.onContractTap,
    this.onPaymentTap,
  });

  final Tenant tenant;
  final void Function(Contract)? onContractTap;
  final void Function(Payment)? onPaymentTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: DefaultTabController(
          length: 3,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context, theme, ref),
              TabBar(
                labelColor: theme.colorScheme.primary,
                tabs: const [
                  Tab(text: 'Infos', icon: Icon(Icons.person)),
                  Tab(text: 'Contrats', icon: Icon(Icons.description)),
                  Tab(text: 'Paiements', icon: Icon(Icons.payment)),
                ],
              ),
              Flexible(
                child: TabBarView(
                  children: [
                    _InfoTab(tenant: tenant),
                    _ContractsTab(
                      tenantId: tenant.id,
                      onContractTap: onContractTap,
                    ),
                    _PaymentsTab(
                      tenantId: tenant.id,
                      onPaymentTap: onPaymentTap,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              tenant.fullName.isNotEmpty
                  ? tenant.fullName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tenant.fullName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tenant.phone,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).pop();
              showDialog(
                context: context,
                builder: (context) => TenantFormDialog(tenant: tenant),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _InfoTab extends StatelessWidget {
  const _InfoTab({required this.tenant});

  final Tenant tenant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoTile(icon: Icons.phone, label: 'Téléphone', value: tenant.phone),
          _InfoTile(icon: Icons.email, label: 'Email', value: tenant.email),
          if (tenant.address != null)
            _InfoTile(
              icon: Icons.location_on,
              label: 'Adresse',
              value: tenant.address!,
            ),
          if (tenant.idNumber != null)
            _InfoTile(
              icon: Icons.badge,
              label: 'Pièce d\'identité',
              value: tenant.idNumber!,
            ),
          if (tenant.emergencyContact != null)
            _InfoTile(
              icon: Icons.emergency,
              label: 'Contact d\'urgence',
              value: tenant.emergencyContact!,
            ),
          if (tenant.notes != null && tenant.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Notes',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(tenant.notes!),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
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
                Text(value, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContractsTab extends ConsumerWidget {
  const _ContractsTab({required this.tenantId, this.onContractTap});

  final String tenantId;
  final void Function(Contract)? onContractTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contractsAsync = ref.watch(contractsByTenantProvider((tenantId)));
    final theme = Theme.of(context);

    return contractsAsync.when(
      data: (contracts) {
        if (contracts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  'Aucun contrat',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: contracts.length,
          itemBuilder: (context, index) {
            final contract = contracts[index];
            return _ContractMiniCard(
              contract: contract,
              onTap: onContractTap != null
                  ? () => onContractTap!(contract)
                  : null,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
    );
  }
}

class _ContractMiniCard extends StatelessWidget {
  const _ContractMiniCard({required this.contract, this.onTap});

  final Contract contract;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = ContractCardHelpers.getStatusColor(contract.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 8,
          height: 40,
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        title: Text(
          contract.property?.address ??
              'Propriété #${contract.propertyId.length > 8 ? contract.propertyId.substring(0, 8) : contract.propertyId}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${ContractCardHelpers.formatDate(contract.startDate)} - ${ContractCardHelpers.formatDate(contract.endDate)}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              ContractCardHelpers.formatCurrency(contract.monthlyRent),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              ContractCardHelpers.getStatusLabel(contract.status),
              style: theme.textTheme.bodySmall?.copyWith(color: statusColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentsTab extends ConsumerWidget {
  const _PaymentsTab({required this.tenantId, this.onPaymentTap});

  final String tenantId;
  final void Function(Payment)? onPaymentTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentsByTenantProvider((tenantId)));
    final theme = Theme.of(context);

    return paymentsAsync.when(
      data: (payments) {
        if (payments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.payment_outlined,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  'Aucun paiement',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final payment = payments[index];
            return _PaymentMiniCard(
              payment: payment,
              onTap: onPaymentTap != null ? () => onPaymentTap!(payment) : null,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
    );
  }
}

class _PaymentMiniCard extends StatelessWidget {
  const _PaymentMiniCard({required this.payment, this.onTap});

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

  String _getStatusLabel(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return 'Payé';
      case PaymentStatus.pending:
        return 'En attente';
      case PaymentStatus.overdue:
        return 'En retard';
      case PaymentStatus.cancelled:
        return 'Annulé';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(payment.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 8,
          height: 40,
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        title: Text(
          ContractCardHelpers.formatCurrency(payment.amount),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(ContractCardHelpers.formatDate(payment.paymentDate)),
        trailing: Chip(
          label: Text(
            _getStatusLabel(payment.status),
            style: TextStyle(fontSize: 11, color: statusColor),
          ),
          backgroundColor: statusColor.withValues(alpha: 0.1),
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
