/// Service pour la validation des données client.
class CustomerService {
  CustomerService._();

  /// Valide un prénom.
  static String? validateFirstName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Requis';
    }
    return null;
  }

  /// Valide un nom.
  static String? validateLastName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Requis';
    }
    return null;
  }

  /// Valide un numéro de pièce d'identité.
  static String? validateIdNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Requis';
    }
    return null;
  }
}

