import 'package:equatable/equatable.dart';

class GazTreasurySynthesis extends Equatable {
  const GazTreasurySynthesis({
    required this.totalSalesRevenue,
    required this.totalTourExpenses,
    required this.totalManualExpenses,
  });

  final double totalSalesRevenue;
  final double totalTourExpenses;
  final double totalManualExpenses;

  double get estimatedBalance => totalSalesRevenue - totalTourExpenses - totalManualExpenses;

  @override
  List<Object?> get props => [
        totalSalesRevenue,
        totalTourExpenses,
        totalManualExpenses,
      ];
}
