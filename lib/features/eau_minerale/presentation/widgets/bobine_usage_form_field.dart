import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/bobine_stock.dart';
import '../../domain/entities/bobine_usage.dart';
import '../../domain/entities/machine.dart';
import 'bobine_usage_item_form.dart';
import 'form_dialog.dart';
import 'machine_selector_field.dart' show machinesProvider;

/// Champ pour gérer les bobines utilisées dans une session.
class BobineUsageFormField extends ConsumerWidget {
  const BobineUsageFormField({
    super.key,
    required this.bobinesUtilisees,
    required this.machinesDisponibles,
    required this.onBobinesChanged,
  });

  final List<BobineUsage> bobinesUtilisees;
  final List<String> machinesDisponibles;
  final ValueChanged<List<BobineUsage>> onBobinesChanged;

  Future<void> _ajouterBobine(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final bobineStocks = await ref.read(bobineStocksDisponiblesProvider.future);
    final machines = await ref.read(machinesProvider.future);
    
    // Filtrer les machines qui ont déjà une bobine
    final machinesAvecBobine = bobinesUtilisees.map((u) => u.machineId).toSet();
    final machinesDisponiblesFiltrees = machines
        .where((m) => machinesDisponibles.contains(m.id))
        .where((m) => !machinesAvecBobine.contains(m.id))
        .toList();
    
    if (machinesDisponiblesFiltrees.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Toutes les machines ont déjà une bobine'),
        ),
      );
      return;
    }

    if (bobineStocks.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune bobine disponible en stock'),
        ),
      );
      return;
    }

    if (!context.mounted) return;
    final result = await showDialog<BobineUsage>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: BobineUsageItemForm(
            bobineStocksDisponibles: bobineStocks,
            machinesDisponibles: machinesDisponiblesFiltrees,
          ),
        ),
      ),
    );

    if (result != null) {
      final nouvellesBobines = List<BobineUsage>.from(bobinesUtilisees);
      nouvellesBobines.add(result);
      onBobinesChanged(nouvellesBobines);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Bobines utilisées',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _ajouterBobine(context, ref),
              tooltip: 'Ajouter bobine',
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (bobinesUtilisees.isEmpty)
          const Text('Aucune bobine ajoutée')
        else
          ...bobinesUtilisees.asMap().entries.map((entry) {
            final index = entry.key;
            final bobine = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(bobine.bobineType),
                subtitle: Text(
                  'Machine: ${bobine.machineName}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    final nouvellesBobines =
                        List<BobineUsage>.from(bobinesUtilisees);
                    nouvellesBobines.removeAt(index);
                    onBobinesChanged(nouvellesBobines);
                  },
                ),
              ),
            );
          }),
      ],
    );
  }
}

/// Provider pour récupérer les stocks de bobines disponibles (nouveau système par type/quantité).
final bobineStocksDisponiblesProvider = FutureProvider.autoDispose<List<BobineStock>>(
  (ref) async {
    final stocks = await ref.read(bobineStockQuantityRepositoryProvider).fetchAll();
    // Filtrer seulement les stocks avec quantité > 0
    return stocks.where((stock) => stock.quantity > 0).toList();
  },
);

