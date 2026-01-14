/// Helpers pour le formulaire de session de production.
class ProductionSessionFormHelpers {
  /// Formate une date au format DD/MM/YYYY.
  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  /// Formate une heure au format HH:MM.
  static String formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  /// Parse un index compteur depuis un texte, acceptant les décimales.
  /// Retourne null si la valeur est vide, sinon l'entier arrondi.
  static int? parseIndexCompteur(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    // Accepter les décimales et arrondir
    final cleanedValue = trimmed.replaceAll(',', '.');
    final doubleValue = double.tryParse(cleanedValue);
    return doubleValue?.round();
  }
}
