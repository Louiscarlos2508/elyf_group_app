import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:elyf_groupe_app/features/orange_money/application/controllers/orange_money_controller.dart';
import 'package:elyf_groupe_app/features/orange_money/domain/repositories/transaction_repository.dart';
import 'package:elyf_groupe_app/features/orange_money/domain/repositories/liquidity_repository.dart';
import 'package:elyf_groupe_app/features/orange_money/domain/entities/transaction.dart';
import 'package:elyf_groupe_app/features/orange_money/domain/entities/liquidity_checkpoint.dart';
import 'package:elyf_groupe_app/core/errors/app_exceptions.dart';
import 'package:elyf_groupe_app/features/audit_trail/domain/services/audit_trail_service.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {
  @override
  Future<String> createTransaction(Transaction? transaction) => super.noSuchMethod(
        Invocation.method(#createTransaction, [transaction]),
        returnValue: Future.value('txn_id'),
      );

  @override
  Future<List<Transaction>> fetchTransactions({
    DateTime? startDate,
    DateTime? endDate,
    TransactionType? type,
    TransactionStatus? status,
  }) => super.noSuchMethod(
        Invocation.method(#fetchTransactions, [], {
          #startDate: startDate,
          #endDate: endDate,
          #type: type,
          #status: status,
        }),
        returnValue: Future.value(<Transaction>[]),
      );
}

class MockLiquidityRepository extends Mock implements LiquidityRepository {
  @override
  Future<LiquidityCheckpoint?> getTodayCheckpoint(String? enterpriseId) =>
      super.noSuchMethod(
        Invocation.method(#getTodayCheckpoint, [enterpriseId]),
        returnValue: Future.value(null),
      );
}

class MockAuditTrailService extends Mock implements AuditTrailService {
  @override
  Future<String> logAction({
    required String? enterpriseId,
    required String? userId,
    required String? module,
    required String? action,
    required String? entityId,
    required String? entityType,
    Map<String, dynamic>? metadata,
  }) =>
      super.noSuchMethod(
        Invocation.method(#logAction, [], {
          #enterpriseId: enterpriseId,
          #userId: userId,
          #module: module,
          #action: action,
          #entityId: entityId,
          #entityType: entityType,
          #metadata: metadata,
        }),
        returnValue: Future.value('test-log-id'),
      );
}

