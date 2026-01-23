import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/payment_status.dart';
import '../../domain/entities/production_payment.dart';
import '../../domain/entities/salary_payment.dart';
import '../../domain/entities/worker_monthly_stat.dart';
import '../../domain/repositories/daily_worker_repository.dart';
import '../../domain/repositories/production_session_repository.dart';
import '../../domain/repositories/salary_repository.dart';

class SalaryController {
  SalaryController(
    this._repository, {
    required ProductionSessionRepository productionSessionRepository,
    required DailyWorkerRepository dailyWorkerRepository,
  })  : _productionSessionRepository = productionSessionRepository,
        _dailyWorkerRepository = dailyWorkerRepository;

  final SalaryRepository _repository;
  final ProductionSessionRepository _productionSessionRepository;
  final DailyWorkerRepository _dailyWorkerRepository;

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
    // Créer le paiement
    final paymentId = await _repository.createProductionPayment(payment);

    // Si des jours sources sont spécifiés, les marquer comme payés
    if (payment.sourceProductionDayIds.isNotEmpty) {
      await _markProductionDaysAsPaid(
        payment.sourceProductionDayIds,
        paymentId,
        payment.paymentDate,
      );
    }

    return paymentId;
  }

  /// Marque les jours de production comme payés.
  Future<void> _markProductionDaysAsPaid(
    List<String> dayIds,
    String paymentId,
    DateTime paymentDate,
  ) async {
    try {
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
    } catch (e, st) {
      // Log l'erreur mais ne bloque pas la création du paiement
      AppLogger.error(
        'Erreur lors de la mise à jour des statuts de paiement: $e',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<String> createMonthlySalaryPayment(SalaryPayment payment) async {
    return await _repository.createMonthlySalaryPayment(payment);
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

    // 4. Agréger les données par ouvrier
    final statsMap = <String, WorkerMonthlyStat>{};

    for (final day in daysInMonth) {
      for (final workerId in day.personnelIds) {
        final worker = workerMap[workerId];
        final workerName = worker?.name ?? 'Ouvrier inconnu ($workerId)';
        
        // Le coût par personne pour ce jour (stocké dans le jour)
        final dailyEarned = day.salaireJournalierParPersonne;
        
        final isPaid = day.paymentStatus == PaymentStatus.paid || 
                       day.paymentStatus == PaymentStatus.verified;

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
          daysPaid: current.daysPaid + (isPaid ? 1 : 0),
          amountPaid: current.amountPaid + (isPaid ? dailyEarned : 0),
          dailyRate: current.dailyRate, // Garder le dernier connu
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
