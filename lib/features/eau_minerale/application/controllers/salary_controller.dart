import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/employee.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/payment_status.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/production_payment.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/salary_payment.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/daily_worker.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/worker_monthly_stat.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/expense_record.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/repositories/daily_worker_repository.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/repositories/production_session_repository.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/repositories/salary_repository.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/repositories/treasury_repository.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/repositories/finance_repository.dart';
import 'package:elyf_groupe_app/shared/domain/entities/treasury_operation.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';
import 'package:elyf_groupe_app/core/logging/app_logger.dart';

class SalaryController {
  SalaryController(
    this._repository, {
    required ProductionSessionRepository productionSessionRepository,
    required DailyWorkerRepository dailyWorkerRepository,
    required TreasuryRepository treasuryRepository,
    required FinanceRepository financeRepository,
    required String enterpriseId,
    required String userId,
  })  : _productionSessionRepository = productionSessionRepository,
        _dailyWorkerRepository = dailyWorkerRepository,
        _treasuryRepository = treasuryRepository,
        _financeRepository = financeRepository,
        _enterpriseId = enterpriseId,
        _userId = userId;

  final SalaryRepository _repository;
  final ProductionSessionRepository _productionSessionRepository;
  final DailyWorkerRepository _dailyWorkerRepository;
  final TreasuryRepository _treasuryRepository;
  final FinanceRepository _financeRepository;
  final String _enterpriseId;
  final String _userId;

  Future<SalaryState> fetchSalaries() async {
    final fixedEmployees = await _repository.fetchFixedEmployees();
    final productionPayments = await _repository.fetchProductionPayments();
    final monthlySalaryPayments = await _repository
        .fetchMonthlySalaryPayments();
    return SalaryState(
      fixedEmployees: fixedEmployees,
      productionPayments: productionPayments,
      monthlySalaryPayments: monthlySalaryPayments,
    );
  }

  Future<String> createFixedEmployee(Employee employee) async {
    return await _repository.createFixedEmployee(employee);
  }

  Future<void> updateEmployee(Employee employee) async {
    return await _repository.updateEmployee(employee);
  }

  Future<void> deleteEmployee(String employeeId) async {
    return await _repository.deleteEmployee(employeeId);
  }

  Future<String> createProductionPayment(ProductionPayment payment) async {
    // 1. Créer le paiement (Source de vérité financière)
    final paymentId = await _repository.createProductionPayment(payment);

    try {
      // 2. Orchestration financière (Trésorerie + Dépenses)
      await _recordFinancialsForSalary(
        amount: payment.totalAmount,
        date: payment.paymentDate,
        label: 'Paye Production: ${payment.period}',
        referenceId: paymentId,
        referenceType: 'production_payment',
        notes: payment.notes,
      );

      // 3. Tenter de mettre à jour les jours de production (Source de vérité opérationnelle)
      if (payment.sourceProductionDayIds.isNotEmpty) {
        await _markProductionDaysAsPaid(
          payment.sourceProductionDayIds,
          paymentId,
          payment.paymentDate,
        );
      }
    } catch (e, st) {
      // ROLLBACK: Si la mise à jour des jours échoue, on annule le paiement pour éviter l'incohérence.
      AppLogger.error(
        'Erreur lors de la mise à jour des statuts. Annulation du paiement $paymentId.',
        error: e,
        stackTrace: st,
      );
      
      try {
        await _repository.deleteProductionPayment(paymentId);
      } catch (rollbackError) {
        AppLogger.error(
          'CRITIQUE: Echec du rollback pour le paiement $paymentId',
          error: rollbackError,
        );
      }
      
      rethrow;
    }

    return paymentId;
  }

  /// Marque les jours de production comme payés.
  Future<void> _markProductionDaysAsPaid(
    List<String> dayIds,
    String paymentId,
    DateTime paymentDate,
  ) async {
    // Récupérer toutes les sessions
    final sessions = await _productionSessionRepository.fetchSessions();

    // Pour chaque session, vérifier si elle contient des jours à marquer
    for (final session in sessions) {
      var hasChanges = false;
      final updatedDays = session.productionDays.map((day) {
        if (dayIds.contains(day.id)) {
          hasChanges = true;
          return day.copyWith(
            paymentStatus: PaymentStatus.paid,
            paymentId: paymentId,
            datePaiement: paymentDate,
          );
        }
        return day;
      }).toList();

      // Si la session a été modifiée, la mettre à jour
      if (hasChanges) {
        final updatedSession = session.copyWith(
          productionDays: updatedDays,
        );
        await _productionSessionRepository.updateSession(updatedSession);
      }
    }
  }

  Future<String> createMonthlySalaryPayment(SalaryPayment payment) async {
    final paymentId = await _repository.createMonthlySalaryPayment(payment);
    
    try {
      await _recordFinancialsForSalary(
        amount: payment.amount,
        date: payment.date,
        label: 'Salaire: ${payment.employeeName} (${payment.period})',
        referenceId: paymentId,
        referenceType: 'salary_payment',
        notes: payment.notes,
      );
    } catch (e) {
      AppLogger.error('Erreur lors de l\'enregistrement financier du salaire', error: e);
    }

    return paymentId;
  }

