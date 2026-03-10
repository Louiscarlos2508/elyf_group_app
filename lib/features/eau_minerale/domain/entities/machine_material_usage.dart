import 'package:uuid/uuid.dart';

/// Représente l'utilisation d'une matière chargée sur une machine dans une séance de production.
/// (Anciennement BobineUsage).
class MachineMaterialUsage {
  const MachineMaterialUsage({
    String? id, // ID unique pour cet usage spécifique
    required this.materialType, // Type de matière (ex: "Bobine standard", "Sachet")
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
  }) : id = id ?? '';

  final String id;
  final bool isReused;

  final String? productId; // ID du produit dans le catalogue
  final String? productName; // Nom du produit dans le catalogue

  final String materialType; // Type ou nom de la matière
  final String machineId; // ID de la machine
  final String machineName; // Nom de la machine
  final DateTime dateInstallation; // Date d'installation
  final DateTime heureInstallation; // Heure d'installation
  final DateTime? dateUtilisation;
  final bool estInstallee;
  final bool estFinie;

  /// Vérifie si la matière est complètement utilisée
  bool get estCompletementUtilisee => estFinie;

  MachineMaterialUsage copyWith({
    String? id,
    String? materialType,
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
    return MachineMaterialUsage(
      id: id ?? this.id,
      materialType: materialType ?? this.materialType,
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

  factory MachineMaterialUsage.fromMap(Map<String, dynamic> map) {
    String effectiveId = map['id'] as String? ?? (map['usageId'] as String? ?? '');
    if (effectiveId.isEmpty) {
      effectiveId = const Uuid().v4();
    }

    return MachineMaterialUsage(
      id: effectiveId,
      materialType: map['materialType'] as String? ?? (map['bobineType'] as String? ?? ''),
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
      'materialType': materialType,
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
