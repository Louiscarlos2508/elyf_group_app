import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../../application/providers.dart';
import '../../../domain/entities/cylinder.dart';

class StockAlertThresholdDialog extends ConsumerStatefulWidget {
  const StockAlertThresholdDialog({
    super.key,
    required this.cylinder,
  });

  final Cylinder cylinder;

  @override
  ConsumerState<StockAlertThresholdDialog> createState() => _StockAlertThresholdDialogState();
}

class _StockAlertThresholdDialogState extends ConsumerState<StockAlertThresholdDialog> {
  final _formKey = GlobalKey<FormState>();
  final _thresholdController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentThreshold();
  }

  Future<void> _loadCurrentThreshold() async {
    final settings = await ref.read(gazSettingsControllerProvider).getSettings(
      enterpriseId: widget.cylinder.enterpriseId,
      moduleId: 'gaz',
    );
    if (settings != null && mounted) {
      final threshold = settings.getLowStockThreshold(widget.cylinder.weight);
      if (threshold > 0) {
        _thresholdController.text = threshold.toString();
      }
    }
  }

  @override
  void dispose() {
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _saveThreshold() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final threshold = int.tryParse(_thresholdController.text) ?? 0;
      await ref.read(gazSettingsControllerProvider).setLowStockThreshold(
        enterpriseId: widget.cylinder.enterpriseId,
        moduleId: 'gaz',
        weight: widget.cylinder.weight,
        threshold: threshold,
      );

      if (mounted) {
        ref.invalidate(gazSettingsProvider);
        Navigator.of(context).pop();
        NotificationService.showSuccess(context, 'Seuil d\'alerte mis à jour');
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, 'Erreur: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.notification_important_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Alerte Stock Bas (${widget.cylinder.weight}kg)',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Définissez le niveau de stock en dessous duquel vous souhaitez être alerté.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _thresholdController,
                  decoration: InputDecoration(
                    labelText: "Seuil d'alerte",
                    hintText: 'Ex: 5',
                    suffixText: 'Bouteilles',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.withAlpha(10),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Requis';
                    final val = int.tryParse(value);
                    if (val == null || val < 0) return 'Invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElyfButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      variant: ElyfButtonVariant.text,
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 8),
                    ElyfButton(
                      onPressed: _isLoading ? null : _saveThreshold,
                      isLoading: _isLoading,
                      child: const Text('Enregistrer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
