import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../application/providers.dart';
import '../../domain/entities/tour.dart';
import 'tour_form/tour_date_picker.dart';
import 'tour_form/tour_fee_input.dart';
import 'tour_form/tour_form_header.dart';
import '../../../../core/tenant/tenant_provider.dart';

/// Formulaire de création d'un nouveau tour.
class TourFormDialog extends ConsumerStatefulWidget {
  const TourFormDialog({super.key});

  @override
  ConsumerState<TourFormDialog> createState() => _TourFormDialogState();
}

class _TourFormDialogState extends ConsumerState<TourFormDialog>
    with FormHelperMixin {
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
    if (_enterpriseId == null) {
      NotificationService.showError(context, 'Entreprise non définie');
      return;
    }

    await handleFormSubmit(
      context: context,
      formKey: _formKey,
      onLoadingChanged:
          (_) {}, // Pas besoin de gestion d'état de chargement séparée
      onSubmit: () async {
        final controller = ref.read(tourControllerProvider);

        final tour = Tour(
          id: '',
          enterpriseId: _enterpriseId!,
          tourDate: _selectedDate,
          status: TourStatus.collection,
          collections: const [],
          loadingFeePerBottle:
              double.tryParse(_loadingFeeController.text) ?? 0.0,
          unloadingFeePerBottle:
              double.tryParse(_unloadingFeeController.text) ?? 0.0,
        );

        await controller.createTour(tour);

        if (mounted) {
          Navigator.of(context).pop(true);
        }

        return 'Tour créé avec succès';
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeEnterpriseAsync = ref.watch(activeEnterpriseProvider);
    
    // Récupérer l'ID de l'entreprise active
    final enterpriseId = activeEnterpriseAsync.when(
      data: (enterprise) => enterprise?.id,
      loading: () => null,
      error: (_, __) => null,
    );

    if (enterpriseId == null) {
      return Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Aucune entreprise sélectionnée',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fermer'),
              ),
            ],
          ),
        ),
      );
    }

    _enterpriseId = enterpriseId;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                  onDateSelected: (date) =>
                      setState(() => _selectedDate = date),
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
