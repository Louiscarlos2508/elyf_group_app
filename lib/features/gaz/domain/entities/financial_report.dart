/// Période d'un rapport financier.
enum ReportPeriod {
  daily('Journalier'),
  weekly('Hebdomadaire'),
  monthly('Mensuel');

  const ReportPeriod(this.label);
  final String label;
}

/// Statut d'un rapport financier.
enum ReportStatus {
  draft('Brouillon'),
  finalized('Finalisé');

  const ReportStatus(this.label);
  final String label;
}

/// Représente un rapport financier avec calcul du reliquat pour le siège.
class FinancialReport {
  const FinancialReport({
    required this.id,
    required this.enterpriseId,
    required this.reportDate,
    required this.period,
    required this.totalRevenue,
    required this.totalExpenses,
    required this.loadingEventExpenses,
    required this.fixedCharges,
    required this.variableCharges,
    required this.salaries,
    required this.netAmount,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.deletedBy,
  });

  final String id;
  final String enterpriseId;
  final DateTime reportDate;
  final ReportPeriod period;
  final double totalRevenue;
  final double totalExpenses;
  final double loadingEventExpenses;
  final double fixedCharges;
  final double variableCharges;
  final double salaries;
  final double netAmount; // Reliquat pour siège
  final ReportStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final String? deletedBy;

  bool get isDeleted => deletedAt != null;

  FinancialReport copyWith({
    String? id,
    String? enterpriseId,
    DateTime? reportDate,
    ReportPeriod? period,
    double? totalRevenue,
    double? totalExpenses,
    double? loadingEventExpenses,
    double? fixedCharges,
    double? variableCharges,
    double? salaries,
    double? netAmount,
    ReportStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return FinancialReport(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      reportDate: reportDate ?? this.reportDate,
      period: period ?? this.period,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      loadingEventExpenses: loadingEventExpenses ?? this.loadingEventExpenses,
      fixedCharges: fixedCharges ?? this.fixedCharges,
      variableCharges: variableCharges ?? this.variableCharges,
      salaries: salaries ?? this.salaries,
      netAmount: netAmount ?? this.netAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  factory FinancialReport.fromMap(Map<String, dynamic> map, String defaultEnterpriseId) {
    return FinancialReport(
      id: map['id'] as String? ?? map['localId'] as String,
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      reportDate: DateTime.parse(map['reportDate'] as String),
      period: ReportPeriod.values.firstWhere(
        (e) => e.name == map['period'],
        orElse: () => ReportPeriod.daily,
      ),
      totalRevenue: (map['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      totalExpenses: (map['totalExpenses'] as num?)?.toDouble() ?? 0.0,
      loadingEventExpenses: (map['loadingEventExpenses'] as num?)?.toDouble() ?? 0.0,
      fixedCharges: (map['fixedCharges'] as num?)?.toDouble() ?? 0.0,
      variableCharges: (map['variableCharges'] as num?)?.toDouble() ?? 0.0,
      salaries: (map['salaries'] as num?)?.toDouble() ?? 0.0,
      netAmount: (map['netAmount'] as num?)?.toDouble() ?? 0.0,
      status: ReportStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ReportStatus.draft,
      ),
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : null,
      deletedAt: map['deletedAt'] != null ? DateTime.parse(map['deletedAt'] as String) : null,
      deletedBy: map['deletedBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'reportDate': reportDate.toIso8601String(),
      'period': period.name,
      'totalRevenue': totalRevenue,
      'totalExpenses': totalExpenses,
      'loadingEventExpenses': loadingEventExpenses,
      'fixedCharges': fixedCharges,
      'variableCharges': variableCharges,
      'salaries': salaries,
      'netAmount': netAmount,
      'status': status.name,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
    };
  }
}
