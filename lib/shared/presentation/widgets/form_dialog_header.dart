import 'package:flutter/material.dart';

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
    final textGray = const Color(0xFF717182);

    return Row(
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 24,
            color: const Color(0xFF0A0A0A),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: const Color(0xFF0A0A0A),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: textGray,
                  ),
                ),
              ],
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 16),
          onPressed: () => Navigator.of(context).pop(),
          color: const Color(0xFF0A0A0A).withValues(alpha: 0.7),
        ),
      ],
    );
  }
}

