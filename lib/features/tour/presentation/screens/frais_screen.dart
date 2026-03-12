import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../application/tour_notifier.dart';
import '../../data/models/frais_entry.dart';

class FraisScreen extends ConsumerWidget {
  final String tourId;

  const FraisScreen({super.key, required this.tourId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(tourNotifierProvider(tourId)).value;

    if (state == null) return const Center(child: CircularProgressIndicator());

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppDimensions.s16),
              child: Text(
                'Dépenses du Trajet',
                style: theme.textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.s16),
                itemCount: state.frais.length,
                itemBuilder: (context, index) {
                  final frais = state.frais[index];
                  return Card(
                    child: ListTile(
                      leading: Text(frais.categorie.icon, style: const TextStyle(fontSize: 24)),
                      title: Text(frais.categorie.label),
                      subtitle: Text(Formatters.formatDateTime(frais.timestamp)),
                      trailing: Text(
                        Formatters.formatCurrency(frais.montant),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onLongPress: () => ref.read(tourNotifierProvider(tourId).notifier).deleteFrais(frais.id),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: () => _showAddFrais(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('NOUVELLE DÉPENSE'),
          ),
        ),
      ],
    );
  }

  void _showAddFrais(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _AddFraisSheet(onAdd: (frais) {
        ref.read(tourNotifierProvider(tourId).notifier).addFrais(frais);
      }),
    );
  }
}

class _AddFraisSheet extends StatefulWidget {
  final ValueChanged<FraisEntry> onAdd;
  const _AddFraisSheet({required this.onAdd});

  @override
  State<_AddFraisSheet> createState() => _AddFraisSheetState();
}

class _AddFraisSheetState extends State<_AddFraisSheet> {
  CategorieFrais _selectedCat = CategorieFrais.carburant;
  final _amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Nouvelle Dépense', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<CategorieFrais>(
              initialValue: _selectedCat,
              items: CategorieFrais.values.map((c) => DropdownMenuItem(value: c, child: Text('${c.icon} ${c.label}'))).toList(),
              onChanged: (v) => setState(() => _selectedCat = v!),
              decoration: const InputDecoration(labelText: 'Catégorie'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Montant (FCFA)', prefixIcon: Icon(Icons.money)),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                final amount = int.tryParse(_amountController.text) ?? 0;
                if (amount > 0) {
                  widget.onAdd(FraisEntry(
                    id: const Uuid().v4(),
                    categorie: _selectedCat,
                    montant: amount,
                    timestamp: DateTime.now(),
                  ));
                  Navigator.pop(context);
                }
              },
              child: const Text('AJOUTER'),
            ),
          ],
        ),
      ),
    );
  }
}
