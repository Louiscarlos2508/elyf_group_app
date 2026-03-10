import 'package:flutter/material.dart';

/// Un composant visuel pour sélectionner les quantités de bouteilles par poids.
/// Conçu pour être utilisé par des utilisateurs non-tech avec des gros boutons.
class VisualBottleSelector extends StatelessWidget {
  const VisualBottleSelector({
    super.key,
    required this.quantities,
    required this.availableWeights,
    required this.onChanged,
    required this.color,
    this.label,
  });

  final Map<int, int> quantities;
  final List<int> availableWeights;
  final ValueChanged<Map<int, int>> onChanged;
  final Color color;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              label!,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemCount: availableWeights.length,
          itemBuilder: (context, index) {
            final weight = availableWeights[index];
            final qty = quantities[weight] ?? 0;
            return _BottleCard(
              weight: weight,
              qty: qty,
              color: color,
              onQtyChanged: (newQty) {
                final newQuantities = Map<int, int>.from(quantities);
                if (newQty > 0) {
                  newQuantities[weight] = newQty;
                } else {
                  newQuantities.remove(weight);
                }
                onChanged(newQuantities);
              },
            );
          },
        ),
      ],
    );
  }
}

class _BottleCard extends StatelessWidget {
  const _BottleCard({
    required this.weight,
    required this.qty,
    required this.color,
    required this.onQtyChanged,
  });

  final int weight;
  final int qty;
  final Color color;
  final ValueChanged<int> onQtyChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = qty > 0;
    
    // Scale factor based on weight (standard weights: 6, 12, 19, 28, 35, 50)
    final double scale = 0.6 + (weight / 50.0) * 0.4;

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.08) : theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? color : theme.dividerColor.withOpacity(0.1),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected ? [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ] : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Visual representation of the bottle
              Transform.scale(
                scale: scale,
                child: Icon(
                  Icons.gas_meter_rounded, // Best fallback icon
                  size: 48,
                  color: isSelected ? color : theme.disabledColor.withOpacity(0.5),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${weight}kg',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? color : theme.disabledColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CircleButton(
                icon: Icons.remove,
                onPressed: qty > 0 ? () => onQtyChanged(qty - 1) : null,
                color: color,
              ),
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text(
                  qty.toString(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? color : theme.disabledColor,
                  ),
                ),
              ),
              _CircleButton(
                icon: Icons.add,
                onPressed: () => onQtyChanged(qty + 1),
                color: color,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    this.onPressed,
    required this.color,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: onPressed != null ? color : Colors.grey.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: onPressed != null ? color : Colors.grey.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}
