/// Inventory snapshot for finished goods or raw materials.
class StockItem {
  const StockItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.type,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final double quantity;
  final String unit;
  final StockType type;
  final DateTime updatedAt;

  factory StockItem.sample(String id, StockType type) {
    return StockItem(
      id: id,
      name: type == StockType.finishedGoods ? 'Sachets 50cl' : 'Préforme PET',
      quantity: type == StockType.finishedGoods ? 4200 : 780,
      unit: type == StockType.finishedGoods ? 'paquets' : 'kg',
      type: type,
      updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
    );
  }
}

enum StockType { finishedGoods, rawMaterial }
