
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import '../../application/providers.dart';
import '../../domain/entities/closing.dart';
import '../../../../core/pdf/boutique_report_pdf_service.dart';

class ClosingsReportContentV2 extends ConsumerWidget {
  const ClosingsReportContentV2({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  final DateTime startDate;
  final DateTime endDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final closingsAsync = ref.watch(closingsProvider);
    final theme = Theme.of(context);

    return closingsAsync.when(
      data: (allClosings) {
        final filteredClosings = allClosings.where((c) {
          return c.date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
              c.date.isBefore(endDate.add(const Duration(seconds: 1)));
        }).toList();

        if (filteredClosings.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: EmptyState(
                icon: Icons.lock_clock_outlined,
                title: 'Aucune clôture',
                message: 'Aucun bilan de clôture trouvé pour cette période.',
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bilans de Clôture (Z-Reports)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredClosings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final closing = filteredClosings[index];
                return _buildClosingCard(context, closing);
              },
            ),
          ],
        );
      },
      loading: () => AppShimmers.list(context),
      error: (e, _) => ErrorDisplayWidget(error: e),
    );
  }

  Widget _buildClosingCard(BuildContext context, Closing closing) {
    final theme = Theme.of(context);
    final isDiscrepancy = closing.discrepancy != 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDiscrepancy ? Colors.red.withValues(alpha: 0.3) : theme.colorScheme.outlineVariant,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isDiscrepancy ? Colors.red : Colors.green).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDiscrepancy ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                  color: isDiscrepancy ? Colors.red : Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${closing.number ?? "Session"} du ${DateFormat('dd MMMM yyyy').format(closing.date)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Heure: ${DateFormat('HH:mm').format(closing.date)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PrintZReportButton(closing: closing),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                onPressed: () async {
                  try {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Génération du Z-Report PDF...')),
                    );
                    final file = await BoutiqueReportPdfService.instance.generateZReport(closing: closing);
                    final result = await OpenFile.open(file.path);
                    if (result.type != ResultType.done && context.mounted) {
                       NotificationService.showInfo(
                        context, 
                        'PDF généré: ${file.path}',
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      NotificationService.showError(context, 'Erreur PDF: $e');
                    }
                  }
                },
                tooltip: 'Télécharger le Z-Report',
              ),
              if (isDiscrepancy) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Écart: ${CurrencyFormatter.formatFCFA(closing.discrepancy)}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetric('Espèces Digital', closing.digitalCashRevenue - closing.digitalExpenses, theme),
              _buildMetric('Espèces Phys.', closing.physicalCashAmount, theme),
              _buildMetric('Écart Esp.', closing.cashDiscrepancy, theme, isError: closing.cashDiscrepancy != 0),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetric('MM Digital', closing.digitalMobileMoneyRevenue, theme),
              _buildMetric('MM Phys. (Solde)', closing.physicalMobileMoneyAmount, theme),
              _buildMetric('Écart MM', closing.mobileMoneyDiscrepancy, theme, isError: closing.mobileMoneyDiscrepancy != 0),
            ],
          ),
          if (closing.notes != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Note: ${closing.notes}',
                style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetric(String label, int value, ThemeData theme, {bool isError = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isError ? Colors.red : theme.colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
        Text(
          CurrencyFormatter.formatFCFA(value),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isError ? Colors.red : null,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
