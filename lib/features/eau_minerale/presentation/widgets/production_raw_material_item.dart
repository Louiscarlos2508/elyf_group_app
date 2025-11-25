import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/production.dart';

/// Individual raw material item in the production form.
class ProductionRawMaterialItem extends ConsumerStatefulWidget {
  const ProductionRawMaterialItem({
    super.key,
    required this.rawMaterial,
    required this.controller,
    required this.onRemove,
    required this.getStockQuantity,
  });

  final RawMaterialUsage rawMaterial;
  final TextEditingController controller;
  final VoidCallback onRemove;
  final Future<double> Function() getStockQuantity;

  @override
  ConsumerState<ProductionRawMaterialItem> createState() =>
      _ProductionRawMaterialItemState();
}

class _ProductionRawMaterialItemState
    extends ConsumerState<ProductionRawMaterialItem> {
  double _stockQuantity = 0;

  @override
  void initState() {
    super.initState();
    _loadStock();
  }

  Future<void> _loadStock() async {
    final stock = await widget.getStockQuantity();
    if (mounted) {
      setState(() => _stockQuantity = stock);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
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
                  widget.rawMaterial.productName,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stock disponible: $_stockQuantity ${widget.rawMaterial.unit}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: TextFormField(
              controller: widget.controller,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
            onPressed: widget.onRemove,
            iconSize: 24,
          ),
        ],
      ),
    );
  }
}

