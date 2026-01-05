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
      child: Row(
        children: [
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
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0A0A0A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: onPeriodFilterTap,
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F3F5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.transparent,
                        width: 1.219,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedPeriodFilter ?? 'Toutes les périodes',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF0A0A0A),
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 16, color: Color(0xFF0A0A0A)),
                    SizedBox(width: 8),
                    Text(
                      'Date',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0A0A0A),
                      ),
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
                      border: Border.all(
                        color: Colors.transparent,
                        width: 1.219,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedDateFilter != null
                                ? DateFormat('dd/MM/yyyy')
                                    .format(selectedDateFilter!)
                                : '',
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
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: OutlinedButton(
                onPressed: onResetFilters,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: Color(0xFFE5E5E5),
                    width: 1.219,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                ),
                child: const Text(
                  'Réinitialiser filtres',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0A0A0A),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

