import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:elyf_groupe_app/features/orange_money/domain/services/commission_service.dart';
import 'package:elyf_groupe_app/features/orange_money/domain/entities/commission.dart';
import 'package:elyf_groupe_app/features/orange_money/domain/entities/orange_money_settings.dart';
import 'package:elyf_groupe_app/features/orange_money/domain/repositories/commission_repository.dart';
import 'package:elyf_groupe_app/features/orange_money/domain/repositories/settings_repository.dart';
import 'package:elyf_groupe_app/features/orange_money/domain/repositories/transaction_repository.dart';

// Generate Mocks
@GenerateMocks([CommissionRepository, SettingsRepository, TransactionRepository])
import 'commission_workflow_test.mocks.dart';

void main() {
  late CommissionService commissionService;
  late MockCommissionRepository mockCommissionRepo;
  late MockSettingsRepository mockSettingsRepo;
  late MockTransactionRepository mockTransactionRepo;

  setUp(() {
    mockCommissionRepo = MockCommissionRepository();
    mockSettingsRepo = MockSettingsRepository();
    mockTransactionRepo = MockTransactionRepository();
    
    commissionService = CommissionService(
      commissionRepository: mockCommissionRepo,
      settingsRepository: mockSettingsRepo,
      transactionRepository: mockTransactionRepo,
    );
  });

  group('CommissionService Verification', () {
    test('declareCommission should update status to declared and calculate discrepancy', () async {
      // Arrange
      final initialCommission = Commission(
        id: 'comm_123',
        enterpriseId: 'ent_1',
        period: '2024-02',
        estimatedAmount: 10000,
        transactionsCount: 50,
        status: CommissionStatus.estimated,
        createdAt: DateTime.now(),
      );
      
      final settings = OrangeMoneySettings(
        id: 'ent_1',
        enterpriseId: 'ent_1',
        commissionDiscrepancyMinor: 5.0,
      );

      when(mockCommissionRepo.getCommission('comm_123'))
          .thenAnswer((_) async => initialCommission);
      when(mockSettingsRepo.getSettings('ent_1'))
          .thenAnswer((_) async => settings);
      when(mockCommissionRepo.updateCommission(any))
          .thenAnswer((_) async => Future.value());

      // Act
      final result = await commissionService.declareCommission(
        commissionId: 'comm_123',
        declaredAmount: 10200, // 2% discrepancy (minor)
        smsProofUrl: 'http://proof.url',
        declaredBy: 'agent_1',
      );

      // Assert
      expect(result.status, CommissionStatus.declared);
      expect(result.declaredAmount, 10200);
      expect(result.discrepancy, 200);
      expect(result.discrepancyPercentage, 2.0);
      expect(result.discrepancyStatus, DiscrepancyStatus.ecartMineur);
      
      // Verification with argument matcher to avoid "Null is not subtype of Commission"
      verify(mockCommissionRepo.updateCommission(
        argThat(isA<Commission>()),
      )).called(1);
    });

    test('validateCommission should update status to validated', () async {
      // Arrange
      final declaredCommission = Commission(
        id: 'comm_123',
        enterpriseId: 'ent_1',
        period: '2024-02',
        estimatedAmount: 10000,
        transactionsCount: 50,
        declaredAmount: 10200,
        status: CommissionStatus.declared,
        createdAt: DateTime.now(),
      );

      when(mockCommissionRepo.getCommission('comm_123'))
          .thenAnswer((_) async => declaredCommission);
      when(mockCommissionRepo.updateCommission(any))
          .thenAnswer((_) async => Future.value());

      // Act
      final result = await commissionService.validateCommission(
        commissionId: 'comm_123',
        validatedBy: 'supervisor_1',
        notes: 'Verified OK',
      );

      // Assert
      expect(result.status, CommissionStatus.validated);
      expect(result.validatedBy, 'supervisor_1');
      expect(result.notes, 'Verified OK');
      
      verify(mockCommissionRepo.updateCommission(
        argThat(isA<Commission>()),
      )).called(1);
    });
  });
}