  Future<void> _recordFinancialsForSalary({
    required int amount,
    required DateTime date,
    required String label,
    required String referenceId,
    required String referenceType,
    String? notes,
  }) async {
    try {
      // 1. Enregistrer dans la trésorerie (Défaut: Cash pour les salaires)
      await _treasuryRepository.createOperation(TreasuryOperation(
        id: '',
        enterpriseId: _enterpriseId,
        userId: _userId,
        amount: amount,
        type: TreasuryOperationType.removal,
        fromAccount: PaymentMethod.cash,
        date: date,
        reason: label,
        referenceEntityId: referenceId,
        referenceEntityType: referenceType,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      // 2. Enregistrer comme dépense
      await _financeRepository.createExpense(ExpenseRecord(
        id: '',
        enterpriseId: _enterpriseId,
        label: label,
        amountCfa: amount,
        date: date,
        paymentMethod: PaymentMethod.cash,
        category: ExpenseCategory.salaires,
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    } catch (e) {
      AppLogger.error('Failed to record financials for salary payment', error: e);
    }
  }

  /// Récupère les statistiques mensuelles par ouvrier pour un mois donné.
  Future<List<WorkerMonthlyStat>> fetchWorkerMonthlyStats(DateTime month) async {
    // 1. Récupérer toutes les sessions qui contiennent des jours de ce mois
    // On prend une marge pour être sûr (le filtre exact se fera sur les ProductionDay)
    final sessions = await _productionSessionRepository.fetchSessions(
      startDate: DateTime(month.year, month.month, 1),
      endDate: DateTime(month.year, month.month + 1, 0),
    );

    // 2. Extraire les jours de production du mois concerné
    final daysInMonth = sessions
        .expand((s) => s.productionDays)
        .where((d) => d.date.year == month.year && d.date.month == month.month)
        .toList();

    // 3. Récupérer tous les ouvriers pour avoir les noms
    final allWorkers = await _dailyWorkerRepository.fetchAllWorkers();
    final workerMap = {for (var w in allWorkers) w.id: w};

    // 3. Récupérer tous les paiements de production
    final allPayments = await _repository.fetchProductionPayments();
    
    // 4. Construire un mapping des paiements effectués par ouvrier et par jour
    // Key: id_{workerId}_{dayId} ou name_{workerName}_{dayId}
    final paidWorkerDayKeys = <String>{};
    for (final payment in allPayments) {
      final dayIds = payment.sourceProductionDayIds;
      for (final person in payment.persons) {
        for (final dayId in dayIds) {
          if (person.workerId != null) {
            paidWorkerDayKeys.add('id_${person.workerId}_$dayId');
          } else {
            paidWorkerDayKeys.add('name_${person.name}_$dayId');
          }
        }
      }
    }

    // 6. Agréger les données par ouvrier
    final statsMap = <String, WorkerMonthlyStat>{};

    for (final day in daysInMonth) {
      for (final workerId in day.personnelIds) {
        DailyWorker? worker = workerMap[workerId];
        
        // Le coût par personne pour ce jour (stocké dans le jour)
        final dailyEarned = day.salaireJournalierParPersonne;
        
        // Tenter de résoudre le worker s'il n'est pas dans la map initiale
        if (worker == null) {
           worker = await _dailyWorkerRepository.fetchWorkerById(workerId);
           if (worker != null) {
             workerMap[workerId] = worker;
           }
        }
        
        final workerName = worker?.name ?? 'Ouvrier inconnu ($workerId)';

        // VÉRIFICATION DU PAIEMENT INDIVIDUEL
        final isPaidById = paidWorkerDayKeys.contains('id_${workerId}_${day.id}');
        final isPaidByName = paidWorkerDayKeys.contains('name_${workerName}_${day.id}');
        final isStatutoryPaid = isPaidById || isPaidByName;

        if (!statsMap.containsKey(workerId)) {
          statsMap[workerId] = WorkerMonthlyStat(
            workerId: workerId,
            workerName: workerName,
            daysWorked: 0,
            totalEarned: 0,
            daysPaid: 0,
            amountPaid: 0,
            dailyRate: worker?.salaireJournalier,
          );
        }

        final current = statsMap[workerId]!;
        statsMap[workerId] = WorkerMonthlyStat(
          workerId: current.workerId,
          workerName: current.workerName,
          daysWorked: current.daysWorked + 1,
          totalEarned: current.totalEarned + dailyEarned,
          daysPaid: current.daysPaid + (isStatutoryPaid ? 1 : 0),
          amountPaid: current.amountPaid + (isStatutoryPaid ? dailyEarned : 0),
          dailyRate: current.dailyRate,
        );
      }
    }

    // 5. Convertir en liste et trier par nom
    final stats = statsMap.values.toList();
    stats.sort((a, b) => a.workerName.compareTo(b.workerName));

    return stats;
  }
}

class SalaryState {
  const SalaryState({
    required this.fixedEmployees,
    required this.productionPayments,
    required this.monthlySalaryPayments,
  });

  final List<Employee> fixedEmployees;
  final List<ProductionPayment> productionPayments;
  final List<SalaryPayment> monthlySalaryPayments;

  int get fixedEmployeesCount => fixedEmployees.length;
  int get productionPaymentsCount => productionPayments.length;
  int get uniqueProductionWorkers {
    final names = <String>{};
    for (final payment in productionPayments) {
      for (final person in payment.persons) {
        names.add(person.name);
      }
    }
    return names.length;
  }

  int get currentMonthTotal {
    final now = DateTime.now();
    final productionTotal = productionPayments
        .where(
          (p) =>
              p.paymentDate.year == now.year &&
              p.paymentDate.month == now.month,
        )
        .fold(0, (sum, p) => sum + p.totalAmount);
    final monthlyPaymentsList = monthlySalaryPayments;
    final monthlyTotal = monthlyPaymentsList
        .where((p) => p.date.year == now.year && p.date.month == now.month)
        .fold(0, (sum, p) => sum + p.amount);
    return productionTotal + monthlyTotal;
  }
}
