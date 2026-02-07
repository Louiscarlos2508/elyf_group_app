import 'package:flutter/material.dart';
import '../../domain/entities/contract.dart';
import 'contract_card_helpers.dart';

class ContractStatusSelector extends StatelessWidget {
  const ContractStatusSelector({
    super.key,
    required this.status,
    required this.onChanged,
  });

  final ContractStatus status;
  final ValueChanged<ContractStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statut du contrat',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ContractStatus.values.map((s) {
            final isSelected = status == s;
            final color = ContractCardHelpers.getStatusColor(s);
            
            return ChoiceChip(
              label: Text(
                _getStatusLabel(s),
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) onChanged(s);
              },
              selectedColor: color,
              backgroundColor: color.withValues(alpha: 0.1),
              side: BorderSide(
                color: isSelected ? Colors.transparent : color.withValues(alpha: 0.5),
              ),
              avatar: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getStatusLabel(ContractStatus status) {
    switch (status) {
      case ContractStatus.active:
        return 'Actif';
      case ContractStatus.pending:
        return 'En attente';
      case ContractStatus.expired:
        return 'Expiré';
      case ContractStatus.terminated:
        return 'Résilié';
    }
  }
}
