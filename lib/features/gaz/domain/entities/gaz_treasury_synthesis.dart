import 'package:equatable/equatable.dart';

class GazTreasurySynthesis extends Equatable {
  const GazTreasurySynthesis({
    required this.totalSalesRevenue,
    required this.totalTourExpenses,
    required this.totalManualExpenses,
    this.totalPosRemittances = 0,
  });

  final double totalSalesRevenue;
  final double totalTourExpenses;
  final double totalManualExpenses;
  final double totalPosRemittances;

  double get totalIncoming => totalSalesRevenue + totalPosRemittances;
  double get estimatedBalance => totalIncoming - totalTourExpenses - totalManualExpenses;

  @override
  List<Object?> get props => [
        totalSalesRevenue,
        totalTourExpenses,
        totalManualExpenses,
        totalPosRemittances,
      ];
}
