import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:elyf_groupe_app/features/immobilier/application/controllers/expense_controller.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/repositories/expense_repository.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/entities/expense.dart';

import 'expense_controller_test.mocks.dart';

import 'package:elyf_groupe_app/features/audit_trail/domain/services/audit_trail_service.dart';

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

@GenerateMocks([PropertyExpenseRepository])
void main() {
  late PropertyExpenseController controller;
  late MockPropertyExpenseRepository mockRepository;
  late MockAuditTrailService mockAuditService;

  setUp(() {
    mockRepository = MockPropertyExpenseRepository();
    mockAuditService = MockAuditTrailService();
    controller = PropertyExpenseController(
      mockRepository,
      mockAuditService,
      'test-enterprise',
      'test-user',
    );
  });

  group('PropertyExpenseController', () {
    group('fetchExpenses', () {
      test('should return list of expenses from repository', () async {
        // Arrange
        final expenses = <PropertyExpense>[];
        when(mockRepository.getAllExpenses()).thenAnswer((_) async => expenses);

        // Act
        final result = await controller.fetchExpenses();

        // Assert
        expect(result, equals(expenses));
        verify(mockRepository.getAllExpenses()).called(1);
      });
    });

    group('createExpense', () {
      test('should create expense via repository', () async {
        // Arrange
        final expense = PropertyExpense(
          id: 'expense-1',
          enterpriseId: 'test-enterprise',
          propertyId: 'property-1',
          amount: 10000,
          expenseDate: DateTime(2026, 1, 1),
          category: ExpenseCategory.maintenance,
          description: 'Test expense',
        );
        when(mockRepository.createExpense(any)).thenAnswer((_) async => expense);

        // Act
        final result = await controller.createExpense(expense);

        // Assert
        expect(result, equals(expense));
        verify(mockRepository.createExpense(expense)).called(1);
      });
    });
  });
}
