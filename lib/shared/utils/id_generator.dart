/// Utilitaire pour générer des identifiants uniques.
///
/// Centralise la génération d'ID pour permettre de changer
/// la stratégie plus tard si nécessaire (UUID, nanoid, etc.).
class IdGenerator {
  IdGenerator._();

  /// Génère un ID unique basé sur le timestamp actuel.
  ///
  /// Retourne une chaîne représentant le nombre de millisecondes
  /// depuis l'époque Unix.
  static String generate() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Génère un ID unique avec un préfixe.
  ///
  /// [prefix] : Le préfixe à ajouter (ex: "prod-", "customer-")
  ///
  /// Exemple : `IdGenerator.generateWithPrefix('prod-')` → "prod-1234567890"
  static String generateWithPrefix(String prefix) {
    return '$prefix${generate()}';
  }
}
