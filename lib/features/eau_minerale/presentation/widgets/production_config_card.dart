import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/production_period_config.dart';

/// Card for configuring production periods.
class ProductionConfigCard extends ConsumerStatefulWidget {
  const ProductionConfigCard({super.key});

  @override
  ConsumerState<ProductionConfigCard> createState() =>
      _ProductionConfigCardState();
}

class _ProductionConfigCardState extends ConsumerState<ProductionConfigCard> {
  final _controller = TextEditingController();
  final _originalValueController = TextEditingController();
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void dispose() {
    _controller.dispose();
    _originalValueController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final config = await ref
        .read(productionControllerProvider)
        .getPeriodConfig();
    final value = config.daysPerPeriod.toString();
    _controller.text = value;
    _originalValueController.text = value;
    _hasChanges = false;
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadConfig());
  }

  void _onTextChanged() {
    final hasChanges = _controller.text != _originalValueController.text;
    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  Future<void> _save() async {
    final days = int.tryParse(_controller.text);
    if (days == null || days < 1 || days > 31) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valeur invalide (1-31)')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final config = ProductionPeriodConfig(daysPerPeriod: days);
      await ref
          .read(productionControllerProvider)
          .updatePeriodConfig(config);
      if (!mounted) return;
      _originalValueController.text = _controller.text;
      setState(() {
        _isLoading = false;
        _hasChanges = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuration enregistrée')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = int.tryParse(_controller.text) ?? 10;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Configuration Production',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Paramétrez les périodes de regroupement des productions',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Période de Production (jours)',
                hintText: '10',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            Text(
              'Les productions seront regroupées par périodes de $days jours (Ex: 1-$days, ${days + 1}-${days * 2}, etc.)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: (_isLoading || !_hasChanges) ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.grey.shade800,
                  foregroundColor: Colors.white,
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save, size: 18),
                label: const Text('Enregistrer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

