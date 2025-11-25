import 'package:flutter/material.dart';

import '../../domain/entities/stock_movement.dart';

/// Dropdown for selecting stock movement type.
class StockOperationTypeSelector extends StatelessWidget {
  const StockOperationTypeSelector({
    super.key,
    required this.movementType,
    required this.onChanged,
  });

  final StockMovementType movementType;
  final ValueChanged<StockMovementType> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<StockMovementType>(
      value: movementType,
      decoration: const InputDecoration(
        labelText: 'Type d\'opération',
        prefixIcon: Icon(Icons.swap_vert),
      ),
      items: const [
        DropdownMenuItem(
          value: StockMovementType.entry,
          child: Row(
            children: [
              Icon(Icons.add_circle_outline, size: 20),
              SizedBox(width: 8),
              Text('Entrée'),
            ],
          ),
        ),
        DropdownMenuItem(
          value: StockMovementType.exit,
          child: Row(
            children: [
              Icon(Icons.remove_circle_outline, size: 20),
              SizedBox(width: 8),
              Text('Sortie'),
            ],
          ),
        ),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

