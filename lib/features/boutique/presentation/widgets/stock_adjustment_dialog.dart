import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../application/providers.dart';
import '../../domain/entities/product.dart';

class StockAdjustmentDialog extends ConsumerStatefulWidget {
  const StockAdjustmentDialog({super.key, required this.product});

  final Product product;

  @override
  ConsumerState<StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends ConsumerState<StockAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1');
  String _reason = 'Avarie';
  bool _isExit = true; // Default to stock exit (loss/damage)
  bool _isLoading = false;

  final List<String> _reasons = [
    'Avarie',
    'Perte',
    'Don',
    'Correction',
    'Echantillon',
    'Autre',
  ];

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _saveAdjustment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final qty = int.parse(_quantityController.text);
      final finalQty = _isExit ? -qty : qty;

      final controller = ref.read(storeControllerProvider);
      await controller.adjustStock(
        widget.product.id,
        finalQty,
        _reason,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      
      // Invalidate providers to refresh UI
      ref.invalidate(productsProvider);
      ref.invalidate(lowStockProductsProvider);

      final actionText = _isExit ? 'retirés du' : 'ajoutés au';
      NotificationService.showSuccess(
        context,
        '${qty.abs()} ${widget.product.name} $actionText stock (Motif: $_reason)',
      );
    } catch (e) {
      if (!mounted) return;
      NotificationService.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.inventory_2_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ajuster le stock',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.product.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  'Stock actuel: ${widget.product.stock}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Sortie'),
                  icon: Icon(Icons.remove_circle_outline),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Entrée'),
                  icon: Icon(Icons.add_circle_outline),
                ),
              ],
              selected: {_isExit},
              onSelectionChanged: (value) {
                setState(() => _isExit = value.first);
              },
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: 'Quantité',
                prefixIcon: Icon(_isExit ? Icons.trending_down : Icons.trending_up),
                suffixText: 'unités',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Requis';
                final qty = int.tryParse(v);
                if (qty == null || qty <= 0) return 'Min 1';
                if (_isExit && qty > widget.product.stock) {
                  return 'Max ${widget.product.stock}';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _reason,
              decoration: const InputDecoration(
                labelText: 'Motif de l\'ajustement',
                prefixIcon: Icon(Icons.info_outline),
              ),
              items: _reasons.map((r) => DropdownMenuItem(
                value: r,
                child: Text(r),
              )).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _reason = v);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton.icon(
          onPressed: _isLoading ? null : _saveAdjustment,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.check),
          label: const Text('Confirmer'),
          style: FilledButton.styleFrom(
            backgroundColor: _isExit ? theme.colorScheme.error : null,
          ),
        ),
      ],
    );
  }
}
