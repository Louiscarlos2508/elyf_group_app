import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../domain/entities/property.dart';

/// Helpers pour les cartes de propriété.
class PropertyCardHelpers {
  PropertyCardHelpers._();

  static String formatCurrency(int amount) {
    // Utilise CurrencyFormatter partagé
    return CurrencyFormatter.formatShort(amount);
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

  static Color getStatusColor(PropertyStatus status) {
    switch (status) {
      case PropertyStatus.available:
        return Colors.green;
      case PropertyStatus.rented:
        return Colors.blue;
      case PropertyStatus.maintenance:
        return Colors.orange;
      case PropertyStatus.sold:
        return Colors.grey;
    }
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

  static IconData getTypeIcon(PropertyType type) {
    switch (type) {
      case PropertyType.house:
        return Icons.home;
      case PropertyType.apartment:
        return Icons.apartment;
      case PropertyType.studio:
        return Icons.meeting_room;
      case PropertyType.villa:
        return Icons.villa;
      case PropertyType.commercial:
        return Icons.store;
    }
  }
}

