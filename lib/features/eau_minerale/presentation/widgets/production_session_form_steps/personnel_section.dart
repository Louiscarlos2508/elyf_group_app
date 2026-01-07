import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/production_day.dart';
import '../../../domain/entities/production_session.dart';
import '../../../domain/entities/bobine_usage.dart';
import '../../../application/providers.dart';
import '../daily_personnel_form.dart';
import 'production_session_form_helpers.dart';

/// Section pour gérer le personnel journalier.
class PersonnelSection extends ConsumerWidget {
  const PersonnelSection({
    super.key,
    required this.productionDays,
    required this.selectedDate,
    required this.onProductionDayAdded,
    required this.onProductionDayRemoved,
    this.session,
    this.machinesSelectionnees = const [],
    this.bobinesUtilisees = const [],
  });

  final List<ProductionDay> productionDays;
  final DateTime selectedDate;
  final void Function(ProductionDay) onProductionDayAdded;
  final ValueChanged<ProductionDay> onProductionDayRemoved;
  final ProductionSession? session;
  final List<String> machinesSelectionnees;
  final List bobinesUtilisees;

  Widget _buildSectionHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Personnel journalier',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        IntrinsicWidth(
          child: OutlinedButton.icon(
            onPressed: () => _showPersonnelForm(context, selectedDate),
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('Ajouter'),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Ajoutez le personnel qui travaillera chaque jour de production',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(BuildContext context, ProductionDay day) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            '${day.nombrePersonnes}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          ProductionSessionFormHelpers.formatDate(day.date),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Text(
          '${day.nombrePersonnes} personne${day.nombrePersonnes > 1 ? 's' : ''} • ${day.coutTotalPersonnel} CFA',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, size: 20),
          onPressed: () => onProductionDayRemoved(day),
        ),
      ),
    );
  }

  Future<void> _showPersonnelForm(BuildContext context, DateTime date) async {
    final tempSession = session ??
        ProductionSession(
          id: 'temp',
          date: selectedDate,
          period: 1,
          heureDebut: selectedDate,
          consommationCourant: 0,
          machinesUtilisees: machinesSelectionnees,
          bobinesUtilisees: bobinesUtilisees.cast<BobineUsage>(),
          quantiteProduite: 0,
          quantiteProduiteUnite: 'pack',
          productionDays: productionDays,
        );

    ProductionDay? existingDay;
    try {
      existingDay = productionDays.firstWhere(
        (d) =>
            d.date.year == date.year &&
            d.date.month == date.month &&
            d.date.day == date.day,
      );
    } catch (e) {
      existingDay = null;
    }

    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: DailyPersonnelForm(
            session: tempSession,
            date: date,
            existingDay: existingDay,
            onSaved: (productionDay) {
              onProductionDayAdded(productionDay);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context),
        const SizedBox(height: 12),
        if (productionDays.isEmpty)
          _buildEmptyState(context)
        else
          ...productionDays.map((day) => _buildDayCard(context, day)),
      ],
    );
  }
}

