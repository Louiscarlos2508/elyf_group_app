import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/production_day.dart';
import '../../../domain/entities/production_session.dart';
import '../../../application/providers.dart';
import '../daily_personnel_form.dart';
import '../../screens/sections/production_session_detail_screen.dart' show productionSessionDetailProvider;
import 'personnel_day_card.dart';
import 'personnel_delete_dialog.dart';
import 'personnel_empty_state.dart';
import 'personnel_header.dart';
import 'personnel_total_cost.dart';
import '../../../../shared.dart';

/// Widget pour la section personnel et production journalière.
class PersonnelSection extends ConsumerWidget {
  const PersonnelSection({
    super.key,
    required this.session,
  });

  final ProductionSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PersonnelHeader(
              onAddDay: () {
                final today = DateTime.now();
                final existingForToday = session.productionDays.cast<ProductionDay?>().firstWhere(
                      (day) =>
                          day != null &&
                          day.date.year == today.year &&
                          day.date.month == today.month &&
                          day.date.day == today.day,
                      orElse: () => null,
                    );
                _showPersonnelForm(context, ref, today, existingForToday);
              },
            ),
            const SizedBox(height: 16),
            if (session.productionDays.isEmpty)
              const PersonnelEmptyState()
            else
              ...session.productionDays.map(
                (day) => PersonnelDayCard(
                  session: session,
                  day: day,
                  onDelete: () => _deleteDay(context, ref, day),
                ),
              ),
            if (session.productionDays.isNotEmpty) ...[
              const SizedBox(height: 16),
              PersonnelTotalCost(totalCost: session.coutTotalPersonnel),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _deleteDay(BuildContext context, WidgetRef ref, ProductionDay day) async {
    final confirm = await PersonnelDeleteDialog.show(context, day);

    if (confirm != true || !context.mounted) return;

    final updatedDays = List<ProductionDay>.from(session.productionDays)
      ..removeWhere((d) => d.id == day.id);

    final updatedSession = session.copyWith(productionDays: updatedDays);

    final controller = ref.read(productionSessionControllerProvider);
    await controller.updateSession(updatedSession);

    if (context.mounted) {
      ref.invalidate(productionSessionDetailProvider(session.id));
      NotificationService.showInfo(context, 'Jour de production supprimé avec succès');
    }
  }

  void _showPersonnelForm(
    BuildContext context,
    WidgetRef ref,
    DateTime date, [
    ProductionDay? existingDay,
  ]) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: DailyPersonnelForm(
            session: session,
            date: date,
            existingDay: existingDay,
            onSaved: (productionDay) async {
              final updatedDays = List<ProductionDay>.from(session.productionDays);

              if (existingDay != null) {
                final index = updatedDays.indexWhere((d) => d.id == existingDay.id);
                if (index >= 0) {
                  updatedDays[index] = productionDay;
                }
              } else {
                updatedDays.add(productionDay);
              }

              final updatedSession = session.copyWith(productionDays: updatedDays);

              final controller = ref.read(productionSessionControllerProvider);
              await controller.updateSession(updatedSession);

              if (context.mounted) {
                Navigator.of(context).pop();
                ref.invalidate(productionSessionDetailProvider(session.id));
                ref.invalidate(stockStateProvider);
                NotificationService.showInfo(context, 'Personnel enregistré avec succès');
              }
            },
          ),
        ),
      ),
    );
  }
}

