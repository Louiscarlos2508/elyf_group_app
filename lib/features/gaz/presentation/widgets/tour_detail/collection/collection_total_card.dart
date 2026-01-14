import 'package:flutter/material.dart';

import '../../../../domain/services/gaz_calculation_service.dart';
import '../../../../domain/entities/collection.dart';

/// Carte du total général du chargement.
class CollectionTotalCard extends StatelessWidget {
  const CollectionTotalCard({super.key, required this.collections});

  final List<Collection> collections;

  @override
  Widget build(BuildContext context) {
    final totalBottlesByWeight =
        GazCalculationService.calculateTotalBottlesByWeight(collections);
    final totalBottles = GazCalculationService.calculateTotalBottles(
      collections,
    );

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.fromLTRB(17.292, 17.292, 17.292, 1.305),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEFF6FF), Color(0xFFEEF2FF)],
        ),
        border: Border.all(color: const Color(0xFF51A2FF), width: 1.305),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, size: 20, color: Color(0xFF1C398E)),
              const SizedBox(width: 8),
              const Text(
                '📊 TOTAL GÉNÉRAL DU CHARGEMENT',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C398E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          // Détails par type de bouteille
          ...totalBottlesByWeight.entries.map((entry) {
            final weight = entry.key;
            final qty = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.fromLTRB(13.295, 13.295, 13.295, 1.305),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: const Color(0xFFBEDBFF),
                  width: 1.305,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${weight}kg',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C398E),
                        ),
                      ),
                      Text(
                        '$qty',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C398E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Vides :',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF364153),
                        ),
                      ),
                      Text(
                        '$qty',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF364153),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 17),
          Container(
            padding: const EdgeInsets.only(top: 17.292),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFF51A2FF), width: 1.305),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total vides :',
                      style: TextStyle(fontSize: 16, color: Color(0xFF1E2939)),
                    ),
                    Text(
                      '$totalBottles',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E2939),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1.305),
                Container(
                  padding: const EdgeInsets.only(top: 1.305),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFF8EC5FF), width: 1.305),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL À CHARGER :',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C398E),
                        ),
                      ),
                      Text(
                        '$totalBottles',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C398E),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(7.99),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    children: [
                      Text('💡 ', style: TextStyle(fontSize: 12)),
                      Expanded(
                        child: Text(
                          'Ce total sera utilisé pour calculer les frais de chargement/déchargement',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1447E6),
                          ),
                        ),
                      ),
                    ],
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
