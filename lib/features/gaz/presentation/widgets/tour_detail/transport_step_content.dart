import 'package:flutter/material.dart';

import '../../../domain/entities/tour.dart';
import 'transport/loading_unloading_fees_section.dart';
import 'transport/other_expenses_section.dart';
import 'transport/transport_step_header.dart';

/// Contenu de l'étape transport du tour.
class TransportStepContent extends StatelessWidget {
  const TransportStepContent({
    super.key,
    required this.tour,
    required this.enterpriseId,
  });

  final Tour tour;
  final String enterpriseId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.1),
          width: 1.305,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TransportStepHeader(tour: tour, enterpriseId: enterpriseId),
          const SizedBox(height: 30),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LoadingUnloadingFeesSection(tour: tour),
              const SizedBox(height: 16),
              OtherExpensesSection(tour: tour),
            ],
          ),
        ],
      ),
    );
  }
}
