import 'package:flutter/material.dart';

import '../../../domain/entities/tour.dart';
import 'closure_details_card.dart';
import 'closure_summary_cards.dart';

/// Contenu de l'étape de clôture du tour.
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
    final totalCollected = tour.totalCollected;
    final totalExpenses = tour.totalExpenses;
    final netProfit = tour.netProfit;
    final totalBottles = tour.totalBottlesToLoad;
    final loadingFees = tour.totalLoadingFees;
    final unloadingFees = tour.totalUnloadingFees;
    final otherExpenses = tour.transportExpenses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cartes de résumé (Total encaissé, Total dépenses, Bénéfice net)
        ClosureSummaryCards(
          totalCollected: totalCollected,
          totalExpenses: totalExpenses,
          netProfit: netProfit,
          isMobile: isMobile,
        ),
        const SizedBox(height: 16),
        // Carte principale avec récapitulatif
        ClosureDetailsCard(
          tour: tour,
          totalBottles: totalBottles,
          loadingFees: loadingFees,
          unloadingFees: unloadingFees,
          otherExpenses: otherExpenses,
          totalExpenses: totalExpenses,
          enterpriseId: enterpriseId,
        ),
      ],
    );
  }
}
