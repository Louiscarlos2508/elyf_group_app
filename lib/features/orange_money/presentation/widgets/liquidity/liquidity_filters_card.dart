import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget de filtres pour l'historique des pointages.
class LiquidityFiltersCard extends StatelessWidget {
  const LiquidityFiltersCard({
    super.key,
    required this.selectedPeriodFilter,
    required this.selectedDateFilter,
    required this.onPeriodFilterTap,
    required this.onDateFilterTap,
    required this.onResetFilters,
  });

  final String? selectedPeriodFilter;
  final DateTime? selectedDateFilter;
  final VoidCallback onPeriodFilterTap;
  final VoidCallback onDateFilterTap;
  final VoidCallback onResetFilters;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filtre Période
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Color(0xFF0A0A0A)),
                        SizedBox(width: 8),
                        Text(
                          'Période',
                          style: TextStyle(fontSize: 14, color: Color(0xFF0A0A0A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: onPeriodFilterTap,
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F3F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                selectedPeriodFilter ?? 'Toutes',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF0A0A0A),
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_drop_down,
                              size: 16,
                              color: Color(0xFF0A0A0A),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Filtre Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Color(0xFF0A0A0A),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Date',
                          style: TextStyle(fontSize: 14, color: Color(0xFF0A0A0A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: onDateFilterTap,
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F3F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                selectedDateFilter != null
                                    ? DateFormat('dd/MM/yyyy').format(selectedDateFilter!)
                                    : 'Aujourd\'hui',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF0A0A0A),
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Color(0xFF717182),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Bouton Réinitialiser (en pleine largeur en dessous pour éviter le overflow)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onResetFilters,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text(
                'Réinitialiser les filtres',
                style: TextStyle(fontSize: 14, color: Color(0xFF0A0A0A)),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                  color: Color(0xFFE5E5E5),
                  width: 1.219,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
