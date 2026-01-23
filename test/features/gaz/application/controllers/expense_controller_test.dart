import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:elyf_groupe_app/features/gaz/application/controllers/expense_controller.dart';
import 'package:elyf_groupe_app/features/gaz/domain/repositories/expense_repository.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/expense.dart';
import '../../../../helpers/test_helpers.dart';

import 'expense_controller_test.mocks.dart';

@GenerateMocks([GazExpenseRepository])
void main() {
  late GazExpenseController controller;
  late MockGazExpenseRepository mockRepository;

  setUp(() {
    mockRepository = MockGazExpenseRepository();
    controller = GazExpenseController(mockRepository);
  });

  group('GazExpenseController', () {
    group('loadExpenses', () {
      test('should load expenses and update state', () async {
        // Arrange
        final expenses = [
          createTestGazExpense(id: 'expense-1'),
          createTestGazExpense(id: 'expense-2'),
        ];
        when(mockRepository.getExpenses(
          from: anyNamed('from'),
          to: anyNamed('to'),
        )).thenAnswer((_) async => expenses);

        // Act
        await controller.loadExpenses();

        // Assert
        expect(controller.expenses, equals(expenses));
        expect(controller.isLoading, isFalse);
        verify(mockRepository.getExpenses(
          from: anyNamed('from'),
          to: anyNamed('to'),
        )).called(1);
      });

      test('should load expenses with date range', () async {
        // Arrange
        final from = DateTime(2026, 1, 1);
        final to = DateTime(2026, 1, 31);
        final expenses = [createTestGazExpense(id: 'expense-1')];
        when(mockRepository.getExpenses(from: from, to: to))
            .thenAnswer((_) async => expenses);

        // Act
        await controller.loadExpenses(from: from, to: to);

        // Assert
        expect(controller.expenses, equals(expenses));
        verify(mockRepository.getExpenses(from: from, to: to)).called(1);
      });

      test('should set isLoading during loading', () async {
        // Arrange
        when(mockRepository.getExpenses(
          from: anyNamed('from'),
          to: anyNamed('to'),
        )).thenAnswer(
          (_) async => Future.delayed(
            const Duration(milliseconds: 100),
            () => <GazExpense>[],
          ),
        );

        // Act
        final loadFuture = controller.loadExpenses();

        // Assert
        expect(controller.isLoading, isTrue);
        await loadFuture;
        expect(controller.isLoading, isFalse);
      });
    });

    group('addExpense', () {
      test('should add expense and reload expenses', () async {
        // Arrange
        final expense = createTestGazExpense(id: 'expense-1');
        when(mockRepository.addExpense(any)).thenAnswer((_) async => {});
        when(mockRepository.getExpenses(
          from: anyNamed('from'),
          to: anyNamed('to'),
        )).thenAnswer((_) async => [expense]);

        // Act
        await controller.addExpense(expense);

        // Assert
        verify(mockRepository.addExpense(expense)).called(1);
        verify(mockRepository.getExpenses(
          from: anyNamed('from'),
          to: anyNamed('to'),
        )).called(1);
      });
    });

    group('updateExpense', () {
      test('should update expense and reload expenses', () async {
        // Arrange
        final expense = createTestGazExpense(id: 'expense-1', amount: 15000.0);
        when(mockRepository.updateExpense(any)).thenAnswer((_) async => {});
        when(mockRepository.getExpenses(
          from: anyNamed('from'),
          to: anyNamed('to'),
        )).thenAnswer((_) async => [expense]);

        // Act
        await controller.updateExpense(expense);

        // Assert
        verify(mockRepository.updateExpense(expense)).called(1);
        verify(mockRepository.getExpenses(
          from: anyNamed('from'),
          to: anyNamed('to'),
        )).called(1);
      });
    });

    group('deleteExpense', () {
      test('should delete expense and reload expenses', () async {
        // Arrange
        const expenseId = 'expense-1';
        when(mockRepository.deleteExpense(expenseId))
            .thenAnswer((_) async => {});
        when(mockRepository.getExpenses(
          from: anyNamed('from'),
          to: anyNamed('to'),
        )).thenAnswer((_) async => []);

        // Act
        await controller.deleteExpense(expenseId);

        // Assert
        verify(mockRepository.deleteExpense(expenseId)).called(1);
        verify(mockRepository.getExpenses(
          from: anyNamed('from'),
          to: anyNamed('to'),
        )).called(1);
      });
    });

    group('getTotalExpenses', () {
      test('should return total expenses from repository', () async {
        // Arrange
        const expectedTotal = 50000.0;
        when(mockRepository.getTotalExpenses(
          from: anyNamed('from'),
          to: anyNamed('to'),
        )).thenAnswer((_) async => expectedTotal);

        // Act
        final result = await controller.getTotalExpenses();

        // Assert
        expect(result, equals(expectedTotal));
        verify(mockRepository.getTotalExpenses(
          from: anyNamed('from'),
          to: anyNamed('to'),
        )).called(1);
      });

      test('should return total expenses with date range', () async {
        // Arrange
        final from = DateTime(2026, 1, 1);
        final to = DateTime(2026, 1, 31);
        const expectedTotal = 30000.0;
        when(mockRepository.getTotalExpenses(from: from, to: to))
            .thenAnswer((_) async => expectedTotal);

        // Act
        final result = await controller.getTotalExpenses(from: from, to: to);

        // Assert
        expect(result, equals(expectedTotal));
        verify(mockRepository.getTotalExpenses(from: from, to: to)).called(1);
      });
    });
  });
}
