import '../../domain/entities/property.dart';
import 'property_sort_menu.dart';

/// Helpers pour la liste des propriétés.
class PropertyListHelpers {
  PropertyListHelpers._();

  static List<Property> filterAndSort({
    required List<Property> properties,
    required String searchQuery,
    PropertyStatus? selectedStatus,
    PropertyType? selectedType,
    required PropertySortOption sortOption,
  }) {
    var filtered = properties;

    // Filtrage par recherche
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((p) {
        return p.address.toLowerCase().contains(query) ||
            p.city.toLowerCase().contains(query) ||
            (p.description?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Filtrage par statut
    if (selectedStatus != null) {
      filtered = filtered.where((p) => p.status == selectedStatus).toList();
    }

    // Filtrage par type
    if (selectedType != null) {
      filtered = filtered.where((p) => p.propertyType == selectedType).toList();
    }

    // Tri
    filtered.sort((a, b) {
      switch (sortOption) {
        case PropertySortOption.priceAsc:
          return a.price.compareTo(b.price);
        case PropertySortOption.priceDesc:
          return b.price.compareTo(a.price);
        case PropertySortOption.areaAsc:
          return a.area.compareTo(b.area);
        case PropertySortOption.areaDesc:
          return b.area.compareTo(a.area);
        case PropertySortOption.roomsAsc:
          return a.rooms.compareTo(b.rooms);
        case PropertySortOption.roomsDesc:
          return b.rooms.compareTo(a.rooms);
        case PropertySortOption.dateNewest:
          final aDate = a.createdAt ?? DateTime(1970);
          final bDate = b.createdAt ?? DateTime(1970);
          return bDate.compareTo(aDate);
        case PropertySortOption.dateOldest:
          final aDate = a.createdAt ?? DateTime(1970);
          final bDate = b.createdAt ?? DateTime(1970);
          return aDate.compareTo(bDate);
      }
    });

    return filtered;
  }
}
