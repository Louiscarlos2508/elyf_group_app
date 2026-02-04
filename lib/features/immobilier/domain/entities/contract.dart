import '../../../../core/domain/entities/attached_file.dart';
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
    this.attachedFiles,
  });

  final String id;
  final String propertyId;
  final String tenantId;
  final DateTime startDate;
  final DateTime endDate;
  final int monthlyRent;
  final int
  deposit; // Montant de la caution (calculé si depositInMonths est défini)
  final ContractStatus status;
  final Property? property;
  final Tenant? tenant;
  final int? paymentDay; // Jour du mois pour le paiement
  final String? notes;
  final int?
  depositInMonths; // Nombre de mois pour la caution (si null, deposit est un montant fixe)
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<AttachedFile>?
  attachedFiles; // Fichiers joints (contrat signé, photos, etc.)

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
  Contract copyWith({
    String? id,
    String? propertyId,
    String? tenantId,
    DateTime? startDate,
    DateTime? endDate,
    int? monthlyRent,
    int? deposit,
    ContractStatus? status,
    Property? property,
    Tenant? tenant,
    int? paymentDay,
    String? notes,
    int? depositInMonths,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<AttachedFile>? attachedFiles,
  }) {
    return Contract(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      tenantId: tenantId ?? this.tenantId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      deposit: deposit ?? this.deposit,
      status: status ?? this.status,
      property: property ?? this.property,
      tenant: tenant ?? this.tenant,
      paymentDay: paymentDay ?? this.paymentDay,
      notes: notes ?? this.notes,
      depositInMonths: depositInMonths ?? this.depositInMonths,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attachedFiles: attachedFiles ?? this.attachedFiles,
    );
  }
}

enum ContractStatus { active, expired, terminated, pending }
