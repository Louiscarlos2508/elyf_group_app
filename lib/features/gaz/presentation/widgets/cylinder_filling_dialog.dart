import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared.dart';
import '../../application/providers.dart';
import '../../../../../../core/auth/providers.dart';

class CylinderFillingDialog extends ConsumerStatefulWidget {
  const CylinderFillingDialog({super.key, required this.enterpriseId});

  final String enterpriseId;

  @override
  ConsumerState<CylinderFillingDialog> createState() => _CylinderFillingDialogState();
}

class _CylinderFillingDialogState extends ConsumerState<CylinderFillingDialog> {
  final Map<int, TextEditingController> _controllers = {};
  final List<int> _commonWeights = [3, 6, 12, 38];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    for (final weight in _commonWeights) {
      _controllers[weight] = TextEditingController(text: '0');
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final quantities = <int, int>{};
    for (final entry in _controllers.entries) {
      final qty = int.tryParse(entry.value.text) ?? 0;
      if (qty > 0) quantities[entry.key] = qty;
    }

    if (quantities.isEmpty) {
      NotificationService.showError(context, 'Saisissez au moins une quantité');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final controller = ref.read(cylinderStockControllerProvider);
      final userId = ref.read(authControllerProvider).currentUser?.id ?? 'system';
      
      await controller.fillCylinders(
        enterpriseId: widget.enterpriseId,
        userId: userId,
        quantities: quantities,
      );

      if (mounted) {
        NotificationService.showSuccess(context, 'Remplissage enregistré avec succès');
        ref.invalidate(gazStocksProvider);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) NotificationService.showError(context, 'Erreur: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.gas_meter_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Remplissage de bouteilles',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Cette opération convertit vos bouteilles vides en bouteilles pleines dans le stock.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            ..._commonWeights.map((weight) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(width: 60, child: Text('$weight kg', style: const TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(
                    child: TextFormField(
                      controller: _controllers[weight],
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: '0',
                        suffixText: 'btl',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Enregistrer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
