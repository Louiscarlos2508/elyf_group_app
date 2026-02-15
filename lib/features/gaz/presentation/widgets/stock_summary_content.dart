import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../shared.dart';
import '../../application/providers.dart';
import '../../domain/entities/cylinder.dart';

class GazStockSummaryContent extends ConsumerWidget {
  const GazStockSummaryContent({
    super.key,
    required this.enterpriseId,
    this.siteId,
  });

  final String enterpriseId;
  final String? siteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(
      gazStockSummaryProvider((enterpriseId: enterpriseId, siteId: siteId)),
    );

    return summaryAsync.when(
      data: (summary) {
        if (summary.isEmpty) {
          return const Center(child: Text('Aucune donnée de stock disponible'));
        }

        final sortedWeights = summary.keys.toList()..sort();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Résumé Global du Stock',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  const DataColumn(label: Text('Poids')),
                  ...CylinderStatus.values.map(
                    (status) => DataColumn(label: Text(status.label)),
                  ),
                ],
                rows: sortedWeights.map((weight) {
                  final statusMap = summary[weight]!;
                  return DataRow(
                    cells: [
                      DataCell(Text('${weight}kg')),
                      ...CylinderStatus.values.map(
                        (status) => DataCell(Text('${statusMap[status] ?? 0}')),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
      loading: () => AppShimmers.list(context),
      error: (error, _) => Text('Erreur: $error'),
    );
  }
}
