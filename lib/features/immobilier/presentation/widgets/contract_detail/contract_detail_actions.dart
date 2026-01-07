import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../contract_form_dialog.dart';

/// Actions du dialog de détails de contrat.
class ContractDetailActions extends ConsumerWidget {
  const ContractDetailActions({
    super.key,
    required this.contract,
    this.onDelete,
  });

  final contract;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

