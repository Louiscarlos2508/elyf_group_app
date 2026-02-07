import 'package:flutter/material.dart';
import '../../../domain/entities/contract.dart';
import '../../../domain/entities/property.dart';
import '../../../domain/entities/tenant.dart';
import '../contract_card_helpers.dart';
import 'contract_detail_components.dart';

/// Section des dates du contrat.
class ContractDatesSection extends StatelessWidget {
  const ContractDatesSection({super.key, required this.contract});

  final Contract contract;

  @override
  Widget build(BuildContext context) {
    final duration = contract.endDate?.difference(contract.startDate).inDays;
    final months = duration != null ? (duration / 30).round() : 0;

    return ContractSectionCard(
      title: 'Période du contrat',
      icon: Icons.calendar_month,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ContractInfoColumn(
                  label: 'Date de début',
                  value: ContractCardHelpers.formatDate(contract.startDate),
                ),
              ),
              Expanded(
                child: ContractInfoColumn(
                  label: 'Date de fin',
                  value: contract.endDate != null ? ContractCardHelpers.formatDate(contract.endDate!) : 'Indéterminée',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ContractInfoColumn(
                  label: 'Durée',
                  value: '$months mois',
                ),
              ),
              if (contract.paymentDay != null)
                Expanded(
                  child: ContractInfoColumn(
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
}

/// Section financière du contrat.
class ContractFinancialSection extends StatelessWidget {
  const ContractFinancialSection({super.key, required this.contract});

  final Contract contract;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ContractSectionCard(
      title: 'Informations financières',
      icon: Icons.attach_money,
      child: Row(
        children: [
          Expanded(
            child: ContractInfoColumn(
              label: 'Loyer mensuel',
              value: ContractCardHelpers.formatCurrency(contract.monthlyRent),
              valueStyle: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Expanded(
            child: ContractInfoColumn(
              label: 'Caution',
              value: ContractCardHelpers.formatCurrency(
                contract.calculatedDeposit,
              ),
              subtitle: contract.depositInMonths != null
                  ? '(${contract.depositInMonths} mois)'
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section des entités liées.
class ContractLinkedEntitiesSection extends StatelessWidget {
  const ContractLinkedEntitiesSection({
    super.key,
    required this.contract,
    this.onTenantTap,
    this.onPropertyTap,
  });

  final Contract contract;
  final void Function(Tenant)? onTenantTap;
  final void Function(Property)? onPropertyTap;

  @override
  Widget build(BuildContext context) {
    return ContractSectionCard(
      title: 'Entités liées',
      icon: Icons.link,
      child: Column(
        children: [
          if (contract.tenant != null)
            ContractEntityLinkTile(
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
            ContractEntityLinkTile(
              icon: Icons.home,
              label: 'Propriété',
              value: contract.property!.address,
              subtitle:
                  '${contract.property!.city} - ${contract.property!.rooms} pièces',
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
}

/// Section des notes.
class ContractNotesSection extends StatelessWidget {
  const ContractNotesSection({super.key, required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    return ContractSectionCard(
      title: 'Notes',
      icon: Icons.note,
      child: Text(notes),
    );
  }
}

/// Section de l'état des lieux (Inventory).
class ContractInventorySection extends StatelessWidget {
  const ContractInventorySection({
    super.key,
    this.entryInventory,
    this.exitInventory,
  });

  final String? entryInventory;
  final String? exitInventory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ContractSectionCard(
      title: 'État des Lieux (Inventaire)',
      icon: Icons.checklist_rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInventoryItem(
            theme,
            'Entrée',
            entryInventory,
            Icons.login,
            Colors.green,
          ),
          if (exitInventory != null && exitInventory!.isNotEmpty) ...[
            const Divider(height: 24),
            _buildInventoryItem(
              theme,
              'Sortie',
              exitInventory,
              Icons.logout,
              Colors.orange,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInventoryItem(
    ThemeData theme,
    String label,
    String? content,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          (content == null || content.isEmpty) ? 'Non documenté' : content,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontStyle: (content == null || content.isEmpty) ? FontStyle.italic : null,
            color: (content == null || content.isEmpty) ? theme.colorScheme.onSurfaceVariant : null,
          ),
        ),
      ],
    );
  }
}
