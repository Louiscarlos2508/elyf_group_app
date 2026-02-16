import '../entities/contract.dart';
import '../entities/expense.dart' show PropertyExpense;
import '../entities/maintenance_ticket.dart';
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
    List<MaintenanceTicket> tickets = const [],
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();

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
      return p.paymentDate.year == now.year &&
          p.paymentDate.month == now.month &&
          (p.status == PaymentStatus.paid || p.status == PaymentStatus.partial);
    }).toList();
    final monthRevenue = monthPayments.fold<int>(0, (sum, p) => sum + p.paidAmount);
    final monthPaymentsCount = monthPayments.length;

    // Dépenses du mois
    final monthExpenses = expenses.where((e) {
      return e.expenseDate.year == now.year &&
          e.expenseDate.month == now.month;
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

    // Taux de recouvrement
    final collectionRate = totalMonthlyRent > 0
        ? (monthRevenue / totalMonthlyRent) * 100
        : 0.0;

    // Maintenance
    final openTickets = tickets
        .where((t) =>
            t.status == MaintenanceStatus.open ||
            t.status == MaintenanceStatus.inProgress)
        .length;
    final highPriority = tickets
        .where((t) =>
            (t.priority == MaintenancePriority.high ||
                t.priority == MaintenancePriority.critical) &&
            t.status != MaintenanceStatus.closed)
        .length;

    // Loyers mensuels impayés (contrats actifs sans paiement pour ce mois spécifique)
    // On cherche tout paiement couvrant ce mois/année, peu importe quand il a été payé
    int unpaidCount = 0;
    for (final contract in activeContracts) {
      final hasValidPayment = payments.any((p) =>
          p.contractId == contract.id &&
          p.month == now.month &&
          p.year == now.year &&
          p.status == PaymentStatus.paid);

      if (!hasValidPayment) {
        unpaidCount++;
      }
    }

    return ImmobilierDashboardMetrics(
      totalProperties: totalProperties,
      availableProperties: availableProperties,
      rentedProperties: rentedProperties,
      totalTenants: totalTenants,
      activeContractsCount: activeContractsCount,
      totalMonthlyRent: totalMonthlyRent,
      monthRevenue: monthRevenue,
      monthPaymentsCount: monthPaymentsCount,
      monthExpensesTotal: monthExpensesTotal,
      netRevenue: netRevenue,
      occupancyRate: occupancyRate,
      collectionRate: collectionRate,
      unpaidRentsCount: unpaidCount,
      totalOpenTickets: openTickets,
      highPriorityTickets: highPriority,
      totalDepositsHeld: calculateTotalDeposits(payments),
      totalArrears: calculateTotalArrears(contracts: activeContracts, payments: payments, referenceDate: now),
    );
  }

  /// Calcule le total des arriérés pour tous les contrats actifs.
  int calculateTotalArrears({
    required List<Contract> contracts,
    required List<Payment> payments,
    DateTime? referenceDate,
  }) {
    int totalArrears = 0;
    final now = referenceDate ?? DateTime.now();

    for (final contract in contracts) {
      totalArrears += calculateContractArrears(
        contract: contract,
        payments: payments,
        referenceDate: now,
      );
    }
    return totalArrears;
  }

  /// Calcule les arriérés pour un contrat spécifique jusqu'à la date de référence.
  int calculateContractArrears({
    required Contract contract,
    required List<Payment> payments,
    DateTime? referenceDate,
  }) {
    if (contract.status != ContractStatus.active) return 0;
    
    final now = referenceDate ?? DateTime.now();
    final startDate = contract.startDate;
    int arrears = 0;

    // On parcourt chaque mois depuis le début du contrat jusqu'au mois actuel
    DateTime currentMonth = DateTime(startDate.year, startDate.month);
    final targetMonth = DateTime(now.year, now.month);

    while (currentMonth.isBefore(targetMonth) || currentMonth.isAtSameMomentAs(targetMonth)) {
      final monthlyPayment = payments.where((p) =>
          p.contractId == contract.id &&
          p.paymentType == PaymentType.rent &&
          p.month == currentMonth.month &&
          p.year == currentMonth.year &&
          p.status == PaymentStatus.paid
      ).firstOrNull;

      if (monthlyPayment == null) {
        // Si pas de paiement complet, on vérifie les paiements partiels
        final partialPayments = payments.where((p) =>
            p.contractId == contract.id &&
            p.paymentType == PaymentType.rent &&
            p.month == currentMonth.month &&
            p.year == currentMonth.year &&
            p.status == PaymentStatus.partial
        ).toList();

        final paidAmount = partialPayments.fold<int>(0, (sum, p) => sum + p.paidAmount);
        arrears += (contract.monthlyRent - paidAmount);
      }
      
      // Passer au mois suivant
      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);
    }

    return arrears;
  }

  /// Calcule le total des cautions détenues.
  int calculateTotalDeposits(List<Payment> payments) {
    return payments
        .where((p) =>
            p.paymentType == PaymentType.deposit &&
            (p.status == PaymentStatus.paid || p.status == PaymentStatus.partial))
        .fold<int>(0, (sum, p) => sum + p.paidAmount);
  }

  /// Calcule les données pour le graphique de tendance des revenus (6 derniers mois).
  List<({DateTime date, int revenue})> calculateRevenueTrend(List<Payment> payments, {DateTime? referenceDate}) {
    final now = referenceDate ?? DateTime.now();
    final List<({DateTime date, int revenue})> trend = [];

    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthRevenue = payments
          .where((p) =>
              p.paymentDate.year == date.year &&
              p.paymentDate.month == date.month &&
              (p.status == PaymentStatus.paid || p.status == PaymentStatus.partial))
          .fold<int>(0, (sum, p) => sum + p.paidAmount);
      
      trend.add((date: date, revenue: monthRevenue));
    }

    return trend;
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
    final periodPaymentsFiltered = periodPayments
        .where((p) => p.status == PaymentStatus.paid || p.status == PaymentStatus.partial)
        .toList();
    final periodRevenue = periodPaymentsFiltered.fold<int>(0, (sum, p) => sum + p.paidAmount);
    final paidPaymentsCount = periodPaymentsFiltered.length;

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
      paidPaymentsCount: paidPaymentsCount,
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
    required this.monthPaymentsCount, // Added parameter
    required this.monthExpensesTotal,
    required this.netRevenue,
    required this.occupancyRate,
    required this.collectionRate,
    required this.unpaidRentsCount,
    required this.totalOpenTickets,
    required this.highPriorityTickets,
    required this.totalDepositsHeld,
    required this.totalArrears,
  });

  final int totalProperties;
  final int availableProperties;
  final int rentedProperties;
  final int totalTenants;
  final int activeContractsCount;
  final int totalMonthlyRent;
  final int monthRevenue;
  final int monthPaymentsCount;
  final int monthExpensesTotal;
  final int netRevenue;
  final double occupancyRate;
  final double collectionRate;
  final int unpaidRentsCount;
  final int totalOpenTickets;
  final int highPriorityTickets;
  final int totalDepositsHeld;
  final int totalArrears;
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
    required this.paidPaymentsCount,
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
  final int paidPaymentsCount;

  bool get isProfit => netRevenue >= 0;
}
