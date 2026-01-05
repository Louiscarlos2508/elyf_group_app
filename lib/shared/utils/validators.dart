/// Validators réutilisables pour les formulaires.
class Validators {
  Validators._();

  /// Valide un numéro de téléphone.
  /// Accepte les formats: +226XXXXXXXX, 0XXXXXXXX, XXXXXXXXX
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le numéro de téléphone est requis';
    }
    final cleaned = value.replaceAll(RegExp(r'[\s\-]'), '');
    if (!RegExp(r'^(\+?[0-9]{8,})$').hasMatch(cleaned)) {
      return 'Format de téléphone invalide';
    }
    return null;
  }

  /// Valide un numéro de téléphone (optionnel).
  static String? phoneOptional(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return phone(value);
  }

  /// Valide un montant (entier positif).
  static String? amount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le montant est requis';
    }
    final amount = int.tryParse(value);
    if (amount == null || amount <= 0) {
      return 'Montant invalide (doit être un nombre positif)';
    }
    return null;
  }

  /// Valide un montant (décimal positif).
  static String? amountDouble(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le montant est requis';
    }
    final amount = double.tryParse(value);
    if (amount == null || amount <= 0) {
      return 'Montant invalide (doit être un nombre positif)';
    }
    return null;
  }

  /// Valide un champ requis.
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null ? '$fieldName est requis' : 'Ce champ est requis';
    }
    return null;
  }

  /// Valide un email.
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'email est requis';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return 'Format d\'email invalide';
    }
    return null;
  }

  /// Valide un email (optionnel).
  static String? emailOptional(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return email(value);
  }

  /// Valide une longueur minimale.
  static String? minLength(String? value, int minLength, {String? fieldName}) {
    if (value == null || value.trim().length < minLength) {
      final field = fieldName ?? 'Ce champ';
      return '$field doit contenir au moins $minLength caractères';
    }
    return null;
  }

  /// Valide une longueur maximale.
  static String? maxLength(String? value, int maxLength, {String? fieldName}) {
    if (value != null && value.length > maxLength) {
      final field = fieldName ?? 'Ce champ';
      return '$field ne peut pas dépasser $maxLength caractères';
    }
    return null;
  }

  /// Valide un nombre entier positif.
  static String? positiveInteger(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      final field = fieldName ?? 'Ce champ';
      return '$field est requis';
    }
    final number = int.tryParse(value);
    if (number == null || number <= 0) {
      final field = fieldName ?? 'Ce champ';
      return '$field doit être un nombre entier positif';
    }
    return null;
  }

  /// Valide un nombre décimal positif.
  static String? positiveDouble(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      final field = fieldName ?? 'Ce champ';
      return '$field est requis';
    }
    final number = double.tryParse(value);
    if (number == null || number <= 0) {
      final field = fieldName ?? 'Ce champ';
      return '$field doit être un nombre positif';
    }
    return null;
  }
}

