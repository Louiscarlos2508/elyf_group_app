/// Représente un jour de travail d'un ouvrier journalier.
class WorkDay {
  const WorkDay({
    required this.date,
    required this.productionId,
    required this.salaireJournalier,
  });

  final DateTime date;
  final String productionId; // ID de la production
  final int salaireJournalier; // Salaire journalier en CFA
}

/// Représente un ouvrier journalier ou temporaire.
/// Payé par semaine : salaire = nombre de jours travaillés × salaire journalier.
class DailyWorker {
  const DailyWorker({
    required this.id,
    required this.name,
    required this.phone,
    required this.salaireJournalier,
    this.joursTravailles = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String phone;
  final int salaireJournalier; // Salaire journalier en CFA
  final List<WorkDay> joursTravailles; // Jours travaillés (par semaine)
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Calcule le nombre de jours travaillés dans une semaine donnée.
  int joursTravaillesSemaine(DateTime semaine) {
    final debutSemaine = semaine.subtract(Duration(days: semaine.weekday - 1));
    final finSemaine = debutSemaine.add(const Duration(days: 6));

    return joursTravailles.where((jour) {
      return jour.date.isAfter(
            debutSemaine.subtract(const Duration(days: 1)),
          ) &&
          jour.date.isBefore(finSemaine.add(const Duration(days: 1)));
    }).length;
  }

  /// Calcule le salaire hebdomadaire pour une semaine donnée.
  int salaireHebdomadaire(DateTime semaine) {
    final jours = joursTravaillesSemaine(semaine);
    return jours * salaireJournalier;
  }

  /// Calcule le salaire total pour toutes les semaines.
  int get salaireTotal {
    if (joursTravailles.isEmpty) return 0;
    return joursTravailles.length * salaireJournalier;
  }

  /// Vérifie si l'ouvrier a travaillé un jour donné.
  bool aTravailleLe(DateTime date) {
    return joursTravailles.any(
      (jour) =>
          jour.date.year == date.year &&
          jour.date.month == date.month &&
          jour.date.day == date.day,
    );
  }

  DailyWorker copyWith({
    String? id,
    String? name,
    String? phone,
    int? salaireJournalier,
    List<WorkDay>? joursTravailles,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyWorker(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      salaireJournalier: salaireJournalier ?? this.salaireJournalier,
      joursTravailles: joursTravailles ?? this.joursTravailles,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
