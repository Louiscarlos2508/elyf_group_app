import 'package:flutter/material.dart';

class ProductFormFooter extends StatelessWidget {
  const ProductFormFooter({
    super.key,
    required this.isLoading,
    required this.isEditing,
    required this.onCancel,
    required this.onSave,
  });

  final bool isLoading;
  final bool isEditing;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
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
                : Text(isEditing ? 'Enregistrer' : 'Créer'),
          ),
        ),
      ],
    );
  }
}

