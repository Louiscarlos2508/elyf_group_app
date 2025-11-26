import 'property.dart';
import 'tenant.dart';

/// Entité représentant un contrat de location.
class Contract {
  Contract({
    required this.id,
    required this.propertyId,
    required this.tenantId,
    required this.startDate,
    required this.endDate,
    required this.monthlyRent,
    required this.deposit,
    required this.status,
    this.property,
    this.tenant,
    this.paymentDay,
    this.notes,
    this.depositInMonths,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String propertyId;
  final String tenantId;
  final DateTime startDate;
  final DateTime endDate;
  final int monthlyRent;
  final int deposit; // Montant de la caution (calculé si depositInMonths est défini)
  final ContractStatus status;
  final Property? property;
  final Tenant? tenant;
  final int? paymentDay; // Jour du mois pour le paiement
  final String? notes;
  final int? depositInMonths; // Nombre de mois pour la caution (si null, deposit est un montant fixe)
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Calcule le montant de la caution en fonction du nombre de mois ou retourne le montant fixe.
  int get calculatedDeposit {
    if (depositInMonths != null && depositInMonths! > 0) {
      return monthlyRent * depositInMonths!;
    }
    return deposit;
  }

  /// Vérifie si le contrat est actif.
  bool get isActive {
    final now = DateTime.now();
    return status == ContractStatus.active &&
        now.isAfter(startDate) &&
        now.isBefore(endDate);
  }

  /// Vérifie si le contrat est expiré.
  bool get isExpired {
    return DateTime.now().isAfter(endDate);
  }
}

enum ContractStatus {
  active,
  expired,
  terminated,
  pending,
}

