import 'tour.dart';

// Une entrée de collecte (vides ramassés sur un site)
class CollecteEntry {
  final String siteId;
  final String siteName; // <--- Added
  final TypeSite siteType;
  final Map<FormatBouteille, int> quantitesVides; // format → quantité
  final DateTime timestamp;
  final String? note;

  const CollecteEntry({
    required this.siteId,
    required this.siteName, // <--- Added
    required this.siteType,
    required this.quantitesVides,
    required this.timestamp,
    this.note,
  });
}
