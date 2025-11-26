import '../../domain/entities/property.dart';
import '../../domain/repositories/property_repository.dart';
import '../services/immobilier_validation_service.dart';

class PropertyController {
  PropertyController(
    this._propertyRepository,
    this._validationService,
  );

  final PropertyRepository _propertyRepository;
  final ImmobilierValidationService _validationService;

  Future<List<Property>> fetchProperties() async {
    return await _propertyRepository.getAllProperties();
  }

  Future<Property?> getProperty(String id) async {
    return await _propertyRepository.getPropertyById(id);
  }

  Future<List<Property>> getPropertiesByStatus(PropertyStatus status) async {
    return await _propertyRepository.getPropertiesByStatus(status);
  }

  Future<List<Property>> getPropertiesByType(PropertyType type) async {
    return await _propertyRepository.getPropertiesByType(type);
  }

  Future<Property> createProperty(Property property) async {
    return await _propertyRepository.createProperty(property);
  }

  /// Met à jour une propriété après validation.
  Future<Property> updateProperty(Property property) async {
    // Récupérer l'ancienne propriété pour comparer les statuts
    final oldProperty = await _propertyRepository.getPropertyById(property.id);
    if (oldProperty == null) {
      throw Exception('La propriété à mettre à jour n\'existe pas');
    }

    // Valider le changement de statut
    if (oldProperty.status != property.status) {
      final validationError = await _validationService.validatePropertyStatusUpdate(
        property.id,
        property.status,
      );
      if (validationError != null) {
        throw Exception(validationError);
      }
    }

    return await _propertyRepository.updateProperty(property);
  }

  /// Supprime une propriété après validation.
  Future<void> deleteProperty(String id) async {
    // Valider la suppression
    final validationError = await _validationService.validatePropertyDeletion(id);
    if (validationError != null) {
      throw Exception(validationError);
    }

    await _propertyRepository.deleteProperty(id);
  }
}

