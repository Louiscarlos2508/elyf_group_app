import 'package:flutter/material.dart';

import '../../../domain/entities/tour.dart';

/// Stepper du workflow du tour.
class TourWorkflowStepper extends StatelessWidget {
  const TourWorkflowStepper({
    super.key,
    required this.tour,
  });

  final Tour tour;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = [
      TourStatus.collection,
      TourStatus.transport,
      TourStatus.return_,
      TourStatus.closure,
    ];

    final currentIndex = steps.indexOf(tour.status);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isActive = index == currentIndex;
          final isPast = index < currentIndex;

          // Couleurs selon le design Figma
          final circleColor = isPast
              ? const Color(0xFF00A63E) // Vert pour complété
              : isActive
                  ? const Color(0xFF155DFC) // Bleu pour actif
                  : const Color(0xFFE5E7EB); // Gris pour inactif
          final textColor = isPast || isActive
              ? Colors.white
              : const Color(0xFF6A7282);
          // La ligne après une étape complétée doit être verte
          final lineColor = isPast
              ? const Color(0xFF00A63E) // Vert pour complété
              : const Color(0xFFE5E7EB); // Gris pour inactif

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: circleColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: textColor,
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          color: const Color(0xFF4A5565),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                if (index < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 4,
                      color: lineColor,
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

