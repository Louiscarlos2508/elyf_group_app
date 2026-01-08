import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../domain/entities/property.dart';

/// Helpers pour le dialog de détails de propriété.
class PropertyDetailHelpers {
  PropertyDetailHelpers._();

  static String formatCurrency(int amount) {
    // Utilise CurrencyFormatter partagé
    return CurrencyFormatter.formatShort(amount);
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

