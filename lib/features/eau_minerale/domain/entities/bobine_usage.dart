import 'package:uuid/uuid.dart';

/// Représente l'utilisation d'une bobine dans une session de production.
/// Les bobines sont gérées par type et quantité (comme les emballages).
class BobineUsage {
  const BobineUsage({
    String? id, // ID unique pour ce "stint" de consommation (le rouleau physique)
    required this.bobineType, // Type de bobine (ex: "Bobine standard")
    required this.machineId,
    required this.machineName,
    required this.dateInstallation,
    required this.heureInstallation,
    this.dateUtilisation,
    this.estInstallee = true,
    this.estFinie = false,
    this.isReused = false, // Indique si c'est une réutilisation d'une session précédente
    this.productId,
    this.productName,
  }) : id = id ?? ''; // On accepte le null mais on le convertit en String vide par sécurité

  final String id;
  final bool isReused;

  final String? productId; // ID du produit dans le catalogue
  final String? productName; // Nom du produit dans le catalogue (facultatif si référencé)

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
    String? id,
    String? bobineType,
    String? machineId,
    String? machineName,
    DateTime? dateInstallation,
    DateTime? heureInstallation,
    DateTime? dateUtilisation,
    bool? estInstallee,
    bool? estFinie,
    bool? isReused,
    String? productId,
    String? productName,
  }) {
    return BobineUsage(
      id: id ?? this.id,
      bobineType: bobineType ?? this.bobineType,
      machineId: machineId ?? this.machineId,
      machineName: machineName ?? this.machineName,
      dateInstallation: dateInstallation ?? this.dateInstallation,
      heureInstallation: heureInstallation ?? this.heureInstallation,
      dateUtilisation: dateUtilisation ?? this.dateUtilisation,
      estInstallee: estInstallee ?? this.estInstallee,
      estFinie: estFinie ?? this.estFinie,
      isReused: isReused ?? this.isReused,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
    );
  }

  factory BobineUsage.fromMap(Map<String, dynamic> map) {
    // Si l'ID est manquant ou null, on en génère un nouveau pour éviter les crashs
    // sur les anciens enregistrements lors de la sérialisation
    String effectiveId = map['id'] as String? ?? '';
    if (effectiveId.isEmpty) {
      effectiveId = const Uuid().v4();
    }

    return BobineUsage(
      id: effectiveId,
      bobineType: map['bobineType'] as String? ?? '',
      machineId: map['machineId'] as String? ?? '',
      machineName: map['machineName'] as String? ?? '',
      dateInstallation: DateTime.parse(map['dateInstallation'] as String),
      heureInstallation: DateTime.parse(map['heureInstallation'] as String),
      dateUtilisation: map['dateUtilisation'] != null
          ? DateTime.parse(map['dateUtilisation'] as String)
          : null,
      estInstallee: map['estInstallee'] as bool? ?? true,
      estFinie: map['estFinie'] as bool? ?? false,
      isReused: map['isReused'] as bool? ?? false,
      productId: map['productId'] as String?,
      productName: map['productName'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bobineType': bobineType,
      'machineId': machineId,
      'machineName': machineName,
      'dateInstallation': dateInstallation.toIso8601String(),
      'heureInstallation': heureInstallation.toIso8601String(),
      'dateUtilisation': dateUtilisation?.toIso8601String(),
      'estInstallee': estInstallee,
      'estFinie': estFinie,
      'isReused': isReused,
      'productId': productId,
      'productName': productName,
    };
  }
}
