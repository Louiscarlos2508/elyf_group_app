import '../../../domain/entities/sale.dart';

/// Helpers pour les calculs de prévisions.
class ForecastReportHelpers {
  ForecastReportHelpers._();

  /// Formate un montant en FCFA avec séparateurs de milliers.
  static String formatCurrency(int amount) {
    final formatted = amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
    return '$formatted FCFA';
  }

  /// Groupe les ventes par semaine.
  static List<double> groupByWeek(List<Sale> sales, DateTime startDate) {
    final weeks = <int, double>{};
    for (var i = 0; i < 4; i++) {
      weeks[i] = 0;
    }

    for (final sale in sales) {
      final daysSinceStart = sale.date.difference(startDate).inDays;
      final weekIndex = daysSinceStart ~/ 7;
      if (weekIndex >= 0 && weekIndex < 4) {
        weeks[weekIndex] = (weeks[weekIndex] ?? 0) + sale.totalPrice;
      }
    }

    return weeks.values.toList();
  }

  /// Calcule la tendance (régression linéaire simple).
  static double calculateTrend(List<double> data) {
    if (data.length < 2) return 0;

    // Simple linear regression
    final n = data.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;

    for (var i = 0; i < n; i++) {
      sumX += i;
      sumY += data[i];
      sumXY += i * data[i];
      sumX2 += i * i;
    }

    final denominator = n * sumX2 - sumX * sumX;
    if (denominator == 0) return 0;

    return (n * sumXY - sumX * sumY) / denominator;
  }

  /// Projette les semaines futures.
  static List<double> projectWeeks(double average, double trend, int weeks) {
    return List.generate(weeks, (i) {
      final projection = average + trend * (i + 1);
      return projection > 0 ? projection : 0;
    });
  }

  /// Calcule la variance.
  static double calculateVariance(List<double> data, double mean) {
    if (data.isEmpty) return 0;
    final sumSquaredDiff =
        data.fold<double>(0, (sum, x) => sum + (x - mean) * (x - mean));
    return sumSquaredDiff / data.length;
  }
}

