import 'package:flutter/material.dart';
import '../../../domain/entities/contract.dart';
import '../contract_card_helpers.dart';

/// Bannière de statut du contrat.
class ContractStatusBanner extends StatelessWidget {
  const ContractStatusBanner({
    super.key,
    required this.contract,
    required this.statusColor,
  });

  final Contract contract;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
}
