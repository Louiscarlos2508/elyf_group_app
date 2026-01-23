import '../../../../core/errors/app_exceptions.dart';
import '../../domain/entities/contract.dart';
import '../../domain/entities/property.dart';
import '../../domain/repositories/contract_repository.dart';
import '../../domain/repositories/property_repository.dart';
import '../../domain/services/immobilier_validation_service.dart';

class ContractController {
  ContractController(
    this._contractRepository,
    this._propertyRepository,
    this._validationService,
  );

  final ContractRepository _contractRepository;
  final PropertyRepository _propertyRepository;
  final ImmobilierValidationService _validationService;

  Future<List<Contract>> fetchContracts() async {
    return await _contractRepository.getAllContracts();
  }

  Future<Contract?> getContract(String id) async {
    return await _contractRepository.getContractById(id);
  }

  Future<List<Contract>> getActiveContracts() async {
    return await _contractRepository.getActiveContracts();
  }

  Future<List<Contract>> getContractsByProperty(String propertyId) async {
    return await _contractRepository.getContractsByProperty(propertyId);
  }

  Future<List<Contract>> getContractsByTenant(String tenantId) async {
    return await _contractRepository.getContractsByTenant(tenantId);
  }

  /// Crée un contrat et met à jour le statut de la propriété si nécessaire.
  Future<Contract> createContract(Contract contract) async {
    // Valider le contrat
    final validationError = await _validationService.validateContractCreation(
      contract,
    );
    if (validationError != null) {
      throw ValidationException(
        validationError,
        'CONTRACT_VALIDATION_FAILED',
      );
    }

    // Créer le contrat
    final createdContract = await _contractRepository.createContract(contract);

    // Si le contrat est actif, mettre la propriété en "rented"
    if (contract.status == ContractStatus.active) {
      final property = await _propertyRepository.getPropertyById(
        contract.propertyId,
      );
      if (property != null && property.status != PropertyStatus.rented) {
        final updatedProperty = Property(
          id: property.id,
          address: property.address,
          city: property.city,
          propertyType: property.propertyType,
          rooms: property.rooms,
          area: property.area,
          price: property.price,
          status: PropertyStatus.rented,
          description: property.description,
          images: property.images,
          amenities: property.amenities,
          createdAt: property.createdAt,
          updatedAt: DateTime.now(),
        );
        await _propertyRepository.updateProperty(updatedProperty);
      }
    }

    return createdContract;
  }

  /// Met à jour un contrat et gère le statut de la propriété.
  Future<Contract> updateContract(Contract contract) async {
    // Récupérer l'ancien contrat pour comparer les statuts
    final oldContract = await _contractRepository.getContractById(contract.id);
    if (oldContract == null) {
      throw NotFoundException(
        'Le contrat à mettre à jour n\'existe pas',
        'CONTRACT_NOT_FOUND',
      );
    }

    // Valider la mise à jour
    if (oldContract.status != contract.status) {
      final validationError = await _validationService
          .validateContractStatusUpdate(contract.id, contract.status);
      if (validationError != null) {
        throw ValidationException(
        validationError,
        'CONTRACT_VALIDATION_FAILED',
      );
      }
    }

    // Mettre à jour le contrat
    final updatedContract = await _contractRepository.updateContract(contract);

    // Gérer le statut de la propriété
    final property = await _propertyRepository.getPropertyById(
      contract.propertyId,
    );
    if (property != null) {
      PropertyStatus? newStatus;

      // Si le contrat devient actif, mettre la propriété en "rented"
      if (oldContract.status != ContractStatus.active &&
          contract.status == ContractStatus.active) {
        newStatus = PropertyStatus.rented;
      }
      // Si le contrat n'est plus actif, vérifier s'il y a d'autres contrats actifs
      else if (oldContract.status == ContractStatus.active &&
          contract.status != ContractStatus.active) {
        final contracts = await _contractRepository.getContractsByProperty(
          property.id,
        );
        final activeContracts = contracts.where(
          (c) => c.status == ContractStatus.active && c.id != contract.id,
        );
        // Si plus de contrats actifs, remettre la propriété en "available"
        if (activeContracts.isEmpty &&
            property.status == PropertyStatus.rented) {
          newStatus = PropertyStatus.available;
        }
      }

      if (newStatus != null) {
        final updatedProperty = Property(
          id: property.id,
          address: property.address,
          city: property.city,
          propertyType: property.propertyType,
          rooms: property.rooms,
          area: property.area,
          price: property.price,
          status: newStatus,
          description: property.description,
          images: property.images,
          amenities: property.amenities,
          createdAt: property.createdAt,
          updatedAt: DateTime.now(),
        );
        await _propertyRepository.updateProperty(updatedProperty);
      }
    }

    return updatedContract;
  }

  /// Supprime un contrat et remet la propriété en "available" si nécessaire.
  Future<void> deleteContract(String id) async {
    final contract = await _contractRepository.getContractById(id);
    if (contract == null) {
      throw NotFoundException(
        'Le contrat à supprimer n\'existe pas',
        'CONTRACT_NOT_FOUND',
      );
    }

    final propertyId = contract.propertyId;
    final wasActive = contract.status == ContractStatus.active;

    // Supprimer le contrat
    await _contractRepository.deleteContract(id);

    // Si le contrat était actif, vérifier s'il reste des contrats actifs pour la propriété
    if (wasActive) {
      final contracts = await _contractRepository.getContractsByProperty(
        propertyId,
      );
      final activeContracts = contracts.where(
        (c) => c.status == ContractStatus.active,
      );

      // Si plus de contrats actifs, remettre la propriété en "available"
      if (activeContracts.isEmpty) {
        final property = await _propertyRepository.getPropertyById(propertyId);
        if (property != null && property.status == PropertyStatus.rented) {
          final updatedProperty = Property(
            id: property.id,
            address: property.address,
            city: property.city,
            propertyType: property.propertyType,
            rooms: property.rooms,
            area: property.area,
            price: property.price,
            status: PropertyStatus.available,
            description: property.description,
            images: property.images,
            amenities: property.amenities,
            createdAt: property.createdAt,
            updatedAt: DateTime.now(),
          );
          await _propertyRepository.updateProperty(updatedProperty);
        }
      }
    }
  }
}
