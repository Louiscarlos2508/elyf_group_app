import 'package:flutter/material.dart';
import 'gaz_button_styles.dart';

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
          child: OutlinedButton(
            onPressed: isLoading ? null : onCancel,
            style: GazButtonStyles.outlined(context),
            child: Text(
              cancelLabel,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: (isLoading || !submitEnabled) ? null : onSubmit,
            style: GazButtonStyles.filledPrimary(context),
            child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    submitLabel,
                    style: const TextStyle(fontSize: 14),
                  ),
          ),
        ),
      ],
    );
  }
}
