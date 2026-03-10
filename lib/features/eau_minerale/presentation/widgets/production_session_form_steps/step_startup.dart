import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/machine_material_usage.dart';
import '../machine_selector_field.dart';
import '../time_picker_field.dart';
import 'machine_materials_installation_section.dart';
import 'machine_material_non_finie_alert.dart';
import 'index_compteur_initial_field.dart';
import 'production_session_form_helpers.dart';

/// Étape 1 : Démarrage de production.
class StepStartup extends ConsumerWidget {
  const StepStartup({
    super.key,
    required this.isEditing,
    required this.selectedDate,
    required this.heureDebut,
    required this.machinesSelectionnees,
    required this.machineMaterials,
    required this.machinesAvecMatiereNonFinie,
    required this.indexCompteurInitialController,
    required this.onDateChanged,
    required this.onHeureDebutChanged,
    required this.onMachinesChanged,
    required this.onMaterialsChanged,
    required this.onInstallerMatiere,
    required this.onSignalerPanne,
    required this.onRetirerMatiere,
  });

  final bool isEditing;
  final DateTime selectedDate;
  final DateTime heureDebut;
  final List<String> machinesSelectionnees;
  final List<MachineMaterialUsage> machineMaterials;
  final Map<String, MachineMaterialUsage> machinesAvecMatiereNonFinie;
  final TextEditingController indexCompteurInitialController;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<DateTime> onHeureDebutChanged;
  final ValueChanged<List<String>> onMachinesChanged;
  final ValueChanged<List<MachineMaterialUsage>> onMaterialsChanged;
  final VoidCallback onInstallerMatiere;
  final void Function(BuildContext, MachineMaterialUsage, int) onSignalerPanne;
  final ValueChanged<int> onRetirerMatiere;

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      onDateChanged(picked);
    }
  }

  Widget _buildDateField(BuildContext context) {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date',
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(ProductionSessionFormHelpers.formatDate(selectedDate)),
      ),
    );
  }

  Widget _buildTimeFields(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TimePickerField(
            label: 'Heure début',
            initialTime: TimeOfDay.fromDateTime(heureDebut),
            onTimeSelected: (time) {
              onHeureDebutChanged(
                DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  time.hour,
                  time.minute,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isEditing ? 'Modifier le démarrage' : 'Démarrage de production',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          isEditing
              ? 'Modifiez les informations de démarrage de la session.'
              : 'Configurez la session de production : date, machines, matières et index initial.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        _buildDateField(context),
        const SizedBox(height: 16),
        _buildTimeFields(context),
        const SizedBox(height: 24),
        Text(
          'Machines utilisées',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        MachineSelectorField(
          machinesSelectionnees: machinesSelectionnees,
          onMachinesChanged: onMachinesChanged,
        ),
        if (machinesAvecMatiereNonFinie.isNotEmpty) ...[
          const SizedBox(height: 12),
          MachineMaterialNonFinieAlert(
            machinesAvecMatiereNonFinie: machinesAvecMatiereNonFinie,
          ),
        ],
        if (machinesSelectionnees.isEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '⚠️ Au moins une machine est obligatoire',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 24),
        Text(
          'Installation des matières',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        MachineMaterialsInstallationSection(
          machinesSelectionnees: machinesSelectionnees,
          materials: machineMaterials,
          onInstallerMatiere: onInstallerMatiere,
          onSignalerPanne: onSignalerPanne,
          onRetirerMatiere: onRetirerMatiere,
        ),
        const SizedBox(height: 24),
        Text(
          'Index compteur électrique au démarrage',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        IndexCompteurInitialField(controller: indexCompteurInitialController),
      ],
    );
  }
}
