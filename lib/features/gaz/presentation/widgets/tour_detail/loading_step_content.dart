import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../../domain/entities/tour.dart';

/// Contenu de l'étape Chargement du tour.
///
/// Permet de saisir les quantités de bouteilles vides à charger
/// pour les échanger chez le fournisseur.
class LoadingStepContent extends ConsumerStatefulWidget {
  const LoadingStepContent({
    super.key,
    required this.tour,
    required this.enterpriseId,
  });

  final Tour tour;
  final String enterpriseId;

  @override
  ConsumerState<LoadingStepContent> createState() => _LoadingStepContentState();
}

class _LoadingStepContentState extends ConsumerState<LoadingStepContent> {
  final Map<int, TextEditingController> _controllers = {};
  final List<int> _commonWeights = [3, 6, 12, 38];

  @override
  void initState() {
    super.initState();
    for (final weight in _commonWeights) {
      _controllers[weight] = TextEditingController(
        text: (widget.tour.emptyBottlesLoaded[weight] ?? 0).toString(),
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ElyfCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              Icon(
                Icons.upload_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bouteilles vides à charger',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Saisissez les quantités de bouteilles vides à envoyer chez le fournisseur.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          // Champs de saisie par poids
          ..._commonWeights.map((weight) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        '$weight kg',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _controllers[weight],
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '0',
                          suffixText: 'bouteilles',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          // Bouton d'enregistrement
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _saveLoading,
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Enregistrer le chargement'),
            ),
          ),
          // Résumé si déjà rempli
          if (widget.tour.emptyBottlesLoaded.isNotEmpty) ...[
            const Divider(height: 32),
            Text(
              'Total : ${widget.tour.totalBottlesToLoad} bouteilles vides chargées',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _saveLoading() async {
    final emptyBottles = <int, int>{};
    for (final entry in _controllers.entries) {
      final qty = int.tryParse(entry.value.text) ?? 0;
      if (qty > 0) {
        emptyBottles[entry.key] = qty;
      }
    }

    if (emptyBottles.isEmpty) {
      if (mounted) {
        NotificationService.showError(
          context,
          'Saisissez au moins une quantité',
        );
      }
      return;
    }

    try {
      final controller = ref.read(tourControllerProvider);
      final updatedTour = widget.tour.copyWith(
        emptyBottlesLoaded: emptyBottles,
        updatedAt: DateTime.now(),
      );
      await controller.updateTour(updatedTour);

      if (mounted) {
        NotificationService.showSuccess(
          context,
          'Chargement enregistré',
        );
        ref.invalidate(tourProvider(widget.tour.id));
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, 'Erreur: $e');
      }
    }
  }
}
