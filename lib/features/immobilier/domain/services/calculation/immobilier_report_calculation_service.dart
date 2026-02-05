import '../../entities/contract.dart';
import '../../entities/expense.dart' show PropertyExpense;
import '../../entities/payment.dart';
import '../../entities/property.dart';

/// Service for calculating report metrics for the Immobilier module.
///
/// Extracts business logic from UI widgets to make it testable and reusable.
class ImmobilierReportCalculationService {
  ImmobilierReportCalculationService();

  /// Filters paid payments from a list.
  List<Payment> filterPaidPayments(List<Payment> payments) {
    return payments.where((p) => p.status == PaymentStatus.paid).toList();
  }

  /// Calculates total revenue from paid payments.
  int calculateTotalRevenue(List<Payment> paidPayments) {
    return paidPayments.fold<int>(0, (sum, p) => sum + p.amount);
  }

  /// Calculates total expenses.
  int calculateTotalExpenses(List<PropertyExpense> expenses) {
    return expenses.fold<int>(0, (sum, e) => sum + e.amount);
  }

  /// Calculates net revenue (revenue - expenses).
  int calculateNetRevenue({
    required int totalRevenue,
    required int totalExpenses,
  }) {
    return totalRevenue - totalExpenses;
  }

  /// Counts active contracts.
  int countActiveContracts(List<Contract> contracts) {
    return contracts.where((c) => c.status == ContractStatus.active).length;
  }

  /// Counts rented properties.
  int countRentedProperties(List<Property> properties) {
    return properties.where((p) => p.status == PropertyStatus.rented).length;
  }

  /// Calculates occupancy rate.
  double calculateOccupancyRate({
    required int totalProperties,
    required int rentedProperties,
  }) {
    if (totalProperties == 0) return 0.0;
    return (rentedProperties / totalProperties) * 100;
  }

  /// Calculates all report metrics for a period.
  ImmobilierReportMetrics calculateReportMetrics({
    required List<Property> properties,
    required List<Contract> contracts,
    required List<Payment> periodPayments,
    required List<PropertyExpense> periodExpenses,
  }) {
    final paidPayments = filterPaidPayments(periodPayments);
    final totalRevenue = calculateTotalRevenue(paidPayments);
    final totalExpenses = calculateTotalExpenses(periodExpenses);
    final netRevenue = calculateNetRevenue(
      totalRevenue: totalRevenue,
      totalExpenses: totalExpenses,
    );
    final activeContracts = countActiveContracts(contracts);
    final totalProperties = properties.length;
    final rentedProperties = countRentedProperties(properties);
    final occupancyRate = calculateOccupancyRate(
      totalProperties: totalProperties,
      rentedProperties: rentedProperties,
    );

    return ImmobilierReportMetrics(
      totalRevenue: totalRevenue,
      totalExpenses: totalExpenses,
      netRevenue: netRevenue,
      paidPaymentsCount: paidPayments.length,
      activeContractsCount: activeContracts,
      totalProperties: totalProperties,
      rentedProperties: rentedProperties,
      occupancyRate: occupancyRate,
    );
  }
}

/// Report metrics for Immobilier module.
class ImmobilierReportMetrics {
  const ImmobilierReportMetrics({
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netRevenue,
    required this.paidPaymentsCount,
    required this.activeContractsCount,
    required this.totalProperties,
    required this.rentedProperties,
    required this.occupancyRate,
  });

  final int totalRevenue;
  final int totalExpenses;
  final int netRevenue;
  final int paidPaymentsCount;
  final int activeContractsCount;
  final int totalProperties;
  final int rentedProperties;
  final double occupancyRate;

  bool get isProfit => netRevenue >= 0;
}
