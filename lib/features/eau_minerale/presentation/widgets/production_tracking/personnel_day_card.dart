import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/production_day.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../daily_personnel_form.dart';
import '../../../domain/entities/production_session.dart';
import 'tracking_helpers.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/utils/notification_service.dart';
/// Widget pour afficher une carte de jour de production.
class PersonnelDayCard extends ConsumerWidget {
  const PersonnelDayCard({
    super.key,
    required this.session,
    required this.day,
    required this.onDelete,
  });

  final ProductionSession session;
  final ProductionDay day;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasProduction = day.packsProduits > 0 || day.emballagesUtilises > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                '${day.nombrePersonnes}',
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(TrackingHelpers.formatDate(day.date)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${day.personnelIds.length} personne(s) • ${day.coutTotalPersonnel} CFA',
                ),
                if (hasProduction) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${day.packsProduits} packs produits • ${day.emballagesUtilises} emballages utilisés',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Production non renseignée',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!hasProduction)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: OutlinedButton.icon(
                      onPressed: () => _showPersonnelForm(context, ref, day.date, day),
                      icon: const Icon(Icons.inventory_2, size: 18),
                      label: const Text('Production'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Modifier le personnel et la production',
                    onPressed: () => _showPersonnelForm(context, ref, day.date, day),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Supprimer ce jour',
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
                ref.invalidate(productionSessionDetailProvider((session.id)));
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

