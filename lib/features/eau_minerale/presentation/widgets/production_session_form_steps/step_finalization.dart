import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../production_session_form/production_session_summary_card.dart';
import 'index_compteur_final_field.dart';
import 'consommation_field.dart';
import 'production_session_form_helpers.dart';

/// Étape 3 : Finalisation.
/// 
/// Permet d'enregistrer :
/// - Index compteur final
/// - Consommation électrique
/// - Affiche un résumé de la session
class StepFinalization extends ConsumerWidget {
  const StepFinalization({
    super.key,
    required this.selectedDate,
    required this.heureDebut,
    required this.machinesCount,
    required this.bobinesCount,
    required this.indexCompteurInitialController,
    required this.indexCompteurFinalController,
    required this.consommationController,
    required this.quantiteController,
    required this.emballagesController,
  });

  final DateTime selectedDate;
  final DateTime heureDebut;
  final int machinesCount;
  final int bobinesCount;
  final TextEditingController indexCompteurInitialController;
  final TextEditingController indexCompteurFinalController;
  final TextEditingController consommationController;
  final TextEditingController quantiteController;
  final TextEditingController emballagesController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Finalisation',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enregistrez les index finaux et la consommation pour finaliser la session.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 24),
        IndexCompteurFinalField(
          indexCompteurInitialController: indexCompteurInitialController,
          indexCompteurFinalController: indexCompteurFinalController,
          consommationController: consommationController,
        ),
        const SizedBox(height: 16),
        ConsommationField(
          controller: consommationController,
        ),
        const SizedBox(height: 24),
        ProductionSessionSummaryCard(
          date: selectedDate,
          heureDebut: heureDebut,
          machinesCount: machinesCount,
          bobinesCount: bobinesCount,
          indexInitialKwh: double.tryParse(indexCompteurInitialController.text),
          indexFinalKwh: double.tryParse(indexCompteurFinalController.text),
          consommationText: consommationController.text.isEmpty
              ? null
              : consommationController.text,
          quantiteText: quantiteController.text.isEmpty
              ? '0'
              : quantiteController.text,
          emballagesText: emballagesController.text.isEmpty
              ? null
              : emballagesController.text,
          formatDate: ProductionSessionFormHelpers.formatDate,
          formatTime: ProductionSessionFormHelpers.formatTime,
        ),
      ],
    );
  }
}

