/// Represents a report period with start and end dates.
class ReportPeriod {
  const ReportPeriod({
    required this.startDate,
    required this.endDate,
  });

  final DateTime startDate;
  final DateTime endDate;

  bool get isValid => endDate.isAfter(startDate) || endDate.isAtSameMomentAs(startDate);
}

