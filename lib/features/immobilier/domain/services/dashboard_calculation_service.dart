import '../entities/contract.dart';
import '../entities/expense.dart' show PropertyExpense;
import '../entities/payment.dart';
import '../entities/property.dart';
import '../entities/report_period.dart';
import '../entities/tenant.dart';

/// Service pour calculer les métriques du dashboard immobilier.
///
/// Extrait la logique métier des widgets pour la rendre testable et réutilisable.
class ImmobilierDashboardCalculationService {
  ImmobilierDashboardCalculationService();

  /// Calcule les métriques du dashboard pour le mois en cours.
  ImmobilierDashboardMetrics calculateMonthlyMetrics({
    required List<Property> properties,
    required List<Tenant> tenants,
    required List<Contract> contracts,
    required List<Payment> payments,
    required List<PropertyExpense> expenses,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    // Statistiques des propriétés
    final totalProperties = properties.length;
    final availableProperties = properties
        .where((p) => p.status == PropertyStatus.available)
        .length;
    final rentedProperties = properties
        .where((p) => p.status == PropertyStatus.rented)
        .length;

    // Statistiques des locataires
    final totalTenants = tenants.length;

    // Contrats actifs
    final activeContracts = contracts
        .where((c) => c.status == ContractStatus.active)
        .toList();
    final activeContractsCount = activeContracts.length;

    // Loyers mensuels totaux (contrats actifs)
    final totalMonthlyRent = activeContracts.fold<int>(
      0,
      (sum, c) => sum + c.monthlyRent,
    );

    // Paiements du mois
    final monthPayments = payments.where((p) {
      return p.paymentDate.isAfter(monthStart.subtract(const Duration(days: 1))) &&
          p.status == PaymentStatus.paid;
    }).toList();
    final monthRevenue = monthPayments.fold<int>(
      0,
      (sum, p) => sum + p.amount,
    );

    // Dépenses du mois
    final monthExpenses = expenses.where((e) {
      return e.expenseDate.isAfter(monthStart.subtract(const Duration(days: 1)));
    }).toList();
    final monthExpensesTotal = monthExpenses.fold<int>(
      0,
      (sum, e) => sum + e.amount,
    );

    // Résultat net
    final netRevenue = monthRevenue - monthExpensesTotal;

    // Taux d'occupation
    final occupancyRate = totalProperties > 0
        ? (rentedProperties / totalProperties) * 100
        : 0.0;

    return ImmobilierDashboardMetrics(
      totalProperties: totalProperties,
      availableProperties: availableProperties,
      rentedProperties: rentedProperties,
      totalTenants: totalTenants,
      activeContractsCount: activeContractsCount,
      totalMonthlyRent: totalMonthlyRent,
      monthRevenue: monthRevenue,
      monthExpensesTotal: monthExpensesTotal,
      netRevenue: netRevenue,
      occupancyRate: occupancyRate,
    );
  }

  /// Calcule les dates de début et fin pour une période donnée.
  ({DateTime start, DateTime end}) calculatePeriodDates({
    required ReportPeriod period,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    DateTime start;
    DateTime end;

    if (startDate != null && endDate != null) {
      start = startDate;
      end = endDate;
    } else {
      switch (period) {
        case ReportPeriod.today:
          start = DateTime(now.year, now.month, now.day);
          end = now;
          break;
        case ReportPeriod.thisWeek:
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          start = DateTime(weekStart.year, weekStart.month, weekStart.day);
          end = now;
          break;
        case ReportPeriod.thisMonth:
          start = DateTime(now.year, now.month, 1);
          end = now;
          break;
        case ReportPeriod.thisYear:
          start = DateTime(now.year, 1, 1);
          end = now;
          break;
        case ReportPeriod.custom:
          start = startDate ?? now;
          end = endDate ?? now;
          break;
      }
    }

    return (start: start, end: end);
  }

  /// Calcule les métriques pour une période donnée (utilisé pour les rapports PDF).
  ImmobilierPeriodMetrics calculatePeriodMetrics({
    required List<Property> properties,
    required List<Contract> contracts,
    required List<Payment> periodPayments,
    required List<PropertyExpense> periodExpenses,
  }) {
    // Statistiques des propriétés
    final totalProperties = properties.length;
    final availableProperties = properties
        .where((p) => p.status == PropertyStatus.available)
        .length;
    final rentedProperties = properties
        .where((p) => p.status == PropertyStatus.rented)
        .length;

    // Contrats actifs
    final activeContracts = contracts
        .where((c) => c.status == ContractStatus.active)
        .toList();
    final activeContractsCount = activeContracts.length;

    // Loyers mensuels totaux (contrats actifs)
    final totalMonthlyRent = activeContracts.fold<int>(
      0,
      (sum, c) => sum + c.monthlyRent,
    );

    // Revenus de la période
    final periodRevenue = periodPayments
        .where((p) => p.status == PaymentStatus.paid)
        .fold<int>(
          0,
          (sum, p) => sum + p.amount,
        );

    // Dépenses de la période
    final periodExpensesTotal = periodExpenses.fold<int>(
      0,
      (sum, e) => sum + e.amount,
    );

    // Résultat net
    final netRevenue = periodRevenue - periodExpensesTotal;

    // Taux d'occupation
    final occupancyRate = totalProperties > 0
        ? (rentedProperties / totalProperties) * 100
        : 0.0;

    return ImmobilierPeriodMetrics(
      totalProperties: totalProperties,
      availableProperties: availableProperties,
      rentedProperties: rentedProperties,
      activeContractsCount: activeContractsCount,
      totalMonthlyRent: totalMonthlyRent,
      periodRevenue: periodRevenue,
      periodExpensesTotal: periodExpensesTotal,
      netRevenue: netRevenue,
      occupancyRate: occupancyRate,
    );
  }
}

/// Métriques calculées pour le dashboard immobilier.
class ImmobilierDashboardMetrics {
  const ImmobilierDashboardMetrics({
    required this.totalProperties,
    required this.availableProperties,
    required this.rentedProperties,
    required this.totalTenants,
    required this.activeContractsCount,
    required this.totalMonthlyRent,
    required this.monthRevenue,
    required this.monthExpensesTotal,
    required this.netRevenue,
    required this.occupancyRate,
  });

  final int totalProperties;
  final int availableProperties;
  final int rentedProperties;
  final int totalTenants;
  final int activeContractsCount;
  final int totalMonthlyRent;
  final int monthRevenue;
  final int monthExpensesTotal;
  final int netRevenue;
  final double occupancyRate;
}

/// Métriques calculées pour une période donnée (utilisé pour les rapports PDF).
class ImmobilierPeriodMetrics {
  const ImmobilierPeriodMetrics({
    required this.totalProperties,
    required this.availableProperties,
    required this.rentedProperties,
    required this.activeContractsCount,
    required this.totalMonthlyRent,
    required this.periodRevenue,
    required this.periodExpensesTotal,
    required this.netRevenue,
    required this.occupancyRate,
  });

  final int totalProperties;
  final int availableProperties;
  final int rentedProperties;
  final int activeContractsCount;
  final int totalMonthlyRent;
  final int periodRevenue;
  final int periodExpensesTotal;
  final int netRevenue;
  final double occupancyRate;
}

