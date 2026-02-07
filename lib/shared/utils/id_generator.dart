import 'dart:math';

/// Utilitaire pour générer des identifiants uniques.
///
/// Centralise la génération d'ID pour permettre de changer
/// la stratégie plus tard si nécessaire (UUID, nanoid, etc.).
class IdGenerator {
  IdGenerator._();

  static final _random = Random();

  /// Génère un ID unique basé sur le timestamp actuel et une partie aléatoire.
  ///
  /// Format : `{timestamp}_{random4chars}` (ex: 1715694839201_a9b2)
  static String generate() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart = _generateRandomString(4);
    return '${timestamp}_$randomPart';
  }

  /// Génère un ID unique avec un préfixe.
  ///
  /// [prefix] : Le préfixe à ajouter (ex: "prod-", "customer-")
  ///
  /// Exemple : `IdGenerator.generateWithPrefix('prod-')` → "prod-1234567890_a9b2"
  static String generateWithPrefix(String prefix) {
    return '$prefix${generate()}';
  }

  static String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return String.fromCharCodes(Iterable.generate(
      length,
      (_) => chars.codeUnitAt(_random.nextInt(chars.length)),
    ));
  }
}
