import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:elyf_groupe_app/features/immobilier/application/controllers/expense_controller.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/repositories/expense_repository.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/entities/expense.dart';

import 'expense_controller_test.mocks.dart';

@GenerateMocks([PropertyExpenseRepository])
void main() {
  late PropertyExpenseController controller;
  late MockPropertyExpenseRepository mockRepository;

  setUp(() {
    mockRepository = MockPropertyExpenseRepository();
    controller = PropertyExpenseController(mockRepository);
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
