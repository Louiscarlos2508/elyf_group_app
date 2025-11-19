/// Describes a batch of sachets produced during a shift.
class ProductionBatch {
  const ProductionBatch({
    required this.id,
    required this.date,
    required this.lineName,
    required this.sachetsProduced,
    required this.sachetsRejected,
    required this.operator,
  });

  final String id;
  final DateTime date;
  final String lineName;
  final int sachetsProduced;
  final int sachetsRejected;
  final String operator;

  int get netOutput => sachetsProduced - sachetsRejected;

  factory ProductionBatch.sample(int index) {
    return ProductionBatch(
      id: 'batch-$index',
      date: DateTime.now().subtract(Duration(hours: index * 3)),
      lineName: 'Ligne ${index + 1}',
      sachetsProduced: 7500 - (index * 120),
      sachetsRejected: 120 + (index * 5),
      operator: 'Opérateur ${index + 1}',
    );
  }
}
