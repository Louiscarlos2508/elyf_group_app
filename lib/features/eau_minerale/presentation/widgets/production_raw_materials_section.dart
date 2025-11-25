import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/production.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/stock_item.dart';
import 'production_raw_material_item.dart';

/// Section for selecting raw materials used in production.
class ProductionRawMaterialsSection extends ConsumerStatefulWidget {
  const ProductionRawMaterialsSection({
    super.key,
    required this.rawMaterials,
    required this.onRawMaterialsChanged,
  });

  final List<RawMaterialUsage> rawMaterials;
  final ValueChanged<List<RawMaterialUsage>> onRawMaterialsChanged;

  @override
  ConsumerState<ProductionRawMaterialsSection> createState() =>
      _ProductionRawMaterialsSectionState();
}

class _ProductionRawMaterialsSectionState
    extends ConsumerState<ProductionRawMaterialsSection> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _addRawMaterial() async {
    final products = await ref.read(productsProvider.future);
    final rawMaterials = products.where((p) => p.isRawMaterial).toList();
    final stockState = await ref.read(stockStateProvider.future);
    final stockItems = stockState.items.where((s) => s.type == StockType.rawMaterial).toList();

    if (rawMaterials.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune matière première disponible')),
      );
      return;
    }

    if (!mounted) return;
    final selected = await showDialog<Product>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Sélectionner une matière première'),
        children: rawMaterials.map((product) {
          final stockItem = stockItems.firstWhere(
            (s) => s.name == product.name,
            orElse: () => StockItem(
              id: product.id,
              name: product.name,
              quantity: 0,
              unit: product.unit,
              type: StockType.rawMaterial,
              updatedAt: DateTime.now(),
            ),
          );
          return ListTile(
            title: Text(product.name),
            subtitle: Text('Stock disponible: ${stockItem.quantity} ${stockItem.unit}'),
            onTap: () => Navigator.of(context).pop(product),
          );
        }).toList(),
      ),
    );

    if (selected != null) {
      final stockState = await ref.read(stockStateProvider.future);
      final stockItem = stockState.items.firstWhere(
        (s) => s.name == selected.name && s.type == StockType.rawMaterial,
        orElse: () => StockItem(
          id: selected.id,
          name: selected.name,
          quantity: 0,
          unit: selected.unit,
          type: StockType.rawMaterial,
          updatedAt: DateTime.now(),
        ),
      );

      final controller = TextEditingController(text: '0');
      _controllers[selected.id] = controller;
      controller.addListener(() => _updateRawMaterials());

      final updated = [
        ...widget.rawMaterials,
        RawMaterialUsage(
          productId: selected.id,
          productName: selected.name,
          quantity: 0,
          unit: selected.unit,
        ),
      ];
      widget.onRawMaterialsChanged(updated);
    }
  }

  void _removeRawMaterial(String productId) {
    _controllers[productId]?.dispose();
    _controllers.remove(productId);
    final updated = widget.rawMaterials.where((rm) => rm.productId != productId).toList();
    widget.onRawMaterialsChanged(updated);
  }

  void _updateRawMaterials() {
    final updated = widget.rawMaterials.map((rm) {
      final controller = _controllers[rm.productId];
      if (controller != null) {
        final qty = int.tryParse(controller.text) ?? 0;
        return RawMaterialUsage(
          productId: rm.productId,
          productName: rm.productName,
          quantity: qty,
          unit: rm.unit,
        );
      }
      return rm;
    }).toList();
    widget.onRawMaterialsChanged(updated);
  }

  Future<double> _getStockQuantity(String productName) async {
    final stockState = await ref.read(stockStateProvider.future);
    final stockItem = stockState.items.firstWhere(
      (s) => s.name == productName && s.type == StockType.rawMaterial,
      orElse: () => StockItem(
        id: '',
        name: productName,
        quantity: 0,
        unit: 'kg',
        type: StockType.rawMaterial,
        updatedAt: DateTime.now(),
      ),
    );
    return stockItem.quantity;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Matières Premières Utilisées (optionnel)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sélectionnez les matières premières consommées pour cette production',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        ...widget.rawMaterials.map((rm) {
          if (!_controllers.containsKey(rm.productId)) {
            final controller = TextEditingController(text: rm.quantity.toString());
            _controllers[rm.productId] = controller;
            controller.addListener(_updateRawMaterials);
          }
          return ProductionRawMaterialItem(
            rawMaterial: rm,
            controller: _controllers[rm.productId]!,
            onRemove: () => _removeRawMaterial(rm.productId),
            getStockQuantity: () => _getStockQuantity(rm.productName),
          );
        }).toList(),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _addRawMaterial,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Ajouter une matière première'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }
}

