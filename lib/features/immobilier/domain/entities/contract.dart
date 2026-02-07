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
    this.endDate,
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
    this.entryInventory,
    this.exitInventory,
    this.deletedAt,
    this.deletedBy,
  });

  final String id;
  final String propertyId;
  final String tenantId;
  final DateTime startDate;
  final DateTime? endDate;
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
  final List<AttachedFile>? attachedFiles; // Fichiers joints (contrat signé, photos, etc.)
  final String? entryInventory; // État des lieux d'entrée (texte ou JSON)
  final String? exitInventory; // État des lieux de sortie (texte ou JSON)
  final DateTime? deletedAt;
  final String? deletedBy;

  bool get isDeleted => deletedAt != null;

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
    final isStarted = now.isAfter(startDate) || now.isAtSameMomentAs(startDate);
    final isNotEnded = endDate == null || now.isBefore(endDate!);
    return status == ContractStatus.active && isStarted && isNotEnded;
  }

  /// Identifiant lisible pour l'UI (Locataire ou Propriété).
  String get displayName {
    if (tenant != null) {
      return 'Contrat - ${tenant!.fullName}';
    } else if (property != null) {
      return 'Contrat - ${property!.address}';
    }
    return 'Contrat ${id.substring(0, 8)}';
  }

  /// Vérifie si le contrat est expiré.
  bool get isExpired {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
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
    String? entryInventory,
    String? exitInventory,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    // Note: Pour endDate, comment distinguer 'null' (pas de changement) de 'null' (suppression) ?
    // Dans ce cas simple, on suppose que si endDate est passé, on l'utilise tel quel (même si null).
    // Mais Dart copyWith standard ignore null.
    // Pour permettre de "mettre à null", on pourrait utiliser un sentinel, mais ici on va simplifier :
    // Si on veut mettre fin indéterminée, on passera probablement un nouvel objet Contract ou on gère ça au niveau contrôleur.
    // Pour l'instant, copyWith standard :
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
      entryInventory: entryInventory ?? this.entryInventory,
      exitInventory: exitInventory ?? this.exitInventory,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Contract && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

enum ContractStatus { active, expired, terminated, pending }
