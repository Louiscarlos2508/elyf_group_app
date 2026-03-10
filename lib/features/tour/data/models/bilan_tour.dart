import 'tour.dart';

// État complet du camion (calculé en temps réel)
class TruckState {
  final Map<FormatBouteille, int> videsEnCamion;
  final Map<FormatBouteille, int> pleinesEnCamion;
  final int cashEncaisse;

  const TruckState({
    required this.videsEnCamion,
    required this.pleinesEnCamion,
    required this.cashEncaisse,
  });

  factory TruckState.empty() => const TruckState(
    videsEnCamion: {},
    pleinesEnCamion: {},
    cashEncaisse: 0,
  );

  int get totalVides  => videsEnCamion.values.fold(0, (a, b) => a + b);
  int get totalPleines => pleinesEnCamion.values.fold(0, (a, b) => a + b);
}

// Détail par site pour le bilan
class SiteBilan {
  final String siteName;
  final Map<int, int> entrees; // Poids -> Quantité (Vides collectées)
  final Map<int, int> sorties; // Poids -> Quantité (Pleines livrées)
  final double encaissement;

  const SiteBilan({
    required this.siteName,
    required this.entrees,
    required this.sorties,
    required this.encaissement,
  });

  int get totalEntrees => entrees.values.fold(0, (a, b) => a + b);
  int get totalSorties => sorties.values.fold(0, (a, b) => a + b);
}

// Bilan final
class BilanTour {
  final List<SiteBilan> siteBreakdowns;
  final int totalVidesCollectes;
  final int totalPleinesLivrees;
  final int stockResiduel;
  final int totalEncaisse;
  final int coutRecharge;
  final int totalFrais;
  
  // Données post-clôture
  final double postClosureCash; 
  final int postClosureLeaks;

  const BilanTour({
    required this.siteBreakdowns,
    required this.totalVidesCollectes,
    required this.totalPleinesLivrees,
    required this.stockResiduel,
    required this.totalEncaisse,
    required this.coutRecharge,
    required this.totalFrais,
    this.postClosureCash = 0,
    this.postClosureLeaks = 0,
  });

  int get resultatNet => (totalEncaisse + postClosureCash).toInt() - coutRecharge - totalFrais;

  BilanTour copyWith({
    List<SiteBilan>? siteBreakdowns,
    int? totalVidesCollectes,
    int? totalPleinesLivrees,
    int? stockResiduel,
    int? totalEncaisse,
    int? coutRecharge,
    int? totalFrais,
    double? postClosureCash,
    int? postClosureLeaks,
  }) {
    return BilanTour(
      siteBreakdowns: siteBreakdowns ?? this.siteBreakdowns,
      totalVidesCollectes: totalVidesCollectes ?? this.totalVidesCollectes,
      totalPleinesLivrees: totalPleinesLivrees ?? this.totalPleinesLivrees,
      stockResiduel: stockResiduel ?? this.stockResiduel,
      totalEncaisse: totalEncaisse ?? this.totalEncaisse,
      coutRecharge: coutRecharge ?? this.coutRecharge,
      totalFrais: totalFrais ?? this.totalFrais,
      postClosureCash: postClosureCash ?? this.postClosureCash,
      postClosureLeaks: postClosureLeaks ?? this.postClosureLeaks,
    );
  }
}
