import '../../domain/entities/contract.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/property.dart';
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
    final contracts = await _contractRepository.getContractsByProperty(
      propertyId,
    );
    final activeContracts = contracts.where(
      (c) => c.status == ContractStatus.active,
    );

    if (activeContracts.isNotEmpty) {
      return 'Impossible de supprimer cette propriété car elle a ${activeContracts.length} contrat(s) actif(s)';
    }
    return null;
  }

  /// Valide qu'un locataire peut être supprimé.
  /// Retourne une erreur si le locataire a des contrats actifs.
  Future<String?> validateTenantDeletion(String tenantId) async {
    final contracts = await _contractRepository.getContractsByTenant(tenantId);
    final activeContracts = contracts.where(
      (c) => c.status == ContractStatus.active,
    );

    if (activeContracts.isNotEmpty) {
      return 'Impossible de supprimer ce locataire car il a ${activeContracts.length} contrat(s) actif(s)';
    }
    return null;
  }

  /// Valide qu'un contrat peut être créé.
  /// Vérifie que la propriété existe et n'est pas déjà louée.
  Future<String?> validateContractCreation(Contract contract) async {
    // Vérifier que la propriété existe
    final property = await _propertyRepository.getPropertyById(
      contract.propertyId,
    );
    if (property == null) {
      return 'La propriété sélectionnée n\'existe pas';
    }

    // Vérifier que la date de fin est après la date de début
    if (contract.endDate != null &&
        (contract.endDate!.isBefore(contract.startDate) ||
            contract.endDate!.isAtSameMomentAs(contract.startDate))) {
      return 'La date de fin doit être après la date de début';
    }

    // Si le contrat est actif, vérifier que la propriété n'est pas déjà louée
    if (contract.status == ContractStatus.active) {
      if (property.status == PropertyStatus.rented) {
        // Vérifier s'il y a déjà un contrat actif pour cette propriété
        final existingContracts = await _contractRepository
            .getContractsByProperty(property.id);
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
    final contract = await _contractRepository.getContractById(
      payment.contractId,
    );
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

    // Valider le cas du paiement mixte (both)
    if (payment.paymentMethod.name == 'both') {
      if (payment.cashAmount == null || payment.mobileMoneyAmount == null) {
        return 'Les montants en espèces et en mobile money sont requis pour un paiement mixte';
      }
      if (payment.cashAmount! <= 0 || payment.mobileMoneyAmount! <= 0) {
        return 'Les montants en espèces et en mobile money doivent être supérieurs à 0';
      }
      final totalSplit = payment.cashAmount! + payment.mobileMoneyAmount!;
      if (totalSplit != payment.amount) {
        return 'La somme des montants en espèces (${payment.cashAmount}) et en mobile money (${payment.mobileMoneyAmount}) doit être égale au montant total (${payment.amount})';
      }
    } else {
      if (payment.cashAmount != null || payment.mobileMoneyAmount != null) {
        return 'Les montants séparés ne doivent être renseignés que pour un paiement mixte';
      }
    }

    // Vérifier les doublons
    final existingPayments = await _paymentRepository.getPaymentsByContract(
      payment.contractId,
    );

    if (payment.paymentType == PaymentType.rent) {
      if (payment.month == null || payment.year == null) {
        return 'Le mois et l\'année sont requis pour un paiement de loyer';
      }

      final duplicateRent = existingPayments.any(
        (p) =>
            p.id != payment.id &&
            p.paymentType == PaymentType.rent &&
            p.month == payment.month &&
            p.year == payment.year &&
            p.status != PaymentStatus.cancelled,
      );

      if (duplicateRent) {
        return 'Un paiement de loyer existe déjà pour ${payment.month}/${payment.year}';
      }
    } else if (payment.paymentType == PaymentType.deposit) {
      final duplicateDeposit = existingPayments.any(
        (p) =>
            p.id != payment.id &&
            p.paymentType == PaymentType.deposit &&
            p.status != PaymentStatus.cancelled,
      );

      if (duplicateDeposit) {
        return 'Une caution a déjà été enregistrée pour ce contrat';
      }
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
      final contracts = await _contractRepository.getContractsByProperty(
        propertyId,
      );
      final activeContracts = contracts.where(
        (c) => c.status == ContractStatus.active,
      );
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
      final existingContracts = await _contractRepository
          .getContractsByProperty(contract.propertyId);
      final activeContracts = existingContracts.where(
        (c) => c.status == ContractStatus.active && c.id != contractId,
      );
      if (activeContracts.isNotEmpty) {
        return 'Cette propriété a déjà un contrat actif';
      }
    }

    return null;
  }

  /// Rafraîchit les statuts des contrats et paiements.
  /// - Contrats actifs dont endDate < now passent à expired
  /// - Paiements pending dont paymentDate < now passent à overdue
  Future<void> refreshStatuses() async {
    final now = DateTime.now();

    // Mise à jour des contrats expirés
    final contracts = await _contractRepository.getAllContracts();
    for (final contract in contracts) {
      if (contract.status == ContractStatus.active &&
          contract.endDate != null &&
          contract.endDate!.isBefore(now)) {
        final updated = Contract(
          id: contract.id,
          propertyId: contract.propertyId,
          tenantId: contract.tenantId,
          startDate: contract.startDate,
          endDate: contract.endDate,
          monthlyRent: contract.monthlyRent,
          deposit: contract.deposit,
          status: ContractStatus.expired,
          property: contract.property,
          tenant: contract.tenant,
          paymentDay: contract.paymentDay,
          notes: contract.notes,
          depositInMonths: contract.depositInMonths,
          createdAt: contract.createdAt,
          updatedAt: DateTime.now(),
          attachedFiles: contract.attachedFiles,
        );
        await _contractRepository.updateContract(updated);
      }
    }

    // Mise à jour des paiements en retard
    final payments = await _paymentRepository.getAllPayments();
    for (final payment in payments) {
      if (payment.status == PaymentStatus.pending &&
          payment.paymentDate.isBefore(now)) {
        final updated = Payment(
          id: payment.id,
          contractId: payment.contractId,
          amount: payment.amount,
          paymentDate: payment.paymentDate,
          paymentMethod: payment.paymentMethod,
          status: PaymentStatus.overdue,
          contract: payment.contract,
          month: payment.month,
          year: payment.year,
          receiptNumber: payment.receiptNumber,
          notes: payment.notes,
          paymentType: payment.paymentType,
          cashAmount: payment.cashAmount,
          mobileMoneyAmount: payment.mobileMoneyAmount,
          createdAt: payment.createdAt,
          updatedAt: DateTime.now(),
        );
        await _paymentRepository.updatePayment(updated);
      }
    }
  }

  /// Calcule le statut actuel d'un contrat en fonction de sa date.
  ContractStatus computeContractStatus(Contract contract) {
    final now = DateTime.now();
    if (contract.status == ContractStatus.terminated) {
      return ContractStatus.terminated;
    }
    if (contract.endDate != null && contract.endDate!.isBefore(now)) {
      return ContractStatus.expired;
    }
    if (contract.startDate.isAfter(now)) {
      return ContractStatus.pending;
    }
    return ContractStatus.active;
  }

  /// Calcule le statut actuel d'un paiement.
  PaymentStatus computePaymentStatus(Payment payment) {
    if (payment.status == PaymentStatus.paid ||
        payment.status == PaymentStatus.cancelled) {
      return payment.status;
    }
    final now = DateTime.now();
    if (payment.paymentDate.isBefore(now)) {
      return PaymentStatus.overdue;
    }
    return PaymentStatus.pending;
  }
}
