// Catégorie de frais
enum CategorieFrais { carburant, repas, peage, autre }

extension CategorieFraisExt on CategorieFrais {
  String get label => switch (this) {
    CategorieFrais.carburant => 'Carburant',
    CategorieFrais.repas     => 'Repas',
    CategorieFrais.peage     => 'Péage',
    CategorieFrais.autre     => 'Autre',
  };
  String get icon => switch (this) {
    CategorieFrais.carburant => '⛽',
    CategorieFrais.repas     => '🍽️',
    CategorieFrais.peage     => '🛣️',
    CategorieFrais.autre     => '📦',
  };
}

// Un frais de transport
class FraisEntry {
  final String id;
  final CategorieFrais categorie;
  final int montant;
  final DateTime timestamp;
  final String? note;

  const FraisEntry({
    required this.id,
    required this.categorie,
    required this.montant,
    required this.timestamp,
    this.note,
  });
}
