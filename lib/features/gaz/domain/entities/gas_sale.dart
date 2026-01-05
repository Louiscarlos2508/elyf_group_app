/// Représente une vente de gaz.
class GasSale {
  const GasSale({
    required this.id,
    required this.cylinderId,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.saleDate,
    required this.saleType,
    this.customerName,
    this.customerPhone,
    this.notes,
    this.tourId, // ID du tour d'approvisionnement (pour ventes en gros)
    this.wholesalerId, // ID du grossiste (pour ventes en gros)
    this.wholesalerName, // Nom du grossiste (pour ventes en gros)
  });

  final String id;
  final String cylinderId;
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  final DateTime saleDate;
  final SaleType saleType;
  final String? customerName;
  final String? customerPhone;
  final String? notes;
  final String? tourId; // ID du tour d'approvisionnement (pour ventes en gros)
  final String? wholesalerId; // ID du grossiste (pour ventes en gros)
  final String? wholesalerName; // Nom du grossiste (pour ventes en gros)

  GasSale copyWith({
    String? id,
    String? cylinderId,
    int? quantity,
    double? unitPrice,
    double? totalAmount,
    DateTime? saleDate,
    SaleType? saleType,
    String? customerName,
    String? customerPhone,
    String? notes,
    String? tourId,
    String? wholesalerId,
    String? wholesalerName,
  }) {
    return GasSale(
      id: id ?? this.id,
      cylinderId: cylinderId ?? this.cylinderId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalAmount: totalAmount ?? this.totalAmount,
      saleDate: saleDate ?? this.saleDate,
      saleType: saleType ?? this.saleType,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      notes: notes ?? this.notes,
      tourId: tourId ?? this.tourId,
      wholesalerId: wholesalerId ?? this.wholesalerId,
      wholesalerName: wholesalerName ?? this.wholesalerName,
    );
  }
}

enum SaleType {
  retail('Détail'),
  wholesale('Gros');

  const SaleType(this.label);
  final String label;
}
