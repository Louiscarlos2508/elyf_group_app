import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:elyf_groupe_app/features/orange_money/domain/entities/liquidity_checkpoint.dart';
import 'package:elyf_groupe_app/features/orange_money/domain/entities/orange_money_settings.dart';
import 'package:elyf_groupe_app/features/orange_money/domain/entities/transaction.dart';
import 'package:elyf_groupe_app/features/orange_money/domain/repositories/liquidity_repository.dart';
import 'package:elyf_groupe_app/features/orange_money/domain/repositories/settings_repository.dart';
import 'package:elyf_groupe_app/features/orange_money/domain/repositories/transaction_repository.dart';
import 'package:elyf_groupe_app/features/orange_money/domain/services/liquidity_service.dart';

import 'liquidity_service_test.mocks.dart';

@GenerateMocks([LiquidityRepository, SettingsRepository, TransactionRepository])
void main() {
  late LiquidityService service;
  late MockLiquidityRepository mockLiquidityRepo;
  late MockSettingsRepository mockSettingsRepo;
  late MockTransactionRepository mockTransactionRepo;

  const enterpriseId = 'ent_123';

  setUp(() {
    mockLiquidityRepo = MockLiquidityRepository();
    mockSettingsRepo = MockSettingsRepository();
    mockTransactionRepo = MockTransactionRepository();
    service = LiquidityService(
      liquidityRepository: mockLiquidityRepo,
      settingsRepository: mockSettingsRepo,
      transactionRepository: mockTransactionRepo,
    );
  });

  group('LiquidityService - calculateTheoreticalLiquidity', () {
    test('calculates correct theoretical liquidity based on transactions', () async {
      // Arrange
      final date = DateTime(2024, 2, 11);
      final morningCash = 100000;
      final morningSim = 200000;

      final transactions = [
        Transaction(
          id: 'tx1',
          enterpriseId: enterpriseId,
          amount: 50000,
          type: TransactionType.cashIn,
          status: TransactionStatus.completed,
          date: date.add(const Duration(hours: 10)),
          commission: 200,
          phoneNumber: '123',
          createdAt: date.add(const Duration(hours: 10)),
        ),
        Transaction(
          id: 'tx2',
          enterpriseId: enterpriseId,
          amount: 30000,
          type: TransactionType.cashOut,
          status: TransactionStatus.completed,
          date: date.add(const Duration(hours: 11)),
          commission: 150,
          phoneNumber: '456',
          createdAt: date.add(const Duration(hours: 11)),
        ),
      ];

      when(mockTransactionRepo.fetchTransactions(
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
      )).thenAnswer((_) async => transactions);

      // Act
      final result = await service.calculateTheoreticalLiquidity(
        enterpriseId: enterpriseId,
        date: date,
        morningCash: morningCash,
        morningSim: morningSim,
      );

      // Assert
      // Cash: 100000 (morning) + 50000 (In) + 200 (Comm) - 30000 (Out) - 150 (Comm) = 120050
      // SIM: 200000 (morning) - 50000 (In) + 30000 (Out) = 180000
      expect(result.cash, 120050);
      expect(result.sim, 180000);
      expect(result.transactionsProcessed, 2);
    });
  });

  group('LiquidityService - createCheckpoint', () {
    test('triggers requiresJustification if discrepancy exceeds threshold', () async {
      // Logic for createCheckpoint with evening type
      // ... (to be implemented with mocks)
    });
  });
}
