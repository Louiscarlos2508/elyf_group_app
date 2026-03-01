import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/production_day.dart';
import '../../../domain/entities/production_session.dart';
import '../../../domain/entities/bobine_usage.dart';
import '../machine_selector_field.dart';
import 'bobines_installation_section.dart';
import 'bobine_non_finie_alert.dart';
import 'personnel_section.dart';
import 'production_form_fields.dart';

/// Étape 2 : Production (Tableau de bord).
class StepProduction extends ConsumerWidget {
  const StepProduction({
    super.key,
    required this.quantiteController,
    required this.emballagesController,
    required this.notesController,
    required this.productionDays,
    required this.selectedDate,
    required this.onProductionDayAdded,
    required this.onProductionDayRemoved,
    required this.machinesSelectionnees,
    required this.bobinesUtilisees,
    required this.machinesAvecBobineNonFinie,
    required this.onMachinesChanged,
    required this.onBobinesChanged,
    required this.onInstallerBobine,
    required this.onSignalerPanne,
    required this.onRetirerBobine,
    this.session,
  });

  final TextEditingController quantiteController;
  final TextEditingController emballagesController;
  final TextEditingController notesController;
  final List<ProductionDay> productionDays;
  final DateTime selectedDate;
  final ProductionSession? session;
  final List<String> machinesSelectionnees;
  final List<BobineUsage> bobinesUtilisees;
  final Map<String, BobineUsage> machinesAvecBobineNonFinie;
  final void Function(ProductionDay) onProductionDayAdded;
  final ValueChanged<ProductionDay> onProductionDayRemoved;
  final ValueChanged<List<String>> onMachinesChanged;
  final ValueChanged<List<BobineUsage>> onBobinesChanged;
  final VoidCallback onInstallerBobine;
  final void Function(BuildContext, BobineUsage, int) onSignalerPanne;
  final ValueChanged<int> onRetirerBobine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle(context, 'Tableau de Bord Production', Icons.dashboard),
        const SizedBox(height: 24),
        
        // 1. Machines et Bobines (Cœur technique)
        _buildCard(
          context,
          title: 'Machines et Bobines',
          icon: Icons.precision_manufacturing,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MachineSelectorField(
                machinesSelectionnees: machinesSelectionnees,
                onMachinesChanged: onMachinesChanged,
              ),
              if (machinesAvecBobineNonFinie.isNotEmpty) ...[
                const SizedBox(height: 12),
                BobineNonFinieAlert(
                  machinesAvecBobineNonFinie: machinesAvecBobineNonFinie,
                ),
              ],
              const SizedBox(height: 24),
              BobinesInstallationSection(
                machinesSelectionnees: machinesSelectionnees,
                bobinesUtilisees: bobinesUtilisees,
                onInstallerBobine: onInstallerBobine,
                onSignalerPanne: onSignalerPanne,
                onRetirerBobine: onRetirerBobine,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 2. Production (Données)
        _buildCard(
          context,
          title: 'Saisie Production',
          icon: Icons.edit_document,
          child: ProductionFormFields(
            quantiteController: quantiteController,
            emballagesController: emballagesController,
            notesController: notesController,
          ),
        ),
        const SizedBox(height: 24),

        // 3. Personnel (Écurie)
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

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.secondary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
