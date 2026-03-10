import 'package:flutter/material.dart';
import '../../../../core/theme/app_dimensions.dart';

class QuantityCounter extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final String label;
  final int min;

  const QuantityCounter({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.min = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppDimensions.s8,
        horizontal: AppDimensions.s12,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppDimensions.r12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _ControlButton(
            icon: Icons.remove,
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 60),
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.s12),
            child: Text(
              value.toString(),
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          _ControlButton(
            icon: Icons.add,
            onPressed: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _ControlButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppDimensions.r8),
        child: Container(
          width: AppDimensions.touchTarget,
          height: AppDimensions.touchTarget,
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
            borderRadius: BorderRadius.circular(AppDimensions.r8),
          ),
          child: Icon(icon, color: onPressed == null ? Colors.grey : null),
        ),
      ),
    );
  }
}
