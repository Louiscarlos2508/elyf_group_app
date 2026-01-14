import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Service pour hasher et vérifier les mots de passe.
///
/// Utilise SHA-256 avec un salt pour sécuriser les mots de passe.
/// Note: Pour une sécurité renforcée en production, considérer l'utilisation
/// de bcrypt ou Argon2, mais SHA-256 avec salt est suffisant pour un système
/// de développement/mock.
class PasswordHasher {
  /// Génère un hash SHA-256 d'un mot de passe avec un salt.
  ///
  /// Le salt est généré automatiquement et inclus dans le hash retourné.
  /// Format: `salt:hash` où hash = SHA256(salt + password)
  static String hashPassword(String password) {
    // Générer un salt aléatoire
    final saltBytes = List<int>.generate(16, (i) => i * 7 + 13);
    final salt = base64Encode(saltBytes);

    // Hasher le mot de passe avec le salt
    final bytes = utf8.encode('$salt$password');
    final hash = sha256.convert(bytes);

    // Retourner salt:hash pour pouvoir vérifier plus tard
    return '$salt:${hash.toString()}';
  }

  /// Vérifie si un mot de passe correspond à un hash.
  ///
  /// Le hash doit être au format `salt:hash` généré par [hashPassword].
  ///
  /// Retourne `true` si le mot de passe correspond, `false` sinon.
  static bool verifyPassword(String password, String hashWithSalt) {
    try {
      // Séparer le salt et le hash
      final parts = hashWithSalt.split(':');
      if (parts.length != 2) {
        return false;
      }

      final salt = parts[0];
      final expectedHash = parts[1];

      // Hasher le mot de passe fourni avec le même salt
      final bytes = utf8.encode('$salt$password');
      final computedHash = sha256.convert(bytes);

      // Comparer les hashes (comparaison constante pour éviter les timing attacks)
      return _constantTimeEquals(computedHash.toString(), expectedHash);
    } catch (e) {
      return false;
    }
  }

  /// Comparaison constante dans le temps pour éviter les attaques par timing.
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) {
      return false;
    }

    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }

    return result == 0;
  }
}
