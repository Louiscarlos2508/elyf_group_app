/// Salary payment record (fixed or production-based).
class Salary {
  const Salary({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.type,
    required this.amount,
    required this.date,
    required this.period,
    this.notes,
    this.daysWorked,
    this.dailyRate,
  });

  final String id;
  final String employeeId;
  final String employeeName;
  final SalaryType type;
  final int amount;
  final DateTime date;
  final String period;
  final String? notes;
  final int? daysWorked;
  final int? dailyRate;
}

enum SalaryType { fixed, production }

class Employee {
  const Employee({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.position,
    required this.monthlySalary,
    required this.isActive,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String position;
  final int monthlySalary;
  final bool isActive;

  String get fullName => '$firstName $lastName';
}
