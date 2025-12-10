/// Représente l'utilisation d'une bobine dans une session de production.
class BobineUsage {
  const BobineUsage({
    required this.bobineId,
    required this.bobineReference,
    required this.poidsInitial,
    required this.poidsFinal,
    required this.machineId,
    required this.machineName,
    this.dateUtilisation,
  }) : assert(
          poidsInitial >= poidsFinal,
          'Le poids initial doit être supérieur ou égal au poids final',
        );

  final String bobineId;
  final String bobineReference; // Référence/nom de la bobine
  final double poidsInitial; // kg - pesée avant utilisation
  final double poidsFinal; // kg - pesée après utilisation
  final String machineId; // ID de la machine qui a utilisé cette bobine
  final String machineName; // Nom de la machine
  final DateTime? dateUtilisation;

  /// Calcule le poids utilisé (kg)
  double get poidsUtilise => poidsInitial - poidsFinal;

  /// Vérifie si la bobine est complètement utilisée
  bool get estCompletementUtilisee => poidsFinal <= 0;

  BobineUsage copyWith({
    String? bobineId,
    String? bobineReference,
    double? poidsInitial,
    double? poidsFinal,
    String? machineId,
    String? machineName,
    DateTime? dateUtilisation,
  }) {
    return BobineUsage(
      bobineId: bobineId ?? this.bobineId,
      bobineReference: bobineReference ?? this.bobineReference,
      poidsInitial: poidsInitial ?? this.poidsInitial,
      poidsFinal: poidsFinal ?? this.poidsFinal,
      machineId: machineId ?? this.machineId,
      machineName: machineName ?? this.machineName,
      dateUtilisation: dateUtilisation ?? this.dateUtilisation,
    );
  }
}

