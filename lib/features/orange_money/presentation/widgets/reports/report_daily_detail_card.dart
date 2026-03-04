import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import 'package:elyf_groupe_app/app/theme/design_tokens.dart' show AppRadius;

/// Daily detail card for reports screen.
class ReportDailyDetailCard extends StatelessWidget {
  const ReportDailyDetailCard({super.key, required this.onExportPdf});

  final VoidCallback onExportPdf;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ElyfCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Détail par jour',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Outfit',
                ),
              ),
              OutlinedButton.icon(
                onPressed: onExportPdf,
                icon: const Icon(Icons.picture_as_pdf, size: 16),
                label: const Text('Exporter (PDF)'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.small),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                children: [
                  Icon(
                    Icons.description,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    'Aucune transaction dans cette période',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
