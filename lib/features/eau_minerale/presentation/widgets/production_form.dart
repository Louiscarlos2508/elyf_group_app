import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/production.dart';
import 'production_form_header.dart';
import 'production_period_display.dart';
import 'production_raw_materials_section.dart';

/// Form for creating/editing a production batch.
class ProductionForm extends ConsumerStatefulWidget {
  const ProductionForm({super.key});

  @override
  ConsumerState<ProductionForm> createState() => ProductionFormState();
}

class ProductionFormState extends ConsumerState<ProductionForm> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  List<RawMaterialUsage> _rawMaterials = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final config = await ref.read(productionControllerProvider).getPeriodConfig();
      final production = Production(
        id: '',
        date: _selectedDate,
        quantity: int.parse(_quantityController.text),
        period: config.getPeriodForDate(_selectedDate),
        rawMaterialsUsed: _rawMaterials.isEmpty ? null : _rawMaterials,
      );

      await ref.read(productionControllerProvider).createProduction(production);

      if (!mounted) return;
      Navigator.of(context).pop();
      ref.invalidate(productionStateProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Production enregistrée')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ProductionFormHeader(),
            const SizedBox(height: 24),
            // Quantity and Date row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantité Produite (Packs) *',
                      prefixIcon: Icon(Icons.water_drop),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requis';
                      final qty = int.tryParse(v);
                      if (qty == null || qty <= 0) return 'Quantité invalide';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date *',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDate(_selectedDate),
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Period display
            ProductionPeriodDisplay(date: _selectedDate),
            const SizedBox(height: 24),
            // Raw materials section
            ProductionRawMaterialsSection(
              rawMaterials: _rawMaterials,
              onRawMaterialsChanged: (materials) {
                setState(() => _rawMaterials = materials);
              },
            ),
          ],
        ),
      ),
    );
  }
}
