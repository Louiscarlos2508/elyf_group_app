/// Service for property validation logic.
///
/// Extracts validation logic from UI widgets to make it testable and reusable.
class PropertyValidationService {
  /// Validates property address.
  ///
  /// Returns null if valid, error message otherwise.
  static String? validateAddress(String? address) {
    if (address == null || address.trim().isEmpty) {
      return 'L\'adresse est requise';
    }
    if (address.trim().length < 5) {
      return 'L\'adresse doit contenir au moins 5 caractères';
    }
    return null;
  }

  /// Validates property city.
  ///
  /// Returns null if valid, error message otherwise.
  static String? validateCity(String? city) {
    if (city == null || city.trim().isEmpty) {
      return 'La ville est requise';
    }
    if (city.trim().length < 2) {
      return 'La ville doit contenir au moins 2 caractères';
    }
    return null;
  }

  /// Validates property area.
  ///
  /// Returns null if valid, error message otherwise.
  static String? validateArea(int? area) {
    if (area == null) {
      return 'La superficie est requise';
    }
    if (area <= 0) {
      return 'La superficie doit être supérieure à 0';
    }
    if (area > 10000) {
      return 'La superficie semble trop élevée (max 10000 m²)';
    }
    return null;
  }

  /// Validates property rooms.
  ///
  /// Returns null if valid, error message otherwise.
  static String? validateRooms(int? rooms) {
    if (rooms == null) {
      return 'Le nombre de pièces est requis';
    }
    if (rooms <= 0) {
      return 'Le nombre de pièces doit être supérieur à 0';
    }
    if (rooms > 50) {
      return 'Le nombre de pièces semble trop élevé (max 50)';
    }
    return null;
  }

  /// Validates property price.
  ///
  /// Returns null if valid, error message otherwise.
  static String? validatePrice(int? price) {
    if (price == null) {
      return 'Le prix est requis';
    }
    if (price < 0) {
      return 'Le prix ne peut pas être négatif';
    }
    if (price > 100000000) {
      return 'Le prix semble trop élevé (max 100,000,000 FCFA)';
    }
    return null;
  }

  /// Validates a complete property.
  ///
  /// Returns a list of validation errors (empty if valid).
  static List<String> validateProperty({
    required String? address,
    required String? city,
    required int? area,
    required int? rooms,
    required int? price,
  }) {
    final errors = <String>[];

    final addressError = validateAddress(address);
    if (addressError != null) errors.add(addressError);

    final cityError = validateCity(city);
    if (cityError != null) errors.add(cityError);

    final areaError = validateArea(area);
    if (areaError != null) errors.add(areaError);

    final roomsError = validateRooms(rooms);
    if (roomsError != null) errors.add(roomsError);

    final priceError = validatePrice(price);
    if (priceError != null) errors.add(priceError);

    return errors;
  }
}

