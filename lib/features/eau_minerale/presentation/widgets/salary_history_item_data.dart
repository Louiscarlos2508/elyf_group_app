/// Data class for salary history items.
class SalaryHistoryItemData {
  const SalaryHistoryItemData({
    required this.date,
    required this.amount,
    required this.type,
    required this.label,
    this.period,
  });

  final DateTime date;
  final int amount;
  final SalaryPaymentType type;
  final String label;
  final String? period;
}

enum SalaryPaymentType { monthly, production }
