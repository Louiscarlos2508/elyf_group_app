import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared.dart';
import '../../application/providers.dart';
import '../../domain/entities/tour.dart';
import 'tour_form/tour_date_picker.dart';
import 'tour_form/tour_fee_input.dart';
import 'tour_form/tour_form_header.dart';

/// Formulaire de création d'un nouveau tour.
class TourFormDialog extends ConsumerStatefulWidget {
  const TourFormDialog({super.key});

  @override
  ConsumerState<TourFormDialog> createState() => _TourFormDialogState();
}

class _TourFormDialogState extends ConsumerState<TourFormDialog> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  final _loadingFeeController = TextEditingController(text: '200');
  final _unloadingFeeController = TextEditingController(text: '25');
  String? _enterpriseId;

  @override
  void dispose() {
    _loadingFeeController.dispose();
    _unloadingFeeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _enterpriseId == null) {
      return;
    }

    try {
      final controller = ref.read(tourControllerProvider);

      final tour = Tour(
        id: '',
        enterpriseId: _enterpriseId!,
        tourDate: _selectedDate,
        status: TourStatus.collection,
        collections: const [],
        loadingFeePerBottle: double.tryParse(_loadingFeeController.text) ?? 0.0,
        unloadingFeePerBottle:
            double.tryParse(_unloadingFeeController.text) ?? 0.0,
      );

      await controller.createTour(tour);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // TODO: Récupérer enterpriseId depuis le contexte/tenant
    _enterpriseId ??= 'default_enterprise';

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.1),
            width: 1.305,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const TourFormHeader(),
                const SizedBox(height: 24),
                // Date du tour
                TourDatePicker(
                  selectedDate: _selectedDate,
                  onDateSelected: (date) => setState(() => _selectedDate = date),
                ),
                const SizedBox(height: 16),
                // Frais de chargement
                TourFeeInput(
                  label: 'Frais de chargement par bouteille',
                  controller: _loadingFeeController,
                ),
                const SizedBox(height: 16),
                // Frais de déchargement
                TourFeeInput(
                  label: 'Frais de déchargement par bouteille',
                  controller: _unloadingFeeController,
                ),
                const SizedBox(height: 24),
                // Boutons d'action
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: GazButtonStyles.outlined,
                        child: const Text(
                          'Annuler',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: _submit,
                        style: GazButtonStyles.filledPrimary,
                        child: const Text(
                          'Créer',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
