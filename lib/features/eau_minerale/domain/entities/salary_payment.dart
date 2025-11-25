/// Represents a salary payment record.
class SalaryPayment {
  const SalaryPayment({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.amount,
    required this.date,
    required this.period,
    this.notes,
  });

  final String id;
  final String employeeId;
  final String employeeName;
  final int amount;
  final DateTime date;
  final String period;
  final String? notes;
}

