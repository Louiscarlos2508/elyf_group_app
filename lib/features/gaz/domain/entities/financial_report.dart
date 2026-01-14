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
    );
  }
}
