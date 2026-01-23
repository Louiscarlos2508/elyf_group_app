import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/production_day.dart';
import '../../domain/entities/production_payment_person.dart';
import 'production_payment_person_row.dart';
import 'production_period_formatter.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/utils/notification_service.dart';

/// Section for managing persons to pay in production payment.
class ProductionPaymentPersonsSection extends ConsumerWidget {
  const ProductionPaymentPersonsSection({
    super.key,
    required this.persons,
    required this.onAddPerson,
    required this.onRemovePerson,
    required this.onUpdatePerson,
    required this.period,
    required this.onLoadFromProduction,
    this.onSourceDaysLoaded,
  });

  final List<ProductionPaymentPerson> persons;
  final VoidCallback onAddPerson;
  final void Function(int) onRemovePerson;
  final void Function(int, ProductionPaymentPerson) onUpdatePerson;
  final String period;
  final ValueChanged<List<ProductionPaymentPerson>> onLoadFromProduction;
  final ValueChanged<List<String>>? onSourceDaysLoaded;

  Future<void> _loadFromProduction(BuildContext context, WidgetRef ref) async {
    try {
      // Récupérer les sessions de production
      final sessions = await ref.read(productionSessionsStateProvider.future);

      // Récupérer la période pour déterminer les dates
      final config = await ref.read(productionPeriodConfigProvider.future);
      final formatter = ProductionPeriodFormatter(config);
      final periodDates = formatter.parsePeriod(period);

      if (periodDates == null) {
        if (context.mounted) {
          NotificationService.showWarning(
            context,
            'Impossible de parser la période. Veuillez sélectionner une période valide.',
          );
        }
        return;
      }

      // Filtrer les sessions de la période
      final sessionsInPeriod = sessions.where((session) {
        return session.date.isAfter(
              periodDates.start.subtract(const Duration(days: 1)),
            ) &&
            session.date.isBefore(periodDates.end.add(const Duration(days: 1)));
      }).toList();

      if (sessionsInPeriod.isEmpty) {
        if (context.mounted) {
          NotificationService.showWarning(
            context,
            'Aucune session de production trouvée pour cette période.',
          );
        }
        return;
      }

      // Extraire tous les ProductionDay
      final productionDays = <ProductionDay>[];
      for (final session in sessionsInPeriod) {
        productionDays.addAll(session.productionDays);
      }

      if (productionDays.isEmpty) {
        if (context.mounted) {
          NotificationService.showWarning(
            context,
            'Aucun personnel journalier enregistré pour cette période.',
          );
        }
        return;
      }

      // Récupérer tous les ouvriers
      final workers = await ref.read(allDailyWorkersProvider.future);
      final workerMap = {for (var w in workers) w.id: w};

      // Grouper par ouvrier et compter les jours travaillés
      final Map<String, int> workerDays = {};

      for (final day in productionDays) {
        for (final workerId in day.personnelIds) {
          workerDays[workerId] = (workerDays[workerId] ?? 0) + 1;
        }
      }

      // Créer la liste des personnes à payer (salaire = taux de l’ouvrier)
      final personsToPay = <ProductionPaymentPerson>[];
      for (final entry in workerDays.entries) {
        final worker = workerMap[entry.key];
        if (worker != null) {
          personsToPay.add(
            ProductionPaymentPerson(
              name: worker.name,
              pricePerDay: worker.salaireJournalier,
              daysWorked: entry.value,
            ),
          );
        }
      }

      if (personsToPay.isEmpty) {
        if (context.mounted) {
          NotificationService.showWarning(
            context,
            'Aucun ouvrier trouvé pour cette période.',
          );
        }
        return;
      }

      // Trier par nom
      personsToPay.sort((a, b) => a.name.compareTo(b.name));

      // Collecter les IDs des jours de production sources
      final sourceDayIds = productionDays.map((day) => day.id).toList();

      // Appeler le callback pour mettre à jour la liste
      onLoadFromProduction(personsToPay);
      
      // Passer les IDs des jours sources si le callback est fourni
      onSourceDaysLoaded?.call(sourceDayIds);

      if (context.mounted) {
        NotificationService.showSuccess(
          context,
          '${personsToPay.length} personne(s) chargée(s) depuis les sessions de production.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        NotificationService.showError(context, 'Erreur lors du chargement: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;

            if (isWide) {
              // Disposition horizontale pour les grands écrans
              return Row(
                children: [
                  Expanded(
                    child: Text(
                      'Personnes à Payer *',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _loadFromProduction(context, ref),
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Charger depuis production'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primaryContainer
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onAddPerson,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nouvelle personne'),
                  ),
                ],
              );
            } else {
              // Disposition verticale pour les petits écrans
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Personnes à Payer *',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _loadFromProduction(context, ref),
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Charger depuis production'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primaryContainer
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: onAddPerson,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nouvelle personne'),
                  ),
                ],
              );
            }
          },
        ),
        const SizedBox(height: 16),
        if (persons.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'Ajoutez des personnes à payer',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 500),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: persons.length,
              itemBuilder: (context, index) {
                return ProductionPaymentPersonRow(
                  person: persons[index],
                  onChanged: (person) => onUpdatePerson(index, person),
                  onRemove: () => onRemovePerson(index),
                );
              },
            ),
          ),
        if (persons.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${persons.length} personne(s)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
