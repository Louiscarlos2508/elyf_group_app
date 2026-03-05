import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import 'package:elyf_groupe_app/app/theme/design_tokens.dart' show AppRadius;

import 'package:intl/intl.dart';

/// Daily detail card for reports screen.
class ReportDailyDetailCard extends StatelessWidget {
  const ReportDailyDetailCard({
    super.key, 
    required this.onExportPdf,
    required this.stats,
  });

  final VoidCallback onExportPdf;
  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final history = stats['dailyHistory'] != null 
        ? List<Map<String, dynamic>>.from(stats['dailyHistory'])
        : <Map<String, dynamic>>[];

    return ElyfCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      backgroundColor: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
      elevation: isDark ? 0 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Résumé par jour',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Outfit',
                ),
              ),
              OutlinedButton.icon(
                onPressed: onExportPdf,
                icon: const Icon(Icons.picture_as_pdf, size: 16),
                label: const Text('Exporter'),
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
          if (history.isEmpty)
            _buildEmptyState(theme)
          else
            _buildTable(theme, history),
        ],
      ),
    );
  }

  Widget _buildTable(ThemeData theme, List<Map<String, dynamic>> history) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2.5),
        2: FlexColumnWidth(2.5),
        3: FlexColumnWidth(2.5),
        4: FlexColumnWidth(1.5),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.1),
              ),
            ),
          ),
          children: [
            _buildHeaderCell(theme, 'Date'),
            _buildHeaderCell(theme, 'Dépôts'),
            _buildHeaderCell(theme, 'Retraits'),
            _buildHeaderCell(theme, 'Net'),
            _buildHeaderCell(theme, 'Tr.', align: TextAlign.right),
          ],
        ),
        ...history.map((day) {
          final date = day['date'] as DateTime;
          final cashIn = day['cashIn'] as int;
          final cashOut = day['cashOut'] as int;
          final net = cashIn - cashOut;
          
          return TableRow(
            children: [
              _buildDataCell(theme, DateFormat('dd/MM').format(date)),
              _buildDataCell(
                theme, 
                CurrencyFormatter.formatShort(cashIn),
                color: const Color(0xFFFF6B00),
              ),
              _buildDataCell(
                theme, 
                CurrencyFormatter.formatShort(cashOut),
                color: AppColors.danger,
              ),
              _buildDataCell(
                theme, 
                CurrencyFormatter.formatShort(net),
                color: net >= 0 ? AppColors.success : AppColors.danger,
              ),
              _buildDataCell(
                theme, 
                day['count']?.toString() ?? '0',
                align: TextAlign.right,
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildHeaderCell(ThemeData theme, String text, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.bold,
        ),
        textAlign: align,
      ),
    );
  }

  Widget _buildDataCell(ThemeData theme, String text, {Color? color, TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: color ?? theme.colorScheme.onSurface,
          fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
        ),
        textAlign: align,
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          children: [
            Icon(
              Icons.description_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Aucune donnée pour cette période',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
