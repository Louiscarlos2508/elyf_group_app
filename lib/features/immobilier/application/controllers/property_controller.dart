import '../../../../core/errors/app_exceptions.dart';
import '../../domain/entities/property.dart';
import '../../domain/repositories/property_repository.dart';
import '../../domain/services/immobilier_validation_service.dart';

class PropertyController {
  PropertyController(this._propertyRepository, this._validationService);

  final PropertyRepository _propertyRepository;
  final ImmobilierValidationService _validationService;

  Future<List<Property>> fetchProperties() async {
    return await _propertyRepository.getAllProperties();
  }

  Stream<List<Property>> watchProperties() {
    return _propertyRepository.watchProperties();
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
      throw NotFoundException(
        'La propriété à mettre à jour n\'existe pas',
        'PROPERTY_NOT_FOUND',
      );
    }

    // Valider le changement de statut
    if (oldProperty.status != property.status) {
      final validationError = await _validationService
          .validatePropertyStatusUpdate(property.id, property.status);
      if (validationError != null) {
        throw ValidationException(
          validationError,
          'PROPERTY_STATUS_UPDATE_VALIDATION_FAILED',
        );
      }
    }

    return await _propertyRepository.updateProperty(property);
  }

  /// Supprime une propriété après validation.
  Future<void> deleteProperty(String id) async {
    // Valider la suppression
    final validationError = await _validationService.validatePropertyDeletion(
      id,
    );
    if (validationError != null) {
      throw ValidationException(
        validationError,
        'PROPERTY_DELETION_VALIDATION_FAILED',
      );
    }

    await _propertyRepository.deleteProperty(id);
  }
}
