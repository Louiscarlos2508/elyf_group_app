import 'salary_payment.dart';

/// Représente un employé permanent (fixe).
/// Payé par mois avec salaire mensuel fixe.
class Employee {
  const Employee({
    required this.id,
    required this.name,
    required this.phone,
    required this.type,
    required this.monthlySalary,
    this.position,
    this.hireDate,
    this.paiementsMensuels = const [],
    this.updatedAt,
    this.createdAt,
    this.deletedAt,
    this.deletedBy,
  });

  final String id;
  final String name;
  final String phone;
  final EmployeeType type;
  final int monthlySalary; // Salaire mensuel fixe en CFA
  final String? position;
  final DateTime? hireDate;
  final List<SalaryPayment>
  paiementsMensuels; // Historique des paiements mensuels
  final DateTime? updatedAt;
  final DateTime? createdAt;
  final DateTime? deletedAt;
  final String? deletedBy;

  Employee copyWith({
    String? id,
    String? name,
    String? phone,
    EmployeeType? type,
    int? monthlySalary,
    String? position,
    DateTime? hireDate,
    List<SalaryPayment>? paiementsMensuels,
    DateTime? updatedAt,
    DateTime? createdAt,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      type: type ?? this.type,
      monthlySalary: monthlySalary ?? this.monthlySalary,
      position: position ?? this.position,
      hireDate: hireDate ?? this.hireDate,
      paiementsMensuels: paiementsMensuels ?? this.paiementsMensuels,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    final paymentsRaw = map['paiementsMensuels'] as List<dynamic>? ?? [];
    final payments = paymentsRaw
        .map((p) => SalaryPayment.fromMap(p as Map<String, dynamic>))
        .toList();

    return Employee(
      id: map['id'] as String? ?? map['localId'] as String,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      type: EmployeeType.values.byName(map['type'] as String? ?? 'fixed'),
      monthlySalary: (map['monthlySalary'] as num?)?.toInt() ?? 0,
      position: map['position'] as String?,
      hireDate: map['hireDate'] != null
          ? DateTime.parse(map['hireDate'] as String)
          : null,
      paiementsMensuels: payments,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      deletedAt: map['deletedAt'] != null
          ? DateTime.parse(map['deletedAt'] as String)
          : null,
      deletedBy: map['deletedBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'type': type.name,
      'monthlySalary': monthlySalary,
      'position': position,
      'hireDate': hireDate?.toIso8601String(),
      'paiementsMensuels': paiementsMensuels.map((p) => p.toMap()).toList(),
      'updatedAt': updatedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
    };
  }

  bool get isDeleted => deletedAt != null;
}

enum EmployeeType {
  /// Employé permanent avec salaire mensuel fixe
  fixed,

  /// Employé basé sur la production (obsolète, utiliser DailyWorker)
  @Deprecated('Utiliser DailyWorker pour les ouvriers journaliers')
  production,
}
