import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/cylinder.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';

class GazSessionOpeningDialog extends ConsumerStatefulWidget {
  const GazSessionOpeningDialog({super.key});

  @override
  ConsumerState<GazSessionOpeningDialog> createState() => _GazSessionOpeningDialogState();
}

class _GazSessionOpeningDialogState extends ConsumerState<GazSessionOpeningDialog> {
  final _cashController = TextEditingController(text: '0');
  final _mmController = TextEditingController(text: '0');
  final Map<int, TextEditingController> _fullStockControllers = {};
  final Map<int, TextEditingController> _emptyStockControllers = {};
  bool _isLoading = false;
  bool _showStockAdjustments = false;

  @override
  void dispose() {
    _cashController.dispose();
    _mmController.dispose();
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
    final stocksAsync = ref.watch(gazStocksProvider);

    // Écouter les stocks pour pré-remplir les champs une seule fois
    ref.listen(gazStocksProvider, (previous, next) {
      if (next.hasValue && (previous == null || !previous.hasValue)) {
        final stocks = next.value!;
        for (final stock in stocks) {
          if (stock.status == CylinderStatus.full) {
             _fullStockControllers[stock.weight]?.text = stock.quantity.toString();
          } else if (stock.status == CylinderStatus.emptyAtStore) {
             _emptyStockControllers[stock.weight]?.text = stock.quantity.toString();
          }
        }
      }
    });

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
          
          for (final weight in weights) {
            _fullStockControllers.putIfAbsent(weight, () => TextEditingController(text: '0'));
            _emptyStockControllers.putIfAbsent(weight, () => TextEditingController(text: '0'));
          }

          if (stocksAsync.hasValue) {
            final stocks = stocksAsync.value!;
            for (final stock in stocks) {
              if (stock.status == CylinderStatus.full) {
                 final controller = _fullStockControllers[stock.weight];
                 if (controller != null && controller.text == '0') {
                    controller.text = stock.quantity.toString();
                 }
              } else if (stock.status == CylinderStatus.emptyAtStore) {
                 final controller = _emptyStockControllers[stock.weight];
                 if (controller != null && controller.text == '0') {
                    controller.text = stock.quantity.toString();
                 }
              }
            }
          }

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Déclarez vos fonds initiaux pour démarrer la session.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                
                // Cash Initial
                TextField(
                  controller: _cashController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Fond de caisse (Espèces)',
                    prefixIcon: Icon(Icons.money),
                    suffixText: 'FCFA',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Mobile Money Initial
                TextField(
                  controller: _mmController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Solde Orange Money',
                    prefixIcon: Icon(Icons.phonelink_ring),
                    suffixText: 'FCFA',
                    border: OutlineInputBorder(),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Toggle Stock Adjustments
                InkWell(
                  onTap: () => setState(() => _showStockAdjustments = !_showStockAdjustments),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          _showStockAdjustments ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Ajuster le stock initial (optionnel)',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_showStockAdjustments) ...[
                  const SizedBox(height: 12),
                  ...weights.map((weight) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${weight}k',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
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
        FilledButton.icon(
          onPressed: _isLoading ? null : _handleOpen,
          icon: const Icon(Icons.check_circle_outline, size: 20),
          label: _isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Confirmer l\'ouverture'),
        ),
      ],
    );
  }

  Future<void> _handleOpen() async {
    setState(() => _isLoading = true);
    
    final openingCash = double.tryParse(_cashController.text) ?? 0.0;
    final openingMM = double.tryParse(_mmController.text) ?? 0.0;
    final openingFullStock = _fullStockControllers.map((k, v) => MapEntry(k, int.tryParse(v.text) ?? 0));
    final openingEmptyStock = _emptyStockControllers.map((k, v) => MapEntry(k, int.tryParse(v.text) ?? 0));
    
    final userId = ref.read(currentUserIdProvider) ?? '';
    
    try {
      await ref.read(gazSessionControllerProvider).openSession(
        userId: userId,
        openingCash: openingCash,
        openingMobileMoney: openingMM,
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
