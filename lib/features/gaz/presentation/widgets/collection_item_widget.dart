import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../shared/utils/currency_formatter.dart';
import '../../domain/entities/collection.dart';
import '../../domain/entities/tour.dart';

/// Widget pour afficher une collecte selon le design Figma.
class CollectionItemWidget extends StatelessWidget {
  const CollectionItemWidget({
    super.key,
    required this.tour,
    required this.collection,
    this.onEdit,
  });

  final Tour tour;
  final Collection collection;
  final VoidCallback? onEdit;


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalBottles = collection.totalBottles;

    return Container(
      padding: const EdgeInsets.fromLTRB(13.295, 13.295, 13.295, 1.305),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border.all(
          color: const Color(0xFF000000).withValues(alpha: 0.1),
          width: 1.305,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête : Nom, téléphone, montant, bouton Modifier
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collection.clientName,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF0A0A0A),
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      collection.clientPhone,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4A5565),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Text(
                    CurrencyFormatter.formatDouble(collection.amountDue),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF00A63E),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onEdit ??
                        () async {
                          // TODO: Implémenter l'édition
                        },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9.99,
                        vertical: 7.99,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.edit,
                            size: 16,
                            color: Color(0xFF0A0A0A),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Modifier',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF0A0A0A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Divider
          Container(
            margin: const EdgeInsets.only(top: 8),
            height: 1.305,
            color: const Color(0xFF000000).withValues(alpha: 0.1),
          ),
          // Détails des bouteilles collectées
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bouteilles vides collectées',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF4A5565),
                  ),
                ),
                const SizedBox(height: 8),
                ...collection.emptyBottles.entries.map((entry) {
                  final weight = entry.key;
                  final qty = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${weight}kg',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF364153),
                          ),
                        ),
                        Text(
                          '$qty × ${CurrencyFormatter.formatDouble(collection.unitPrice)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF101828),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                // Total à charger
                Container(
                  padding: const EdgeInsets.fromLTRB(11.99, 9.298, 11.99, 0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    border: Border(
                      top: BorderSide(
                        color: const Color(0xFF8EC5FF),
                        width: 1.305,
                      ),
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Vides collectées :',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF364153),
                            ),
                          ),
                          Text(
                            '$totalBottles',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF364153),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 1.305),
                        padding: const EdgeInsets.only(top: 1.305),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: const Color(0xFFBEDBFF),
                              width: 1.305,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '= Total à charger :',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1C398E),
                              ),
                            ),
                            Text(
                              '$totalBottles bouteilles',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1C398E),
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
          ),
        ],
      ),
    );
  }
}
