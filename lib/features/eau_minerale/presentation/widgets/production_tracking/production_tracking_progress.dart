import 'package:flutter/material.dart';

import '../../../domain/entities/production_session_status.dart';

/// Indicateur de progression pour le suivi de production.
class ProductionTrackingProgress extends StatelessWidget {
  const ProductionTrackingProgress({super.key, required this.status});

  final ProductionSessionStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = [
      _StepInfo(
        label: 'Initialisation',
        icon: Icons.create_outlined,
        description: 'Session créée',
      ),
      _StepInfo(
        label: 'Démarrage',
        icon: Icons.play_arrow,
        description: 'Production démarrée',
      ),
      _StepInfo(
        label: 'En cours',
        icon: Icons.settings,
        description: 'Machines et bobines',
      ),
      _StepInfo(
        label: 'Terminée',
        icon: Icons.check_circle,
        description: 'Production finalisée',
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stepWidth = constraints.maxWidth / steps.length;

          return Row(
            children: steps.asMap().entries.map((entry) {
              final index = entry.key;
              final stepInfo = entry.value;
              final isActive = status.isStepActive(index);
              final isCompleted = status.isStepCompleted(index);

              return SizedBox(
                width: stepWidth,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive || isCompleted
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surfaceContainerHighest,
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: isCompleted
                                ? Icon(
                                    Icons.check,
                                    size: 24,
                                    color: theme.colorScheme.onPrimary,
                                  )
                                : Icon(
                                    stepInfo.icon,
                                    size: 24,
                                    color: isActive
                                        ? theme.colorScheme.onPrimary
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          stepInfo.label,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isActive
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    if (index < steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 3,
                          margin: const EdgeInsets.only(
                            bottom: 24,
                            left: 8,
                            right: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: isCompleted
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline.withValues(
                                    alpha: 0.2,
                                  ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _StepInfo {
  const _StepInfo({
    required this.label,
    required this.icon,
    required this.description,
  });

  final String label;
  final IconData icon;
  final String description;
}
