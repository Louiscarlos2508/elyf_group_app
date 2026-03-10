import 'package:flutter/material.dart';
import '../../data/models/tour.dart';
import '../../../../core/theme/app_dimensions.dart';

class TourProgressBar extends StatelessWidget {
  final TourStatus currentStatus;
  final ValueChanged<TourStatus>? onStepTap;

  const TourProgressBar({
    super.key, 
    required this.currentStatus,
    this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppDimensions.s12,
        horizontal: AppDimensions.s8,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: TourStatus.values.map((status) {
          final isCompleted = status.index < currentStatus.index;
          final isActive = status == currentStatus;
          final isClickable = status.index <= currentStatus.index;
          
          return Expanded(
            child: InkWell(
              onTap: isClickable ? () => onStepTap?.call(status) : null,
              borderRadius: BorderRadius.circular(AppDimensions.r8),
              child: _StepIndicator(
                label: _getStatusLabel(status),
                isCompleted: isCompleted,
                isActive: isActive,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getStatusLabel(TourStatus status) {
    return switch (status) {
      TourStatus.created    => 'DEBUT',
      TourStatus.collecting => 'COLLECTE',
      TourStatus.recharging => 'RECHARGE',
      TourStatus.delivering => 'LIVRAISON',
      TourStatus.closing    => 'BILAN',
      TourStatus.closed     => 'FIN',
    };
  }
}

class _StepIndicator extends StatelessWidget {
  final String label;
  final bool isCompleted;
  final bool isActive;

  const _StepIndicator({
    required this.label,
    required this.isCompleted,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isCompleted || isActive 
        ? theme.colorScheme.primary 
        : theme.colorScheme.onSurface.withOpacity(0.3);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isActive ? 12 : 8,
          height: isActive ? 12 : 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: isActive ? [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 2,
              )
            ] : null,
          ),
        ),
        const SizedBox(height: AppDimensions.s4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.normal,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
