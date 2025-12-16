import 'package:flutter/material.dart';

/// Shared placeholder UI for sections not implemented yet.
class SectionPlaceholder extends StatelessWidget {
  const SectionPlaceholder({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.child,
    this.onPrimaryAction,
    this.primaryActionLabel,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? child;
  final VoidCallback? onPrimaryAction;
  final String? primaryActionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width > 720;
    final content = Column(
      crossAxisAlignment: isWide
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 48, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: isWide ? TextAlign.start : TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: isWide ? TextAlign.start : TextAlign.center,
        ),
        if (!isWide && child != null) ...[const SizedBox(height: 24), child!],
        if (primaryActionLabel != null) ...[
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onPrimaryAction,
            child: Text(primaryActionLabel!),
          ),
        ],
      ],
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(child: content),
                      ),
                      if (child != null) ...[
                        const SizedBox(width: 32),
                        Expanded(
                          child: SingleChildScrollView(child: child!),
                        ),
                      ],
                    ],
                  )
                : SingleChildScrollView(child: content),
          ),
        ),
      ),
    );
  }
}
