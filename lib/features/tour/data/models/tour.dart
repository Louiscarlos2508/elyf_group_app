// Format de bouteille gaz — dynamique, vient des Paramètres
class FormatBouteille {
  final String id;        // ex: "f1", "f2" — clé unique en base
  final String label;     // ex: "6 kg", "12 kg", "35 kg"
  final int prixVente;    // prix de vente grossiste en FCFA (depuis Paramètres)
  final int prixGros;     // prix de gros en FCFA (depuis Paramètres)
  final int prixAchat;    // prix d'achat fournisseur en FCFA (depuis Paramètres)

  const FormatBouteille({
    required this.id,
    required this.label,
    required this.prixVente,
    int? prixGros,
    required this.prixAchat,
  }) : prixGros = prixGros ?? prixVente;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FormatBouteille && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// État du tour (machine d'états)
enum TourStatus {
  created,    // Tour créé, pas encore démarré
  collecting, // Phase collecte vides en cours
  recharging, // En attente de recharge fournisseur
  delivering, // Phase livraison pleines en cours
  closing,    // Bilan en cours de validation
  closed,     // Tour clôturé définitivement
}

extension TourStatusExtension on TourStatus {
  static TourStatus fromDomain(dynamic tour) {
    final s = tour.status;
    // Utiliser le nom de l'enum domaine pour le mapping
    final statusName = s is Enum ? s.name : s.toString().split('.').last;
    
    if (statusName == 'closed' || statusName == 'cancelled') return TourStatus.closed;
    if (statusName == 'closing' || tour.closureDate != null) return TourStatus.closing;
    if (statusName == 'delivering' || tour.receptionCompletedDate != null) return TourStatus.delivering;
    if (statusName == 'recharging' || tour.transportCompletedDate != null) return TourStatus.recharging;
    if (statusName == 'collecting' || tour.siteInteractions.isNotEmpty) return TourStatus.collecting;
    
    return TourStatus.created;
  }
}

extension TourStatusX on TourStatus {
  String get routeName => switch (this) {
    TourStatus.created    => 'collecte',
    TourStatus.collecting => 'collecte',
    TourStatus.recharging => 'recharge',
    TourStatus.delivering => 'livraison',
    TourStatus.closing    => 'cloture',
    TourStatus.closed     => 'cloture',
  };
}

// Type de site
enum TypeSite { grossiste, pos }

// Un site (grossiste ou POS)
class Site {
  final String id;
  final String nom;
  final String adresse;
  final String telephone;
  final TypeSite type;

  const Site({
    required this.id,
    required this.nom,
    required this.adresse,
    required this.telephone,
    required this.type,
  });
}
