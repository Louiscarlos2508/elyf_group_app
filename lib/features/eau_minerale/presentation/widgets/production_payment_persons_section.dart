import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/production_day.dart';
import '../../domain/entities/production_payment_person.dart';
import 'production_payment_person_row.dart';
import 'production_period_formatter.dart';

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
  });

  final List<ProductionPaymentPerson> persons;
  final VoidCallback onAddPerson;
  final void Function(int) onRemovePerson;
  final void Function(int, ProductionPaymentPerson) onUpdatePerson;
  final String period;
  final ValueChanged<List<ProductionPaymentPerson>> onLoadFromProduction;

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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible de parser la période. Veuillez sélectionner une période valide.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      // Filtrer les sessions de la période
      final sessionsInPeriod = sessions.where((session) {
        return session.date.isAfter(periodDates.start.subtract(const Duration(days: 1))) &&
               session.date.isBefore(periodDates.end.add(const Duration(days: 1)));
      }).toList();
      
      if (sessionsInPeriod.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucune session de production trouvée pour cette période.'),
              backgroundColor: Colors.orange,
            ),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucun personnel journalier enregistré pour cette période.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      // Récupérer tous les ouvriers
      final workers = await ref.read(allDailyWorkersProvider.future);
      final workerMap = {for (var w in workers) w.id: w};
      
      // Grouper par ouvrier et compter les jours travaillés
      final Map<String, ({int daysWorked, int pricePerDay})> workerStats = {};
      
      for (final day in productionDays) {
        for (final workerId in day.personnelIds) {
          if (workerStats.containsKey(workerId)) {
            final current = workerStats[workerId]!;
            workerStats[workerId] = (
              daysWorked: current.daysWorked + 1,
              pricePerDay: day.salaireJournalierParPersonne,
            );
          } else {
            workerStats[workerId] = (
              daysWorked: 1,
              pricePerDay: day.salaireJournalierParPersonne,
            );
          }
        }
      }
      
      // Créer la liste des personnes à payer
      final personsToPay = <ProductionPaymentPerson>[];
      for (final entry in workerStats.entries) {
        final worker = workerMap[entry.key];
        if (worker != null) {
          personsToPay.add(ProductionPaymentPerson(
            name: worker.name,
            pricePerDay: entry.value.pricePerDay,
            daysWorked: entry.value.daysWorked,
          ));
        }
      }
      
      if (personsToPay.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucun ouvrier trouvé pour cette période.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      // Trier par nom
      personsToPay.sort((a, b) => a.name.compareTo(b.name));
      
      // Appeler le callback pour mettre à jour la liste
      onLoadFromProduction(personsToPay);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${personsToPay.length} personne(s) chargée(s) depuis les sessions de production.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
                      backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
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
                      backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
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

