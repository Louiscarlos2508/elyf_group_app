import 'package:flutter/material.dart';
import 'elyf_ui/atoms/elyf_icon_button.dart';

/// En-tête générique pour les dialogs de formulaire.
class FormDialogHeader extends StatelessWidget {
  const FormDialogHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 24,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        ElyfIconButton(
          icon: Icons.close,
          onPressed: () => Navigator.of(context).pop(),
          iconColor: theme.colorScheme.onSurfaceVariant,
          useGlassEffect: false,
          iconSize: 20,
          size: 36,
        ),
      ],
    );
  }
}
