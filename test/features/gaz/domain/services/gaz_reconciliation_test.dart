import 'package:flutter_test/flutter_test.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/gaz_session.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/cylinder.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/cylinder_stock.dart';
import 'package:elyf_groupe_app/features/gaz/domain/services/gaz_calculation_service.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';

void main() {
  group('Gaz Reconciliation Tests', () {
    final cylinder12kg = Cylinder(
      id: 'c12',
      weight: 12,
      buyPrice: 5000,
      sellPrice: 6000,
      depositPrice: 2000,
      stock: 0,
      enterpriseId: 'ent1',
      moduleId: 'gaz',
    );

    test('calculateDailyReconciliation should calculate both full and empty theoretical stock', () {
      // Setup Stocks: 10 Full 12kg, 5 Empty 12kg
      final stocks = [
        CylinderStock(
          id: 's1',
          cylinderId: 'c12',
          weight: 12,
          status: CylinderStatus.full,
          quantity: 10,
          enterpriseId: 'ent1',
          updatedAt: DateTime.now(),
        ),
        CylinderStock(
          id: 's2',
          cylinderId: 'c12',
          weight: 12,
          status: CylinderStatus.emptyAtStore,
          quantity: 5,
          enterpriseId: 'ent1',
          updatedAt: DateTime.now(),
        ),
      ];

      final date = DateTime.now();
      
      // Calculate
      final metrics = GazCalculationService.calculateDailyReconciliation(
        date: date,
        allSales: [],
        allExpenses: [],
        cylinders: [cylinder12kg],
        stocks: stocks,
      );

      // Assert
      expect(metrics.theoreticalStock[12], 10);
      expect(metrics.theoreticalEmptyStock[12], 5);
    });

    test('GazSession.fromMetrics should calculate discrepancies for both types', () {
      final metrics = ReconciliationMetrics(
        date: DateTime.now(),
        totalSales: 10000,
        totalExpenses: 0,
        theoreticalCash: 10000,
        salesByPaymentMethod: {PaymentMethod.cash: 10000},
        salesByCylinderWeight: {12: 5},
        theoreticalStock: {12: 10},
        theoreticalEmptyStock: {12: 5},
      );

      // We report 8 Full (Discrepancy -2) and 6 Empty (Discrepancy +1)
      final session = GazSession.fromMetrics(
        id: 'sess1',
        enterpriseId: 'ent1',
        metrics: metrics,
        physicalCash: 10000,
        closedBy: 'user1',
        physicalStock: {12: 8},
        physicalEmptyStock: {12: 6},
      );

      expect(session.stockReconciliation[12], -2);
      expect(session.emptyStockReconciliation[12], 1);
    });
  });
}
