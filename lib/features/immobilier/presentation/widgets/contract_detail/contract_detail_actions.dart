import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/contract.dart';
import '../../../application/providers.dart';
import '../contract_form_dialog.dart';

/// Actions du dialog de détails de contrat.
class ContractDetailActions extends ConsumerWidget {
  const ContractDetailActions({
    super.key,
    required this.contract,
    this.onDelete,
  });

  final Contract contract;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fermer'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
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
            ],
          ),
          const SizedBox(height: 12),
          _buildStatusActionButtons(context, ref),
        ],
      ),
    );
  }

  Widget _buildStatusActionButtons(BuildContext context, WidgetRef ref) {
    switch (contract.status) {
      case ContractStatus.pending:
        return FilledButton.icon(
          onPressed: () => _activateContract(context, ref),
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Activer le contrat'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
          ),
        );
      case ContractStatus.active:
        return FilledButton.icon(
          onPressed: () => _terminateContract(context, ref),
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Résilier le contrat'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Colors.white,
          ),
        );
      case ContractStatus.expired:
      case ContractStatus.terminated:
        return FilledButton.icon(
          onPressed: () {
            // Pour le renouvellement, on ouvre le formulaire de modification
            // mais on pourrait pré-remplir les dates pour une nouvelle période
             Navigator.of(context).pop();
             showDialog(
              context: context,
              builder: (context) => ContractFormDialog(contract: contract),
             );
          },
          icon: const Icon(Icons.autorenew),
          label: const Text('Renouveler / Reactiver'),
        );
    }
  }

  Future<void> _activateContract(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Activer le contrat ?'),
        content: const Text(
          'Cela marquera le contrat comme actif et la propriété comme louée (si ce n\'est pas déjà le cas).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Activer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (context.mounted) {
        Navigator.pop(context); // Close details
      }
      try {
        final updatedContract = contract.copyWith(
          status: ContractStatus.active,
          updatedAt: DateTime.now(),
        );
        await ref
            .read(contractControllerProvider)
            .updateContract(updatedContract);
            
         // Invalidations
        ref.invalidate(contractsProvider);
        ref.invalidate(propertiesProvider);
        
        // Pas besoin de toast ici, l'interface se mettra à jour
      } catch (e) {
        // Gérer l'erreur
      }
    }
  }

  Future<void> _terminateContract(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Résilier le contrat ?'),
        content: const Text(
          'Cela marquera le contrat comme résilié et libérera la propriété pour de nouvelles locations.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Résilier'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (context.mounted) {
        Navigator.pop(context); // Close details
      }
      try {
        final updatedContract = contract.copyWith(
          status: ContractStatus.terminated,
          // Optionnel : mettre à jour la date de fin à aujourd'hui si elle est future
          endDate: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await ref
            .read(contractControllerProvider)
            .updateContract(updatedContract);

        // Invalidations
        ref.invalidate(contractsProvider);
        ref.invalidate(propertiesProvider);
      } catch (e) {
         // Gérer l'erreur
      }
    }
  }
}
