import '../../domain/repositories/closing_repository.dart';
import '../../domain/repositories/finance_repository.dart';
import '../../domain/repositories/treasury_repository.dart';
import '../../domain/entities/closing.dart';
import '../../domain/entities/expense_record.dart';
import '../../../../shared/domain/entities/treasury_operation.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/logging/app_logger.dart';

class FinancesController {
  FinancesController(
    this._repository,
    this._treasuryRepository,
    this._closingRepository,
    this._enterpriseId,
    this._userId,
  );

  final FinanceRepository _repository;
  final TreasuryRepository _treasuryRepository;
  final ClosingRepository _closingRepository;
  final String _enterpriseId;
  final String _userId;

  Future<FinancesState> fetchRecentExpenses() async {
    // Fetch more expenses to support monthly summary
    final expenses = await _repository.fetchRecentExpenses(limit: 500);
    return FinancesState(expenses: expenses);
  }

  Stream<FinancesState> watchRecentExpenses() {
    // Watch all expenses (filtered by recent if needed, but for dashboard monthly, we need current month)
    // The repo watch methods usually fetch ALL unless filtered.
    // fetchRecentExpenses uses getAllForEnterprise which is ALL.
    return _repository.watchExpenses().map((expenses) {
      expenses.sort((a, b) => b.date.compareTo(a.date));
      return FinancesState(expenses: expenses);
    });
  }

  Stream<List<ExpenseRecord>> watchExpenses() {
    return _repository.watchExpenses();
  }

  Future<String> createExpense(ExpenseRecord expense) async {
    // 1. Vérifier si une session de trésorerie est ouverte
    final currentSession = await _closingRepository.getCurrentSession();
    if (currentSession == null || currentSession.status != ClosingStatus.open) {
      throw ValidationException(
        'Impossible d\'enregistrer une dépense : la session de trésorerie est fermée. '
        'Veuillez ouvrir une session dans la section Trésorerie.',
        'TREASURY_SESSION_CLOSED',
      );
    }

    final id = await _repository.createExpense(expense);
    
    // Record in Treasury
    try {
      await _treasuryRepository.createOperation(TreasuryOperation(
        id: '',
        enterpriseId: _enterpriseId,
        userId: _userId,
        amount: expense.amountCfa,
        type: TreasuryOperationType.removal,
        fromAccount: expense.paymentMethod,
        date: expense.date,
        reason: 'Dépense: ${expense.label}',
        referenceEntityId: id,
        referenceEntityType: 'expense',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    } catch (e) {
      AppLogger.error('Failed to record treasury operation for expense', error: e);
    }
    
    return id;
  }

  Future<void> updateExpense(ExpenseRecord expense) async {
    return await _repository.updateExpense(expense);
  }
}

class FinancesState {
  const FinancesState({required this.expenses});

  final List<ExpenseRecord> expenses;

  int get totalCharges =>
      expenses.fold(0, (value, expense) => value + expense.amountCfa.toInt());
}
