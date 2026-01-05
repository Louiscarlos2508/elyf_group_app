/// Validateurs réutilisables pour les formulaires.
/// 
/// Tous les validateurs retournent `String?` :
/// - `null` = valide
/// - `String` = message d'erreur à afficher
class Validators {
  Validators._();

  /// Valide qu'un champ n'est pas vide.
  /// 
  /// [message] : Message d'erreur personnalisé (par défaut: 'Requis').
  static String? required(String? value, {String message = 'Requis'}) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  /// Valide un numéro de téléphone.
  /// 
  /// Accepte les formats avec ou sans indicatif (+), minimum 8 chiffres.
  /// Exemples valides : +237 6XX XXX XXX, 6XX XXX XXX, 0123456789
  static String? phone(String? value, {String? customMessage}) {
    if (value == null || value.trim().isEmpty) {
      return customMessage ?? 'Le numéro de téléphone est requis';
    }

    // Nettoie les espaces et tirets
    final cleaned = value.replaceAll(RegExp(r'[\s\-]'), '');
    
    // Valide : commence par + ou un chiffre, minimum 8 chiffres
    if (!RegExp(r'^(\+?[0-9]{8,})$').hasMatch(cleaned)) {
      return customMessage ?? 'Format de téléphone invalide';
    }

    return null;
  }

  /// Valide un montant entier positif.
  /// 
  /// [value] : La valeur à valider (peut être vide si non requis).
  /// [allowZero] : Autorise 0 (par défaut: false).
  /// [customMessage] : Message d'erreur personnalisé.
  static String? amount(String? value, {
    bool allowZero = false,
    String? customMessage,
  }) {
    if (value == null || value.trim().isEmpty) {
      return customMessage ?? 'Le montant est requis';
    }

    final amount = int.tryParse(value.trim());
    if (amount == null) {
      return customMessage ?? 'Montant invalide';
    }

    if (amount < 0) {
      return customMessage ?? 'Le montant doit être positif';
    }

    if (!allowZero && amount == 0) {
      return customMessage ?? 'Le montant doit être supérieur à 0';
    }

    return null;
  }

  /// Valide un montant décimal positif.
  /// 
  /// [value] : La valeur à valider (peut être vide si non requis).
  /// [allowZero] : Autorise 0.0 (par défaut: false).
  /// [customMessage] : Message d'erreur personnalisé.
  static String? amountDouble(String? value, {
    bool allowZero = false,
    String? customMessage,
  }) {
    if (value == null || value.trim().isEmpty) {
      return customMessage ?? 'Le montant est requis';
    }

    final amount = double.tryParse(value.trim());
    if (amount == null) {
      return customMessage ?? 'Montant invalide';
    }

    if (amount < 0) {
      return customMessage ?? 'Le montant doit être positif';
    }

    if (!allowZero && amount == 0) {
      return customMessage ?? 'Le montant doit être supérieur à 0';
    }

    return null;
  }

  /// Valide une adresse email.
  /// 
  /// Utilise une regex simple pour valider le format email.
  static String? email(String? value, {String? customMessage}) {
    if (value == null || value.trim().isEmpty) {
      return customMessage ?? 'L\'email est requis';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return customMessage ?? 'Format d\'email invalide';
    }

    return null;
  }

  /// Valide la longueur minimale d'un texte.
  /// 
  /// [minLength] : Longueur minimale requise.
  /// [customMessage] : Message d'erreur personnalisé.
  static String? minLength(
    String? value,
    int minLength, {
    String? customMessage,
  }) {
    if (value == null || value.trim().isEmpty) {
      return customMessage ?? 'Ce champ est requis';
    }

    if (value.trim().length < minLength) {
      return customMessage ?? 
          'Ce champ doit contenir au moins $minLength caractères';
    }

    return null;
  }

  /// Valide la longueur maximale d'un texte.
  /// 
  /// [maxLength] : Longueur maximale autorisée.
  /// [customMessage] : Message d'erreur personnalisé.
  static String? maxLength(
    String? value,
    int maxLength, {
    String? customMessage,
  }) {
    if (value == null || value.trim().isEmpty) {
      return null; // Vide est valide, utilisez required() si nécessaire
    }

    if (value.length > maxLength) {
      return customMessage ?? 
          'Ce champ doit contenir au maximum $maxLength caractères';
    }

    return null;
  }

  /// Valide qu'un nombre entier est positif.
  /// 
  /// [value] : La valeur à valider.
  /// [allowZero] : Autorise 0 (par défaut: false).
  /// [customMessage] : Message d'erreur personnalisé.
  static String? positiveInt(String? value, {
    bool allowZero = false,
    String? customMessage,
  }) {
    if (value == null || value.trim().isEmpty) {
      return customMessage ?? 'Ce champ est requis';
    }

    final number = int.tryParse(value.trim());
    if (number == null) {
      return customMessage ?? 'Valeur invalide';
    }

    if (number < 0) {
      return customMessage ?? 'La valeur doit être positive';
    }

    if (!allowZero && number == 0) {
      return customMessage ?? 'La valeur doit être supérieure à 0';
    }

    return null;
  }

  /// Combine plusieurs validateurs.
  /// 
  /// Exécute les validateurs dans l'ordre et retourne la première erreur.
  /// 
  /// Exemple:
  /// ```dart
  /// validator: (v) => Validators.combine([
  ///   () => Validators.required(v),
  ///   () => Validators.minLength(v, 3),
  /// ])
  /// ```
  static String? combine(List<String? Function()> validators) {
    for (final validator in validators) {
      final error = validator();
      if (error != null) {
        return error;
      }
    }
    return null;
  }
}

