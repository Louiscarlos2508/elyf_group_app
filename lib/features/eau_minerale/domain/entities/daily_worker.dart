class WorkDay {
  const WorkDay({
    required this.date,
    required this.productionId,
    required this.salaireJournalier,
  });

  final DateTime date;
  final String productionId; // ID de la production
  final int salaireJournalier; // Salaire journalier en CFA

  factory WorkDay.fromMap(Map<String, dynamic> map) {
    return WorkDay(
      date: DateTime.parse(map['date'] as String),
      productionId: map['productionId'] as String? ?? '',
      salaireJournalier: (map['salaireJournalier'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'productionId': productionId,
      'salaireJournalier': salaireJournalier,
    };
  }
}

/// Représente un ouvrier journalier ou temporaire.
/// Payé par semaine : salaire = nombre de jours travaillés × salaire journalier.
class DailyWorker {
  const DailyWorker({
    required this.id,
    required this.enterpriseId,
    required this.name,
    required this.phone,
    required this.salaireJournalier,
    this.joursTravailles = const [],
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.deletedBy,
  });

  final String id;
  final String enterpriseId;
  final String name;
  final String phone;
  final int salaireJournalier; // Salaire journalier en CFA
  final List<WorkDay> joursTravailles; // Jours travaillés (par semaine)
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final String? deletedBy;

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

  bool get isDeleted => deletedAt != null;

  DailyWorker copyWith({
    String? id,
    String? enterpriseId,
    String? name,
    String? phone,
    int? salaireJournalier,
    List<WorkDay>? joursTravailles,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return DailyWorker(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      salaireJournalier: salaireJournalier ?? this.salaireJournalier,
      joursTravailles: joursTravailles ?? this.joursTravailles,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  factory DailyWorker.fromMap(Map<String, dynamic> map, String defaultEnterpriseId) {
    return DailyWorker(
      id: map['id'] as String? ?? map['localId'] as String,
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      salaireJournalier: (map['salaireJournalier'] as num?)?.toInt() ?? 0,
      joursTravailles: (map['joursTravailles'] as List? ?? [])
          .map((e) => WorkDay.fromMap(e as Map<String, dynamic>))
          .toList(),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
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
      'enterpriseId': enterpriseId,
      'name': name,
      'phone': phone,
      'salaireJournalier': salaireJournalier,
      'joursTravailles': joursTravailles.map((e) => e.toMap()).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
    };
  }
}
