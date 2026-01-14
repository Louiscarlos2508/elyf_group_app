/// Représente une machine de production.
class Machine {
  const Machine({
    required this.id,
    required this.nom,
    required this.reference,
    this.description,
    this.estActive = true,
    this.puissanceKw,
    this.dateInstallation,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String nom; // Nom de la machine
  final String reference; // Référence unique
  final String? description;
  final bool estActive; // Indique si la machine est active
  final double? puissanceKw; // Puissance en kW (pour calcul consommation)
  final DateTime? dateInstallation;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Vérifie si la machine est disponible pour utilisation
  bool get estDisponible => estActive;

  Machine copyWith({
    String? id,
    String? nom,
    String? reference,
    String? description,
    bool? estActive,
    double? puissanceKw,
    DateTime? dateInstallation,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Machine(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      reference: reference ?? this.reference,
      description: description ?? this.description,
      estActive: estActive ?? this.estActive,
      puissanceKw: puissanceKw ?? this.puissanceKw,
      dateInstallation: dateInstallation ?? this.dateInstallation,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
