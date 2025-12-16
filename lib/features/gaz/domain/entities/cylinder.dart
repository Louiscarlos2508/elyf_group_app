/// Represents a gas cylinder.
class Cylinder {
  const Cylinder({
    required this.id,
    required this.size,
    required this.status,
    this.depotId,
    this.customerId,
    this.lastDeliveryDate,
    this.lastSaleDate,
  });

  final String id;
  final CylinderSize size;
  final CylinderStatus status;
  final String? depotId;
  final String? customerId;
  final DateTime? lastDeliveryDate;
  final DateTime? lastSaleDate;
}

enum CylinderSize {
  kg6,
  kg12,
  kg14,
}

enum CylinderStatus {
  available,
  rented,
  inTransit,
  maintenance,
}

extension CylinderSizeExtension on CylinderSize {
  String get label {
    switch (this) {
      case CylinderSize.kg6:
        return '6 kg';
      case CylinderSize.kg12:
        return '12 kg';
      case CylinderSize.kg14:
        return '14 kg';
    }
  }
}

extension CylinderStatusExtension on CylinderStatus {
  String get label {
    switch (this) {
      case CylinderStatus.available:
        return 'Disponible';
      case CylinderStatus.rented:
        return 'En location';
      case CylinderStatus.inTransit:
        return 'En transit';
      case CylinderStatus.maintenance:
        return 'En maintenance';
    }
  }
}

