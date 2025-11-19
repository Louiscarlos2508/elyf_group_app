/// Configuration for production periods.
class ProductionPeriodConfig {
  const ProductionPeriodConfig({required this.daysPerPeriod});

  final int daysPerPeriod;

  int getPeriodForDate(DateTime date) {
    final day = date.day;
    if (day <= daysPerPeriod) return 1;
    if (day <= daysPerPeriod * 2) return 2;
    return 3;
  }

  String getPeriodLabel(int period) {
    switch (period) {
      case 1:
        return '1-$daysPerPeriod';
      case 2:
        return '${daysPerPeriod + 1}-${daysPerPeriod * 2}';
      case 3:
        return '${daysPerPeriod * 2 + 1}-31';
      default:
        return 'Période $period';
    }
  }
}
