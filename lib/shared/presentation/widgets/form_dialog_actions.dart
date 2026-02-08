import 'package:flutter/material.dart';
import 'elyf_ui/atoms/elyf_button.dart';

/// Actions génériques pour les dialogs de formulaire.
class FormDialogActions extends StatelessWidget {
  const FormDialogActions({
    super.key,
    required this.onCancel,
    required this.onSubmit,
    this.submitLabel = 'Enregistrer',
    this.cancelLabel = 'Annuler',
    this.isLoading = false,
    this.submitEnabled = true,
  });

  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  final String submitLabel;
  final String cancelLabel;
  final bool isLoading;
  final bool submitEnabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElyfButton(
            onPressed: isLoading ? null : onCancel,
            variant: ElyfButtonVariant.outlined,
            width: double.infinity,
            child: Text(
              cancelLabel,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElyfButton(
            onPressed: (isLoading || !submitEnabled) ? null : onSubmit,
            isLoading: isLoading,
            width: double.infinity,
            child: Text(
              submitLabel,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}
