import 'package:flutter/material.dart';

import '../../../domain/entities/production_day.dart';
import '../../../domain/entities/production_session.dart';
import '../../../domain/entities/bobine_usage.dart';
import 'personnel_section.dart';
import 'production_form_fields.dart';

/// Étape 2 : Production.
///
/// Permet d'enregistrer :
/// - Quantité produite
/// - Emballages utilisés
/// - Personnel journalier
/// - Notes
class StepProduction extends StatelessWidget {
  const StepProduction({
    super.key,
    required this.quantiteController,
    required this.emballagesController,
    required this.notesController,
    required this.productionDays,
    required this.selectedDate,
    required this.onProductionDayAdded,
    required this.onProductionDayRemoved,
    this.session,
    this.machinesSelectionnees = const [],
    this.bobinesUtilisees = const [],
  });

  final TextEditingController quantiteController;
  final TextEditingController emballagesController;
  final TextEditingController notesController;
  final List<ProductionDay> productionDays;
  final DateTime selectedDate;
  final ProductionSession? session;
  final List<String> machinesSelectionnees;
  final List<BobineUsage> bobinesUtilisees;
  final void Function(ProductionDay) onProductionDayAdded;
  final ValueChanged<ProductionDay> onProductionDayRemoved;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Production',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Enregistrez les quantités produites et les emballages utilisés.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        ProductionFormFields(
          quantiteController: quantiteController,
          emballagesController: emballagesController,
          notesController: notesController,
        ),
        const SizedBox(height: 24),
        PersonnelSection(
          productionDays: productionDays,
          selectedDate: selectedDate,
          session: session,
          machinesSelectionnees: machinesSelectionnees,
          bobinesUtilisees: bobinesUtilisees,
          onProductionDayAdded: onProductionDayAdded,
          onProductionDayRemoved: onProductionDayRemoved,
        ),
      ],
    );
  }
}
