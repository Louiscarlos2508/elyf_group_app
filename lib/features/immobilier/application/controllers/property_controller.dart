import '../../../audit_trail/domain/services/audit_trail_service.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../domain/entities/property.dart';
import '../../domain/repositories/property_repository.dart';
import '../../domain/services/immobilier_validation_service.dart';

class PropertyController {
  PropertyController(
    this._propertyRepository,
    this._validationService,
    this._auditTrailService,
    this._enterpriseId,
    this._userId,
  );

  final PropertyRepository _propertyRepository;
  final ImmobilierValidationService _validationService;
  final AuditTrailService _auditTrailService;
  final String _enterpriseId;
  final String _userId;

  Future<List<Property>> fetchProperties() async {
    return await _propertyRepository.getAllProperties();
  }

  Stream<List<Property>> watchProperties() {
    return _propertyRepository.watchProperties();
  }

  Stream<List<Property>> watchDeletedProperties() {
    return _propertyRepository.watchDeletedProperties();
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
    final created = await _propertyRepository.createProperty(property);
    await _logAction('create', created.id, metadata: created.toMap());
    return created;
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

    final updated = await _propertyRepository.updateProperty(property);
    await _logAction('update', updated.id, metadata: updated.toMap());
    return updated;
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
    await _logAction('delete', id);
  }

  Future<void> restoreProperty(String id) async {
    await _propertyRepository.restoreProperty(id);
    await _logAction('restore', id);
  }

  Future<void> _logAction(
    String action,
    String entityId, {
    Map<String, dynamic>? metadata,
  }) async {
    await _auditTrailService.logAction(
      enterpriseId: _enterpriseId,
      userId: _userId,
      module: 'immobilier',
      action: action,
      entityId: entityId,
      entityType: 'property',
      metadata: metadata,
    );
  }
}
