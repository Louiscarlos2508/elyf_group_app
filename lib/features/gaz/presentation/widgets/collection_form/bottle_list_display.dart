import 'package:flutter/material.dart';

/// Affichage de la liste des bouteilles collectées avec résumé.
class BottleListDisplay extends StatelessWidget {
  const BottleListDisplay({
    super.key,
    required this.bottles,
    required this.onRemove,
  });

  final Map<int, int> bottles; // poids -> quantité
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final totalBottles = bottles.values.fold<int>(0, (sum, qty) => sum + qty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (bottles.isNotEmpty) ...[
          ...bottles.entries.map(
            (entry) => _BottleItem(
              weight: entry.key,
              quantity: entry.value,
              onRemove: () => onRemove(entry.key),
            ),
          ),
          const SizedBox(height: 8),
          // Résumé
          _SummaryBox(totalBottles: totalBottles),
        ],
      ],
    );
  }
}

class _BottleItem extends StatelessWidget {
  const _BottleItem({
    required this.weight,
    required this.quantity,
    required this.onRemove,
  });

  final int weight;
  final int quantity;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$quantity × ${weight}kg',
            style: const TextStyle(fontSize: 14, color: Color(0xFF0A0A0A)),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            color: const Color(0xFF0A0A0A),
          ),
        ],
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  const _SummaryBox({required this.totalBottles});

  final int totalBottles;

  @override
  Widget build(BuildContext context) {
    final blueBg = const Color(0xFFEFF6FF);
    final blueBorder = const Color(0xFF8EC5FF);
    final blueText = const Color(0xFF1C398E);

    return Container(
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 1),
      decoration: BoxDecoration(
        color: blueBg,
        border: Border.all(color: blueBorder, width: 1.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📦 Chargement total',
            style: TextStyle(fontSize: 14, color: blueText),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Vides collectées :',
                style: TextStyle(fontSize: 14, color: Color(0xFF364153)),
              ),
              Text(
                '$totalBottles',
                style: const TextStyle(fontSize: 14, color: Color(0xFF0A0A0A)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.only(top: 9),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: blueBorder, width: 1.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total à charger :',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: blueText,
                  ),
                ),
                Text(
                  '$totalBottles bouteilles',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: blueText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
