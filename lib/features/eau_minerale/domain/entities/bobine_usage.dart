/// Représente l'utilisation d'une bobine dans une session de production.
/// Les bobines sont gérées par type et quantité (comme les emballages).
class BobineUsage {
  const BobineUsage({
    required this.bobineType, // Type de bobine (ex: "Bobine standard")
    required this.machineId,
    required this.machineName,
    required this.dateInstallation,
    required this.heureInstallation,
    this.dateUtilisation,
    this.estInstallee = true,
    this.estFinie = false,
  });

  final String bobineType; // Type de bobine (au lieu de référence unique)
  final String machineId; // ID de la machine qui a utilisé cette bobine
  final String machineName; // Nom de la machine
  final DateTime dateInstallation; // Date d'installation (obligatoire)
  final DateTime heureInstallation; // Heure d'installation (obligatoire)
  final DateTime? dateUtilisation;
  final bool estInstallee; // Indique si la bobine est installée
  final bool estFinie; // Indique si la bobine est complètement finie

  /// Vérifie si la bobine est complètement utilisée
  bool get estCompletementUtilisee => estFinie;

  /// Vérifie si la bobine peut être retirée (doit être finie)
  bool get peutEtreRetiree => estFinie;

  BobineUsage copyWith({
    String? bobineType,
    String? machineId,
    String? machineName,
    DateTime? dateInstallation,
    DateTime? heureInstallation,
    DateTime? dateUtilisation,
    bool? estInstallee,
    bool? estFinie,
  }) {
    return BobineUsage(
      bobineType: bobineType ?? this.bobineType,
      machineId: machineId ?? this.machineId,
      machineName: machineName ?? this.machineName,
      dateInstallation: dateInstallation ?? this.dateInstallation,
      heureInstallation: heureInstallation ?? this.heureInstallation,
      dateUtilisation: dateUtilisation ?? this.dateUtilisation,
      estInstallee: estInstallee ?? this.estInstallee,
      estFinie: estFinie ?? this.estFinie,
    );
  }
}

