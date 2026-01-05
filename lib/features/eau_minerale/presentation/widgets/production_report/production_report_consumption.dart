import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../domain/entities/production_session.dart';
import 'production_report_components.dart';

/// Section consommation électrique du rapport.
class ProductionReportConsumption extends ConsumerWidget {
  const ProductionReportConsumption({
    super.key,
    required this.session,
  });

  final ProductionSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (session.consommationCourant <= 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final meterTypeAsync = ref.watch(electricityMeterTypeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProductionReportComponents.buildSectionTitle('Consommation', theme),
        const SizedBox(height: 16),
        meterTypeAsync.when(
          data: (meterType) => ProductionReportComponents.buildInfoItem(
            label: 'Consommation électrique',
            value: '${session.consommationCourant.toStringAsFixed(2)} ${meterType.unit}',
            icon: Icons.bolt,
            theme: theme,
          ),
          loading: () => ProductionReportComponents.buildInfoItem(
            label: 'Consommation électrique',
            value: '${session.consommationCourant.toStringAsFixed(2)}',
            icon: Icons.bolt,
            theme: theme,
          ),
          error: (_, __) => ProductionReportComponents.buildInfoItem(
            label: 'Consommation électrique',
            value: '${session.consommationCourant.toStringAsFixed(2)}',
            icon: Icons.bolt,
            theme: theme,
          ),
        ),
      ],
    );
  }
}

