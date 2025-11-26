import '../../domain/entities/property.dart';

/// Helpers pour le dialog de détails de propriété.
class PropertyDetailHelpers {
  PropertyDetailHelpers._();

  static String formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        ) + ' F';
  }

  static String getTypeLabel(PropertyType type) {
    switch (type) {
      case PropertyType.house:
        return 'Maison';
      case PropertyType.apartment:
        return 'Appartement';
      case PropertyType.studio:
        return 'Studio';
      case PropertyType.villa:
        return 'Villa';
      case PropertyType.commercial:
        return 'Commercial';
    }
  }

  static String getStatusLabel(PropertyStatus status) {
    switch (status) {
      case PropertyStatus.available:
        return 'Disponible';
      case PropertyStatus.rented:
        return 'Louée';
      case PropertyStatus.maintenance:
        return 'En maintenance';
      case PropertyStatus.sold:
        return 'Vendue';
    }
  }
}

