import 'package:equatable/equatable.dart';

enum GazSalaryStatus {
  paid,
  pending,
  cancelled,
}

class GazSalaryPayment extends Equatable {
  final String id;
  final String enterpriseId;
  final String employeeId;
  final String employeeName;
  final double amount;
  final DateTime paymentDate;
  final String? period; // e.g., "Mars 2026"
  final String? notes;
  final String? treasuryOperationId;
  final GazSalaryStatus status;

  const GazSalaryPayment({
    required this.id,
    required this.enterpriseId,
    required this.employeeId,
    required this.employeeName,
    required this.amount,
    required this.paymentDate,
    this.period,
    this.notes,
    this.treasuryOperationId,
    this.status = GazSalaryStatus.paid,
  });

  @override
  List<Object?> get props => [
    id,
    enterpriseId,
    employeeId,
    employeeName,
    amount,
    paymentDate,
    period,
    notes,
    treasuryOperationId,
    status,
  ];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'amount': amount,
      'paymentDate': paymentDate.toIso8601String(),
      'period': period,
      'notes': notes,
      'treasuryOperationId': treasuryOperationId,
      'status': status.name,
    };
  }

  factory GazSalaryPayment.fromJson(Map<String, dynamic> json) {
    return GazSalaryPayment(
      id: json['id'] as String,
      enterpriseId: json['enterpriseId'] as String,
      employeeId: json['employeeId'] as String,
      employeeName: json['employeeName'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentDate: DateTime.parse(json['paymentDate'] as String),
      period: json['period'] as String?,
      notes: json['notes'] as String?,
      treasuryOperationId: json['treasuryOperationId'] as String?,
      status: GazSalaryStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => GazSalaryStatus.paid,
      ),
    );
  }
}
