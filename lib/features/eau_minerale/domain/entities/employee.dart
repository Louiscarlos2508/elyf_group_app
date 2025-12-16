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
  });

  final String id;
  final String name;
  final String phone;
  final EmployeeType type;
  final int monthlySalary; // Salaire mensuel fixe en CFA
  final String? position;
  final DateTime? hireDate;
  final List<SalaryPayment> paiementsMensuels; // Historique des paiements mensuels

  /// Vérifie si l'employé est permanent (fixe).
  bool get estPermanent => type == EmployeeType.fixed;

  /// Récupère les paiements pour un mois donné.
  List<SalaryPayment> paiementsPourMois(int annee, int mois) {
    return paiementsMensuels.where((paiement) {
      return paiement.date.year == annee && paiement.date.month == mois;
    }).toList();
  }

  /// Vérifie si le salaire a été payé pour un mois donné.
  bool salairePayePourMois(int annee, int mois) {
    return paiementsPourMois(annee, mois).isNotEmpty;
  }

  /// Calcule le total des paiements pour une année donnée.
  int totalPaiementsAnnee(int annee) {
    return paiementsMensuels
        .where((p) => p.date.year == annee)
        .fold<int>(0, (sum, p) => sum + p.amount);
  }

  factory Employee.sample(int index) {
    return Employee(
      id: 'employee-$index',
      name: 'Employé ${index + 1}',
      phone: '+22177000${100 + index}',
      type: EmployeeType.fixed, // Tous les employés samples sont permanents
      monthlySalary: 50000 + (index * 10000),
      position: index.isEven ? 'Opérateur' : 'Superviseur',
      hireDate: DateTime.now().subtract(Duration(days: 30 * (index + 1))),
    );
  }
}

enum EmployeeType {
  /// Employé permanent avec salaire mensuel fixe
  fixed,

  /// Employé basé sur la production (obsolète, utiliser DailyWorker)
  @Deprecated('Utiliser DailyWorker pour les ouvriers journaliers')
  production,
}

