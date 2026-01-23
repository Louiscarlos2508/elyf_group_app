import 'package:flutter_test/flutter_test.dart';
import 'package:elyf_groupe_app/features/gaz/domain/services/gaz_calculation_service.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/gas_sale.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  group('GazCalculationService', () {
    group('filterSalesByDateRange', () {
      test('should filter sales by date range', () {
        // Arrange
        final sales = [
          createTestGasSale(id: 'sale-1', saleDate: DateTime(2026, 1, 15)),
          createTestGasSale(id: 'sale-2', saleDate: DateTime(2026, 1, 20)),
          createTestGasSale(id: 'sale-3', saleDate: DateTime(2026, 2, 1)),
        ];
        final startDate = DateTime(2026, 1, 1);
        final endDate = DateTime(2026, 1, 31);

        // Act
        final result = GazCalculationService.filterSalesByDateRange(
          sales,
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        expect(result.length, equals(2));
        expect(result.map((s) => s.id), containsAll(['sale-1', 'sale-2']));
      });

      test('should return all sales when no date range provided', () {
        // Arrange
        final sales = [
          createTestGasSale(id: 'sale-1'),
          createTestGasSale(id: 'sale-2'),
        ];

        // Act
        final result = GazCalculationService.filterSalesByDateRange(sales);

        // Assert
        expect(result.length, equals(2));
      });
    });

    group('filterSalesByType', () {
      test('should filter sales by type', () {
        // Arrange
        final sales = [
          createTestGasSale(id: 'sale-1', saleType: SaleType.retail),
          createTestGasSale(id: 'sale-2', saleType: SaleType.wholesale),
          createTestGasSale(id: 'sale-3', saleType: SaleType.retail),
        ];

        // Act
        final result = GazCalculationService.filterSalesByType(
          sales,
          SaleType.retail,
        );

        // Assert
        expect(result.length, equals(2));
        expect(result.map((s) => s.id), containsAll(['sale-1', 'sale-3']));
      });
    });

    group('filterWholesaleSales', () {
      test('should filter wholesale sales only', () {
        // Arrange
        final sales = [
          createTestGasSale(id: 'sale-1', saleType: SaleType.retail),
          createTestGasSale(id: 'sale-2', saleType: SaleType.wholesale),
          createTestGasSale(id: 'sale-3', saleType: SaleType.wholesale),
        ];

        // Act
        final result = GazCalculationService.filterWholesaleSales(sales);

        // Assert
        expect(result.length, equals(2));
        expect(result.map((s) => s.id), containsAll(['sale-2', 'sale-3']));
      });
    });

    group('filterRetailSales', () {
      test('should filter retail sales only', () {
        // Arrange
        final sales = [
          createTestGasSale(id: 'sale-1', saleType: SaleType.retail),
          createTestGasSale(id: 'sale-2', saleType: SaleType.wholesale),
          createTestGasSale(id: 'sale-3', saleType: SaleType.retail),
        ];

        // Act
        final result = GazCalculationService.filterRetailSales(sales);

        // Assert
        expect(result.length, equals(2));
        expect(result.map((s) => s.id), containsAll(['sale-1', 'sale-3']));
      });
    });
  });
}
