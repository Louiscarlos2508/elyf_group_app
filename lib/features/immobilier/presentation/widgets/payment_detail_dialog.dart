import 'package:flutter/material.dart';

import '../../domain/entities/contract.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/tenant.dart';
import 'payment_card_helpers.dart';
import 'payment_form_dialog.dart';

/// Dialog de détails d'un paiement avec informations complètes.
class PaymentDetailDialog extends StatelessWidget {
  const PaymentDetailDialog({
    super.key,
    required this.payment,
    this.onContractTap,
    this.onTenantTap,
    this.onPropertyTap,
    this.onDelete,
    this.onPrint,
    this.onDownloadPdf,
  });

  final Payment payment;
  final void Function(Contract)? onContractTap;
  final void Function(Tenant)? onTenantTap;
  final void Function(Property)? onPropertyTap;
  final VoidCallback? onDelete;
  final VoidCallback? onPrint;
  final VoidCallback? onDownloadPdf;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = PaymentCardHelpers.getStatusColor(payment.status);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context, theme, statusColor),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAmountSection(theme, statusColor),
                    const SizedBox(height: 16),
                    _buildDetailsSection(theme),
                    const SizedBox(height: 16),
                    _buildLinkedEntitiesSection(context, theme),
                    if (payment.notes != null && payment.notes!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildNotesSection(theme),
                    ],
                  ],
                ),
              ),
            ),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, Color statusColor) {
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
            child: Icon(
              PaymentCardHelpers.getMethodIcon(payment.paymentMethod),
              color: statusColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paiement',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (payment.receiptNumber != null)
                  Text(
                    'Reçu: ${payment.receiptNumber}',
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

  Widget _buildAmountSection(ThemeData theme, Color statusColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withValues(alpha: 0.1),
            statusColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            PaymentCardHelpers.formatCurrency(payment.amount),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              PaymentCardHelpers.getStatusLabel(payment.status),
              style: theme.textTheme.labelLarge?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (payment.paymentType != null) ...[
            const SizedBox(height: 8),
            Text(
              payment.paymentType == PaymentType.deposit ? 'Caution' : 'Loyer',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsSection(ThemeData theme) {
    return _SectionCard(
      title: 'Détails du paiement',
      icon: Icons.info_outline,
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.calendar_today,
            label: 'Date de paiement',
            value: PaymentCardHelpers.formatDate(payment.paymentDate),
          ),
          _DetailRow(
            icon: PaymentCardHelpers.getMethodIcon(payment.paymentMethod),
            label: 'Méthode',
            value: PaymentCardHelpers.getMethodLabel(payment.paymentMethod),
          ),
          if (payment.month != null && payment.year != null)
            _DetailRow(
              icon: Icons.calendar_month,
              label: 'Période',
              value: '${PaymentCardHelpers.getMonthName(payment.month!)} ${payment.year}',
            ),
          if (payment.receiptNumber != null)
            _DetailRow(
              icon: Icons.receipt,
              label: 'N° de reçu',
              value: payment.receiptNumber!,
            ),
        ],
      ),
    );
  }

  Widget _buildLinkedEntitiesSection(BuildContext context, ThemeData theme) {
    final contract = payment.contract;
    if (contract == null) {
      return const SizedBox.shrink();
    }

    return _SectionCard(
      title: 'Entités liées',
      icon: Icons.link,
      child: Column(
        children: [
          _EntityLinkTile(
            icon: Icons.description,
            label: 'Contrat',
            value: 'Contrat #${contract.id.substring(0, 8)}',
            subtitle: '${PaymentCardHelpers.formatCurrency(contract.monthlyRent)}/mois',
            onTap: onContractTap != null
                ? () {
                    Navigator.of(context).pop();
                    onContractTap!(contract);
                  }
                : null,
          ),
          if (contract.tenant != null) ...[
            const Divider(height: 16),
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
          ],
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
      child: Text(payment.notes!),
    );
  }

  Widget _buildActions(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Actions secondaires
          if (onPrint != null || onDownloadPdf != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onPrint != null)
                  TextButton.icon(
                    onPressed: onPrint,
                    icon: const Icon(Icons.print, size: 20),
                    label: const Text('Imprimer'),
                  ),
                if (onDownloadPdf != null) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: onDownloadPdf,
                    icon: const Icon(Icons.picture_as_pdf, size: 20),
                    label: const Text('PDF'),
                  ),
                ],
              ],
            ),
          const SizedBox(height: 8),
          // Actions principales
          Row(
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
                    foregroundColor: theme.colorScheme.error,
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
                      builder: (context) => PaymentFormDialog(payment: payment),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Modifier'),
                ),
              ),
            ],
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
              radius: 18,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(icon, size: 18, color: theme.colorScheme.onPrimaryContainer),
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
