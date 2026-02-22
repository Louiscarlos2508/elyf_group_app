import 'package:flutter/material.dart';

import '../../../domain/entities/tour.dart';
import 'closure_details_card.dart';
import 'closure_summary_cards.dart';

/// Contenu de l'étape de clôture du tour fournisseur.
class ClosureStepContent extends StatelessWidget {
  const ClosureStepContent({
    super.key,
    required this.tour,
    required this.enterpriseId,
    required this.isMobile,
  });

  final Tour tour;
  final String enterpriseId;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cartes de résumé
        ClosureSummaryCards(
          totalEmpty: tour.totalBottlesToLoad,
          totalFull: tour.totalBottlesReceived,
          totalExpenses: tour.totalExpenses,
          isMobile: isMobile,
        ),
        const SizedBox(height: 16),
        // Carte principale avec récapitulatif
        ClosureDetailsCard(
          tour: tour,
          totalBottles: tour.totalBottlesToLoad,
          loadingFees: tour.totalLoadingFees,
          unloadingFees: tour.totalUnloadingFees,
          exchangeFees: tour.totalExchangeFees,
          otherExpenses: tour.transportExpenses,
          totalExpenses: tour.totalExpenses,
          enterpriseId: enterpriseId,
        ),
      ],
    );
  }
}
