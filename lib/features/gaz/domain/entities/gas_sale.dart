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
    );
  }
}

enum SaleType {
  retail('Détail'),
  wholesale('Gros');

  const SaleType(this.label);
  final String label;
}
