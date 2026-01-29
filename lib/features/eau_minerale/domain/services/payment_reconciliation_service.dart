import '../entities/payment_status.dart';
import '../entities/production_day.dart';
import '../entities/production_payment.dart';
import '../entities/production_session.dart';

/// Service de réconciliation des paiements.
/// Gère la traçabilité entre les jours de production et les paiements.
class PaymentReconciliationService {
  /// Récupère tous les jours de production non payés.
  List<ProductionDay> getUnpaidProductionDays(
    List<ProductionSession> sessions,
  ) {
    final allDays = <ProductionDay>[];
    for (final session in sessions) {
      allDays.addAll(session.productionDays);
    }

    return allDays
        .where((day) => day.paymentStatus == PaymentStatus.unpaid)
        .toList();
  }

  /// Récupère les jours de production partiellement payés.
  List<ProductionDay> getPartiallyPaidProductionDays(
    List<ProductionSession> sessions,
  ) {
    final allDays = <ProductionDay>[];
    for (final session in sessions) {
      allDays.addAll(session.productionDays);
    }

    return allDays
        .where((day) => day.paymentStatus == PaymentStatus.partial)
        .toList();
  }

  /// Marque les jours comme payés lors de la création d'un paiement.
  List<ProductionDay> markDaysAsPaid({
    required List<ProductionDay> days,
    required String paymentId,
    required DateTime paymentDate,
    PaymentStatus status = PaymentStatus.paid,
  }) {
    return days
        .map(
          (day) => day.copyWith(
            paymentStatus: status,
            paymentId: paymentId,
            datePaiement: paymentDate,
          ),
        )
        .toList();
  }

  /// Génère un rapport de réconciliation pour une période donnée.
  ReconciliationReport generateReport({
    required List<ProductionSession> sessions,
    required List<ProductionPayment> payments,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    // Filtrer les sessions de la période
    final sessionsInPeriod = sessions.where((session) {
      return session.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          session.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    // Extraire tous les jours de production
    final allDays = <ProductionDay>[];
    for (final session in sessionsInPeriod) {
      allDays.addAll(session.productionDays);
    }

    // Calculer les statistiques
    final unpaidDays = allDays
        .where((day) => day.paymentStatus == PaymentStatus.unpaid)
        .toList();
    final paidDays =
        allDays.where((day) => day.paymentStatus == PaymentStatus.paid).toList();
    final verifiedDays = allDays
        .where((day) => day.paymentStatus == PaymentStatus.verified)
        .toList();

    final totalUnpaidAmount =
        unpaidDays.fold<int>(0, (sum, day) => sum + day.coutTotalPersonnel);
    final totalPaidAmount =
        paidDays.fold<int>(0, (sum, day) => sum + day.coutTotalPersonnel);

    // Filtrer les paiements de la période
    final paymentsInPeriod = payments.where((payment) {
      return payment.paymentDate
              .isAfter(startDate.subtract(const Duration(days: 1))) &&
          payment.paymentDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    final totalPaymentsAmount =
        paymentsInPeriod.fold<int>(0, (sum, p) => sum + p.totalAmount);

    return ReconciliationReport(
      startDate: startDate,
      endDate: endDate,
      unpaidDays: unpaidDays,
      paidDays: paidDays,
      verifiedDays: verifiedDays,
      totalUnpaidAmount: totalUnpaidAmount,
      totalPaidAmount: totalPaidAmount,
      paymentsInPeriod: paymentsInPeriod,
      totalPaymentsAmount: totalPaymentsAmount,
    );
  }

  /// Vérifie si un paiement existe déjà pour une période donnée.
  bool hasExistingPaymentForPeriod({
    required List<ProductionPayment> payments,
    required String period,
  }) {
    return payments.any((payment) => payment.period == period);
  }

  /// Récupère les paiements existants pour une période.
  List<ProductionPayment> getPaymentsForPeriod({
    required List<ProductionPayment> payments,
    required String period,
  }) {
    return payments.where((payment) => payment.period == period).toList();
  }
}

/// Rapport de réconciliation des paiements.
class ReconciliationReport {
  const ReconciliationReport({
    required this.startDate,
    required this.endDate,
    required this.unpaidDays,
    required this.paidDays,
    required this.verifiedDays,
    required this.totalUnpaidAmount,
    required this.totalPaidAmount,
    required this.paymentsInPeriod,
    required this.totalPaymentsAmount,
  });

  final DateTime startDate;
  final DateTime endDate;
  final List<ProductionDay> unpaidDays;
  final List<ProductionDay> paidDays;
  final List<ProductionDay> verifiedDays;
  final int totalUnpaidAmount;
  final int totalPaidAmount;
  final List<ProductionPayment> paymentsInPeriod;
  final int totalPaymentsAmount;

  /// Nombre total de jours de production.
  int get totalDays => unpaidDays.length + paidDays.length + verifiedDays.length;

  /// Écart entre les montants enregistrés et payés.
  int get discrepancy => totalPaymentsAmount - totalPaidAmount;

  /// Indique s'il y a un écart.
  bool get hasDiscrepancy => discrepancy != 0;
}
