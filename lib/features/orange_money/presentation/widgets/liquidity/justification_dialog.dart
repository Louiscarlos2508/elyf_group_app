import 'package:flutter/material.dart';

/// Dialog to provide a justification for a liquidity discrepancy.
class JustificationDialog extends StatefulWidget {
  const JustificationDialog({
    super.key,
    required this.checkpointId,
    required this.discrepancyPercentage,
  });

  final String checkpointId;
  final double discrepancyPercentage;

  @override
  State<JustificationDialog> createState() => _JustificationDialogState();
}

class _JustificationDialogState extends State<JustificationDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Justification de l\'écart'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Un écart de ${widget.discrepancyPercentage.toStringAsFixed(2)}% a été détecté. '
              'Veuillez expliquer la raison de cette différence.',
              style: const TextStyle(fontSize: 14, color: Color(0xFF4A5565)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ex: Erreur de saisie le matin, dépôt non enregistré...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La justification est obligatoire';
                }
                if (value.trim().length < 10) {
                  return 'Veuillez fournir une explication plus détaillée';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(_controller.text.trim());
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF155DFC),
            foregroundColor: Colors.white,
          ),
          child: const Text('Valider'),
        ),
      ],
    );
  }
}
