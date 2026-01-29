/// Utilitaires pour les numéros de téléphone (Burkina Faso, indicatif +226).
class PhoneUtils {
  PhoneUtils._();

  static const String _indicatif = '226';
  static const String _indicatifPrefix = '+226';

  /// Normalise un numéro vers le format +226XXXXXXXX (Burkina).
  ///
  /// Accepte : 7X XX XX XX, 70123456, +226 70 12 34 56, 22670123456.
  /// Retourne null si le numéro est vide ou invalide.
  static String? normalizeBurkina(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final digits = value.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 8) return '$_indicatifPrefix$digits';
    if (digits.length == 11 &&
        digits.startsWith(_indicatif) &&
        digits.substring(3).length == 8) {
      return '$_indicatifPrefix${digits.substring(3)}';
    }
    return null;
  }

  /// Valide un numéro Burkina (8+ chiffres, format local ou +226).
  /// Retourne null si valide, sinon un message d'erreur.
  static String? validateBurkina(String? value, {String? customMessage}) {
    if (value == null || value.trim().isEmpty) {
      return customMessage ?? 'Le numéro de téléphone est requis';
    }
    final normalized = normalizeBurkina(value);
    if (normalized == null) {
      return customMessage ??
          'Format invalide. Utilisez l\'indicatif Burkina +226 (ex: +226 70 00 00 00)';
    }
    return null;
  }

  /// Valide puis normalise. Retourne (null, error) ou (normalized, null).
  static (String?, String?) validateAndNormalizeBurkina(String? value) {
    final err = validateBurkina(value);
    if (err != null) return (null, err);
    return (normalizeBurkina(value), null);
  }
}
