import 'package:flutter/material.dart';

import '../../../domain/entities/tour.dart';
import 'package:elyf_groupe_app/app/theme/app_colors.dart';

/// Stepper du workflow du tour.
class TourWorkflowStepper extends StatelessWidget {
  const TourWorkflowStepper({super.key, required this.tour});

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

          // Couleurs selon le thème
          final circleColor = isPast
              ? AppColors.success
              : isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.5);
          final textColor = isPast || isActive
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurfaceVariant;
          // La ligne après une étape complétée doit être verte
          final lineColor = isPast
              ? AppColors.success
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.3);

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: circleColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isPast
                              ? Icon(
                                  Icons.check,
                                  size: 18,
                                  color: textColor,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: textColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        step.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                          color: isActive
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (index < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: lineColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
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
