import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/cylinder.dart';

class GazSessionOpeningDialog extends ConsumerStatefulWidget {
  const GazSessionOpeningDialog({super.key});

  @override
  ConsumerState<GazSessionOpeningDialog> createState() => _GazSessionOpeningDialogState();
}

class _GazSessionOpeningDialogState extends ConsumerState<GazSessionOpeningDialog> {
  final _cashController = TextEditingController(text: '0');
  final Map<int, TextEditingController> _fullStockControllers = {};
  final Map<int, TextEditingController> _emptyStockControllers = {};
  bool _isLoading = false;

  @override
  void dispose() {
    _cashController.dispose();
    for (final controller in _fullStockControllers.values) {
      controller.dispose();
    }
    for (final controller in _emptyStockControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cylindersAsync = ref.watch(cylindersProvider);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.lock_open_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          const Text('Ouverture de Session'),
        ],
      ),
      content: cylindersAsync.when(
        data: (cylinders) {
          final weights = cylinders.map((c) => c.weight).toSet().toList()..sort();
          
          // Initialiser les controllers si nécessaire
          for (final weight in weights) {
            _fullStockControllers.putIfAbsent(weight, () => TextEditingController(text: '0'));
            _emptyStockControllers.putIfAbsent(weight, () => TextEditingController(text: '0'));
          }

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Veuillez déclarer les montants et stocks initiaux pour cette session.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                
                // Cash Initial
                TextField(
                  controller: _cashController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cash Initial (Fond de caisse)',
                    prefixIcon: Icon(Icons.money),
                    suffixText: 'FCFA',
                    border: OutlineInputBorder(),
                  ),
                ),
                
                const SizedBox(height: 24),
                const Text('Stock Initial (Bouteilles)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                
                ...weights.map((weight) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${weight}kg',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _fullStockControllers[weight],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Pleines',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _emptyStockControllers[weight],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Vides',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _handleOpen,
          child: _isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Ouvrir la Session'),
        ),
      ],
    );
  }

  Future<void> _handleOpen() async {
    setState(() => _isLoading = true);
    
    final openingCash = double.tryParse(_cashController.text) ?? 0.0;
    final openingFullStock = _fullStockControllers.map((k, v) => MapEntry(k, int.tryParse(v.text) ?? 0));
    final openingEmptyStock = _emptyStockControllers.map((k, v) => MapEntry(k, int.tryParse(v.text) ?? 0));
    
    final userId = ref.read(currentUserIdProvider) ?? '';
    
    try {
      await ref.read(gazSessionControllerProvider).openSession(
        userId: userId,
        openingCash: openingCash,
        openingFullStock: openingFullStock,
        openingEmptyStock: openingEmptyStock,
      );
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, 'Erreur lors de l\'ouverture: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
