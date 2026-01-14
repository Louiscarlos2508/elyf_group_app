import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';

/// Widget affichant le résumé de la session de production.
class ProductionSessionSummaryCard extends ConsumerWidget {
  const ProductionSessionSummaryCard({
    super.key,
    required this.date,
    required this.heureDebut,
    required this.machinesCount,
    required this.bobinesCount,
    this.indexInitialKwh,
    this.indexFinalKwh,
    this.consommationText,
    required this.quantiteText,
    this.emballagesText,
    required this.formatDate,
    required this.formatTime,
  });

  final DateTime date;
  final DateTime heureDebut;
  final int machinesCount;
  final int bobinesCount;
  final double? indexInitialKwh;
  final double? indexFinalKwh;
  final String? consommationText;
  final String quantiteText;
  final String? emballagesText;
  final String Function(DateTime) formatDate;
  final String Function(DateTime) formatTime;

  Widget _buildSummaryRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meterTypeAsync = ref.watch(electricityMeterTypeProvider);

    return meterTypeAsync.when(
      data: (meterType) {
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Résumé de la session',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildSummaryRow(context, 'Date', formatDate(date)),
                _buildSummaryRow(
                  context,
                  'Heure début',
                  formatTime(heureDebut),
                ),
                _buildSummaryRow(context, 'Machines', '$machinesCount'),
                _buildSummaryRow(context, 'Bobines', '$bobinesCount'),
                if (indexInitialKwh != null)
                  _buildSummaryRow(
                    context,
                    meterType.initialLabel,
                    '$indexInitialKwh ${meterType.unit}',
                  ),
                if (indexFinalKwh != null)
                  _buildSummaryRow(
                    context,
                    meterType.finalLabel,
                    '$indexFinalKwh ${meterType.unit}',
                  ),
                if (consommationText != null && consommationText!.isNotEmpty)
                  _buildSummaryRow(
                    context,
                    'Consommation électrique',
                    '$consommationText ${meterType.unit}',
                  ),
                _buildSummaryRow(
                  context,
                  'Quantité produite',
                  '$quantiteText packs',
                ),
                if (emballagesText != null && emballagesText!.isNotEmpty)
                  _buildSummaryRow(
                    context,
                    'Emballages',
                    '$emballagesText packs',
                  ),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Erreur de chargement du type de compteur'),
        ),
      ),
    );
  }
}
