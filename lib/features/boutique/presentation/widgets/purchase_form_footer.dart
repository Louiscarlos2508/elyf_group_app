import 'package:flutter/material.dart';

class PurchaseFormFooter extends StatelessWidget {
  const PurchaseFormFooter({
    super.key,
    required this.totalAmount,
    required this.notesController,
    required this.isLoading,
    required this.onCancel,
    required this.onSave,
  });

  final int totalAmount;
  final TextEditingController notesController;
  final bool isLoading;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        ) + ' FCFA';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        if (totalAmount > 0) ...[
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _formatCurrency(totalAmount),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        TextFormField(
          controller: notesController,
          decoration: const InputDecoration(
            labelText: 'Notes (optionnel)',
            prefixIcon: Icon(Icons.note),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: isLoading ? null : onCancel,
              child: const Text('Annuler'),
            ),
            const SizedBox(width: 12),
            IntrinsicWidth(
              child: FilledButton(
                onPressed: isLoading ? null : onSave,
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Enregistrer'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

