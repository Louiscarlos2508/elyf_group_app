import 'package:flutter/material.dart';

/// Footer widget for credit payment dialog.
class CreditPaymentFooter extends StatelessWidget {
  const CreditPaymentFooter({
    super.key,
    required this.isLoading,
    required this.canSubmit,
    required this.onCancel,
    required this.onSubmit,
  });

  final bool isLoading;
  final bool canSubmit;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: isLoading ? null : onCancel,
            child: const Text('Annuler'),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: FilledButton.icon(
              onPressed: (isLoading || !canSubmit) ? null : onSubmit,
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: const Text('Enregistrer'),
            ),
          ),
        ],
      ),
    );
  }
}
