/// Statut de progression d'une session de production.
enum ProductionSessionStatus {
  /// Session créée mais pas encore démarrée
  draft,

  /// Production démarrée (heure début enregistrée)
  started,

  /// Production en cours (machines et bobines enregistrées)
  inProgress,

  /// Production terminée (heure fin et quantité enregistrées)
  completed,
}

extension ProductionSessionStatusExtension on ProductionSessionStatus {
  /// Libellé du statut
  String get label {
    switch (this) {
      case ProductionSessionStatus.draft:
        return 'Brouillon';
      case ProductionSessionStatus.started:
        return 'Démarrée';
      case ProductionSessionStatus.inProgress:
        return 'En cours';
      case ProductionSessionStatus.completed:
        return 'Terminée';
    }
  }

  /// Numéro d'étape (0-3)
  int get stepNumber {
    switch (this) {
      case ProductionSessionStatus.draft:
        return 0;
      case ProductionSessionStatus.started:
        return 1;
      case ProductionSessionStatus.inProgress:
        return 2;
      case ProductionSessionStatus.completed:
        return 3;
    }
  }

  /// Indique si l'étape est complétée
  bool isStepCompleted(int step) {
    return stepNumber > step;
  }

  /// Indique si l'étape est active
  bool isStepActive(int step) {
    return stepNumber == step;
  }
}