void main() {
  late OrangeMoneyController controller;
  late MockTransactionRepository mockTxnRepo;
  late MockLiquidityRepository mockLiquidityRepo;
  late MockAuditTrailService mockAuditService;

  const enterpriseId = 'ent_1';

  setUp(() {
    mockTxnRepo = MockTransactionRepository();
    mockLiquidityRepo = MockLiquidityRepository();
    mockAuditService = MockAuditTrailService();
    controller = OrangeMoneyController(
      mockTxnRepo, 
      mockLiquidityRepo,
      mockAuditService,
    );
  });

  group('OrangeMoneyController - createTransactionFromInput', () {
    test('validates phone number', () async {
      expect(
        () => controller.createTransactionFromInput(
          enterpriseId: enterpriseId,
          type: TransactionType.cashIn,
          phoneNumber: '123', // Invalid
          amountStr: '1000',
        ),
        throwsA(isA<BusinessException>().having((e) => e.message, 'message',
            contains('Veuillez entrer un numéro Burkina'))),
      );
    });

    test('validates amount', () async {
      expect(
        () => controller.createTransactionFromInput(
          enterpriseId: enterpriseId,
          type: TransactionType.cashIn,
          phoneNumber: '70000000',
          amountStr: 'abc', // Invalid
        ),
        throwsA(isA<BusinessException>().having(
            (e) => e.message, 'message', contains('Montant invalide'))),
      );
    });

    test('blocks Cash-In if SIM balance is insufficient', () async {
      final checkpoint = LiquidityCheckpoint(
        id: 'cp_1',
        enterpriseId: enterpriseId,
        date: DateTime.now(),
        type: LiquidityCheckpointType.morning,
        amount: 2000,
        simAmount: 500, // Only 500 on SIM
        cashAmount: 1500,
      );

      when(mockLiquidityRepo.getTodayCheckpoint(enterpriseId))
          .thenAnswer((_) async => checkpoint);

      expect(
        () => controller.createTransactionFromInput(
          enterpriseId: enterpriseId,
          type: TransactionType.cashIn,
          phoneNumber: '70000000',
          amountStr: '1000', // Requesting 1000
        ),
        throwsA(isA<BusinessException>().having((e) => e.message, 'message',
            contains('Solde SIM insuffisant pour ce Cash-In'))),
      );
    });

    test('blocks Cash-Out if CASH balance is insufficient', () async {
      final checkpoint = LiquidityCheckpoint(
        id: 'cp_1',
        enterpriseId: enterpriseId,
        date: DateTime.now(),
        type: LiquidityCheckpointType.morning,
        amount: 2000,
        simAmount: 1500,
        cashAmount: 300, // Only 300 CASH
      );

      when(mockLiquidityRepo.getTodayCheckpoint(enterpriseId))
          .thenAnswer((_) async => checkpoint);

      expect(
        () => controller.createTransactionFromInput(
          enterpriseId: enterpriseId,
          type: TransactionType.cashOut,
          phoneNumber: '70000000',
          amountStr: '500', // Requesting 500
        ),
        throwsA(isA<BusinessException>().having((e) => e.message, 'message',
            contains('Encaisse insuffisante pour ce Cash-Out'))),
      );
    });

    test('allows transaction if liquidity is sufficient', () async {
      final checkpoint = LiquidityCheckpoint(
        id: 'cp_1',
        enterpriseId: enterpriseId,
        date: DateTime.now(),
        type: LiquidityCheckpointType.morning,
        amount: 10000,
        simAmount: 5000,
        cashAmount: 5000,
      );

      when(mockLiquidityRepo.getTodayCheckpoint(enterpriseId))
          .thenAnswer((_) async => checkpoint);
      when(mockTxnRepo.createTransaction(any))
          .thenAnswer((_) async => 'txn_123');

      final result = await controller.createTransactionFromInput(
        enterpriseId: enterpriseId,
        type: TransactionType.cashIn,
        phoneNumber: '70000000',
        amountStr: '1000',
      );

      expect(result, 'txn_123');
      verify(mockTxnRepo.createTransaction(any)).called(1);
    });

    test('allows transaction if no checkpoint for today yet (audit behavior)',
        () async {
      when(mockLiquidityRepo.getTodayCheckpoint(enterpriseId))
          .thenAnswer((_) async => null);
      when(mockTxnRepo.createTransaction(any))
          .thenAnswer((_) async => 'txn_123');

      final result = await controller.createTransactionFromInput(
        enterpriseId: enterpriseId,
        type: TransactionType.cashIn,
        phoneNumber: '70000000',
        amountStr: '1000',
      );

      expect(result, 'txn_123');
    });
  group('findCustomerByPhoneNumber', () {
    test('returns customer name if transaction exists', () async {
      final txn = Transaction(
        id: 't1',
        enterpriseId: enterpriseId,
        type: TransactionType.cashIn,
        amount: 1000,
        phoneNumber: '+22670000000',
        date: DateTime.now(),
        status: TransactionStatus.completed,
        customerName: 'Alice',
      );

      when(mockTxnRepo.fetchTransactions()).thenAnswer((_) async => [txn]);

      final name = await controller.findCustomerByPhoneNumber('70000000');
      expect(name, 'Alice');
    });

    test('returns null if transaction does not exist', () async {
      when(mockTxnRepo.fetchTransactions()).thenAnswer((_) async => []);

      final name = await controller.findCustomerByPhoneNumber('70000000');
      expect(name, isNull);
    });
  });
  });
}
