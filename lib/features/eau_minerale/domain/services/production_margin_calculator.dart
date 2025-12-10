import '../entities/production_session.dart';
import '../entities/sale.dart';

/// Service pour calculer les marges des sessions de production.
class ProductionMarginCalculator {
  /// Calcule la marge d'une session de production.
  ///
  /// [session] : La session de production
  /// [ventesLiees] : Les ventes liées à cette session
  /// [prixKwh] : Prix du kWh en CFA (optionnel, pour calculer le coût électricité)
  ///
  /// Retourne un objet [ProductionMargin] avec les détails du calcul.
  static ProductionMargin calculerMarge({
    required ProductionSession session,
    required List<Sale> ventesLiees,
    double? prixKwh,
  }) {
    // Calculer les revenus totaux des ventes liées
    final revenusTotaux = ventesLiees.fold<int>(
      0,
      (sum, vente) => sum + vente.totalPrice,
    );

    // Calculer les coûts
    final coutBobines = session.coutBobines ?? 0;
    final coutElectricite = session.coutElectricite ??
        _calculerCoutElectricite(
          session.consommationCourant,
          prixKwh,
        );
    final coutTotal = coutBobines + coutElectricite;

    // Calculer la marge brute
    final margeBrute = revenusTotaux - coutTotal;

    // Calculer le pourcentage de marge
    final pourcentageMarge = revenusTotaux > 0
        ? (margeBrute / revenusTotaux) * 100
        : 0.0;

    return ProductionMargin(
      revenusTotaux: revenusTotaux,
      coutTotal: coutTotal,
      coutBobines: coutBobines,
      coutElectricite: coutElectricite,
      margeBrute: margeBrute,
      pourcentageMarge: pourcentageMarge,
      nombreVentes: ventesLiees.length,
      estRentable: margeBrute > 0,
    );
  }

  /// Calcule le coût de l'électricité.
  static int _calculerCoutElectricite(
    double consommationKwh,
    double? prixKwh,
  ) {
    if (prixKwh == null || prixKwh <= 0) return 0;
    return (consommationKwh * prixKwh).round();
  }
}

/// Résultat du calcul de marge pour une session de production.
class ProductionMargin {
  const ProductionMargin({
    required this.revenusTotaux,
    required this.coutTotal,
    required this.coutBobines,
    required this.coutElectricite,
    required this.margeBrute,
    required this.pourcentageMarge,
    required this.nombreVentes,
    required this.estRentable,
  });

  final int revenusTotaux; // Revenus totaux des ventes liées
  final int coutTotal; // Coût total (bobines + électricité)
  final int coutBobines; // Coût des bobines
  final int coutElectricite; // Coût de l'électricité
  final int margeBrute; // Marge brute (revenus - coûts)
  final double pourcentageMarge; // Pourcentage de marge (%)
  final int nombreVentes; // Nombre de ventes liées
  final bool estRentable; // Indique si la session est rentable

  /// Formate le pourcentage de marge avec 2 décimales
  String get pourcentageMargeFormate => '${pourcentageMarge.toStringAsFixed(2)}%';
}

