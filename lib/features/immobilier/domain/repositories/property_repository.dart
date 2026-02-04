import '../entities/property.dart';

/// Repository abstrait pour la gestion des propriétés.
abstract class PropertyRepository {
  /// Récupère toutes les propriétés.
  Future<List<Property>> getAllProperties();

  /// Récupère une propriété par son ID.
  Future<Property?> getPropertyById(String id);

  /// Récupère les propriétés par statut.
  Future<List<Property>> getPropertiesByStatus(PropertyStatus status);

  /// Récupère les propriétés par type.
  Future<List<Property>> getPropertiesByType(PropertyType type);

  /// Crée une nouvelle propriété.
  Future<Property> createProperty(Property property);

  /// Met à jour une propriété existante.
  Future<Property> updateProperty(Property property);

  /// Observe les propriétés.
  Stream<List<Property>> watchProperties();

  /// Supprime une propriété.
  Future<void> deleteProperty(String id);
}
