
/// Statistiques mensuelles pour un ouvrier journalier.
class WorkerMonthlyStat {
  const WorkerMonthlyStat({
    required this.workerId,
    required this.workerName,
    required this.daysWorked,
    required this.totalEarned,
    required this.daysPaid,
    required this.amountPaid,
    this.dailyRate,
  });

  /// ID de l'ouvrier.
  final String workerId;

  /// Nom de l'ouvrier.
  final String workerName;

  /// Nombre de jours travaillés dans le mois.
  final int daysWorked;

  /// Montant total gagné (théorique) dans le mois.
  final int totalEarned;

  /// Nombre de jours payés.
  final int daysPaid;

  /// Montant réellement payé.
  final int amountPaid;
  
  /// Salaire journalier (informatif, peut varier si changement).
  final int? dailyRate;

  /// Montant restant à payer.
  int get remainingAmount => totalEarned - amountPaid;
  
  /// Indique si tout a été payé.
  bool get isFullyPaid => remainingAmount <= 0;
}
