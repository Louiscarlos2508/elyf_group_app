import 'tour.dart';

// Une ligne de livraison
class LivraisonLigne {
  final FormatBouteille format;
  final int quantiteLivree;
  final int prixUnitaire;
  int get sousTotal => quantiteLivree * prixUnitaire;

  const LivraisonLigne({
    required this.format,
    required this.quantiteLivree,
    required this.prixUnitaire,
  });
}

// Une livraison sur un site
class LivraisonEntry {
  final String siteId;
  final String siteName; // <--- Added
  final TypeSite typeSite;
  final List<LivraisonLigne> lignes;
  final int montantEncaisse;   // pour grossiste : auto-calculé
  final DateTime timestamp;

  const LivraisonEntry({
    required this.siteId,
    required this.siteName, // <--- Added
    required this.typeSite,
    required this.lignes,
    required this.montantEncaisse,
    required this.timestamp,
  });

  int get totalBouteilles => lignes.fold(0, (s, l) => s + l.quantiteLivree);
  int get totalMontant    => lignes.fold(0, (s, l) => s + l.sousTotal);
}
