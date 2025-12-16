import 'cylinder.dart';

/// Represents a gas sale (retail or wholesale).
class GasSale {
  const GasSale({
    required this.id,
    required this.type,
    required this.cylinderSize,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.date,
    required this.status,
    this.customerName,
    this.customerPhone,
    this.depotId,
    this.deliveryAddress,
    this.notes,
    this.createdBy,
  });

  final String id;
  final SaleType type;
  final CylinderSize cylinderSize;
  final int quantity;
  final int unitPrice; // Price per cylinder in FCFA
  final int totalPrice; // Total price in FCFA
  final DateTime date;
  final SaleStatus status;
  final String? customerName;
  final String? customerPhone;
  final String? depotId;
  final String? deliveryAddress;
  final String? notes;
  final String? createdBy;

  bool get isRetail => type == SaleType.retail;
  bool get isWholesale => type == SaleType.wholesale;
  bool get isCompleted => status == SaleStatus.completed;
  bool get isPending => status == SaleStatus.pending;
}

enum SaleType {
  retail,
  wholesale,
}

enum SaleStatus {
  pending,
  completed,
  cancelled,
}

extension SaleTypeExtension on SaleType {
  String get label {
    switch (this) {
      case SaleType.retail:
        return 'Détail';
      case SaleType.wholesale:
        return 'Gros';
    }
  }
}

extension SaleStatusExtension on SaleStatus {
  String get label {
    switch (this) {
      case SaleStatus.pending:
        return 'En attente';
      case SaleStatus.completed:
        return 'Terminé';
      case SaleStatus.cancelled:
        return 'Annulé';
    }
  }
}

