import '../../domain/entities/contract.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/tenant.dart';
import '../../domain/repositories/contract_repository.dart';
import '../../domain/repositories/payment_repository.dart';
import '../../domain/repositories/property_repository.dart';

/// Service de validation pour assurer la cohérence des données immobilières.
class ImmobilierValidationService {
  ImmobilierValidationService(
    this._propertyRepository,
    this._contractRepository,
    this._paymentRepository,
  );

  final PropertyRepository _propertyRepository;
  final ContractRepository _contractRepository;
  final PaymentRepository _paymentRepository;

  /// Valide qu'une propriété peut être supprimée.
  /// Retourne une erreur si la propriété a des contrats actifs.
  Future<String?> validatePropertyDeletion(String propertyId) async {
    final contracts = await _contractRepository.getContractsByProperty(propertyId);
    final activeContracts = contracts.where((c) => c.status == ContractStatus.active);
    
    if (activeContracts.isNotEmpty) {
      return 'Impossible de supprimer cette propriété car elle a ${activeContracts.length} contrat(s) actif(s)';
    }
    return null;
  }

  /// Valide qu'un locataire peut être supprimé.
  /// Retourne une erreur si le locataire a des contrats actifs.
  Future<String?> validateTenantDeletion(String tenantId) async {
    final contracts = await _contractRepository.getContractsByTenant(tenantId);
    final activeContracts = contracts.where((c) => c.status == ContractStatus.active);
    
    if (activeContracts.isNotEmpty) {
      return 'Impossible de supprimer ce locataire car il a ${activeContracts.length} contrat(s) actif(s)';
    }
    return null;
  }

  /// Valide qu'un contrat peut être créé.
  /// Vérifie que la propriété existe et n'est pas déjà louée.
  Future<String?> validateContractCreation(Contract contract) async {
    // Vérifier que la propriété existe
    final property = await _propertyRepository.getPropertyById(contract.propertyId);
    if (property == null) {
      return 'La propriété sélectionnée n\'existe pas';
    }

    // Vérifier que la date de fin est après la date de début
    if (contract.endDate.isBefore(contract.startDate) || 
        contract.endDate.isAtSameMomentAs(contract.startDate)) {
      return 'La date de fin doit être après la date de début';
    }

    // Si le contrat est actif, vérifier que la propriété n'est pas déjà louée
    if (contract.status == ContractStatus.active) {
      if (property.status == PropertyStatus.rented) {
        // Vérifier s'il y a déjà un contrat actif pour cette propriété
        final existingContracts = await _contractRepository.getContractsByProperty(property.id);
        final activeContracts = existingContracts.where(
          (c) => c.status == ContractStatus.active && c.id != contract.id,
        );
        if (activeContracts.isNotEmpty) {
          return 'Cette propriété a déjà un contrat actif';
        }
      }
    }

    return null;
  }

  /// Valide qu'un paiement peut être créé.
  /// Vérifie que le contrat existe et est actif.
  Future<String?> validatePaymentCreation(Payment payment) async {
    // Vérifier que le contrat existe
    final contract = await _contractRepository.getContractById(payment.contractId);
    if (contract == null) {
      return 'Le contrat sélectionné n\'existe pas';
    }

    // Vérifier que le contrat est actif
    if (contract.status != ContractStatus.active) {
      return 'Le paiement ne peut être enregistré que pour un contrat actif';
    }

    // Vérifier que le montant est positif
    if (payment.amount <= 0) {
      return 'Le montant doit être supérieur à 0';
    }

    return null;
  }

  /// Vérifie si une propriété peut être mise à jour avec un nouveau statut.
  Future<String?> validatePropertyStatusUpdate(
    String propertyId,
    PropertyStatus newStatus,
  ) async {
    // Si on essaie de mettre une propriété en "available" alors qu'elle a des contrats actifs
    if (newStatus == PropertyStatus.available) {
      final contracts = await _contractRepository.getContractsByProperty(propertyId);
      final activeContracts = contracts.where((c) => c.status == ContractStatus.active);
      if (activeContracts.isNotEmpty) {
        return 'Impossible de mettre cette propriété en "Disponible" car elle a ${activeContracts.length} contrat(s) actif(s)';
      }
    }

    return null;
  }

  /// Vérifie si un contrat peut être mis à jour avec un nouveau statut.
  Future<String?> validateContractStatusUpdate(
    String contractId,
    ContractStatus newStatus,
  ) async {
    final contract = await _contractRepository.getContractById(contractId);
    if (contract == null) {
      return 'Le contrat n\'existe pas';
    }

    // Si on passe d'actif à non-actif, on peut le faire
    // Si on passe de non-actif à actif, vérifier qu'il n'y a pas d'autre contrat actif pour la même propriété
    if (contract.status != ContractStatus.active && 
        newStatus == ContractStatus.active) {
      final existingContracts = await _contractRepository.getContractsByProperty(contract.propertyId);
      final activeContracts = existingContracts.where(
        (c) => c.status == ContractStatus.active && c.id != contractId,
      );
      if (activeContracts.isNotEmpty) {
        return 'Cette propriété a déjà un contrat actif';
      }
    }

    return null;
  }
}

