import 'package:flutter_test/flutter_test.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/adapters/pack_stock_adapter.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/repositories/stock_repository.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/repositories/customer_repository.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/sale.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/stock_movement.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/services/sale_service.dart';

// Mock implementations
class MockStockRepository implements StockRepository {
  final Map<String, int> _stock = {};

  void setStock(String productId, int quantity) {
    _stock[productId] = quantity;
  }

  @override
  Future<int> getStock(String productId) async {
    return _stock[productId] ?? 0;
  }

  @override
  Future<void> updateStock(String productId, int quantity) async {
    _stock[productId] = quantity;
  }

  @override
  Future<void> recordMovement(StockMovement movement) async {
    // Mock implementation
  }

  @override
  Future<List<StockMovement>> fetchMovements({
    String? productId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return [];
  }

  @override
  Future<List<String>> getLowStockAlerts(int thresholdPercent) async {
    return [];
  }
}

class MockPackStockAdapter implements PackStockAdapter {
  @override
  Future<int> getPackStock({String? productId}) async => 0;

  @override
  Future<void> recordPackExit(
    int quantity, {
    String? productId,
    String? reason,
    String? notes,
  }) async {
    // Mock implementation
  }
}

class MockCustomerRepository implements CustomerRepository {
  @override
  Future<List<CustomerSummary>> fetchCustomers() async {
    return [];
  }

  @override
  Future<CustomerSummary?> getCustomer(String id) async {
    return null;
  }

  @override
  Future<String> createCustomer(
    String name,
    String phone, {
    String? cnib,
  }) async {
    return 'customer-${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<List<Sale>> fetchCustomerHistory(String customerId) async {
    return [];
  }
}

void main() {
  group('SaleService', () {
    late SaleService service;
    late MockStockRepository mockStockRepository;
    late MockCustomerRepository mockCustomerRepository;

    setUp(() {
      mockStockRepository = MockStockRepository();
      mockCustomerRepository = MockCustomerRepository();
      service = SaleService(
        stockRepository: mockStockRepository,
        customerRepository: mockCustomerRepository,
        packStockAdapter: MockPackStockAdapter(),
      );
    });

    group('validateSale', () {
      test('should return null when stock is sufficient', () async {
        mockStockRepository.setStock('product1', 100);

        final result = await service.validateSale(
          productId: 'product1',
          quantity: 50,
          totalPrice: 1000,
          amountPaid: 1000,
        );

        expect(result, isNull);
      });

      test('should return error when stock is insufficient', () async {
        mockStockRepository.setStock('product1', 10);

        final result = await service.validateSale(
          productId: 'product1',
          quantity: 50,
          totalPrice: 1000,
          amountPaid: 1000,
        );

        expect(result, contains('Stock insuffisant'));
      });
    });

    group('getCurrentStock', () {
      test('should return current stock for product', () async {
        mockStockRepository.setStock('product1', 100);

        final result = await service.getCurrentStock('product1');

        expect(result, equals(100));
      });
    });

    group('getOrCreateCustomerId', () {
      test('should return provided customerId', () async {
        final result = await service.getOrCreateCustomerId(
          customerId: 'customer123',
          customerName: 'Test Customer',
        );

        expect(result, equals('customer123'));
      });

      test(
        'should generate ID when customerName provided but no customerId',
        () async {
          final result = await service.getOrCreateCustomerId(
            customerName: 'Test Customer',
          );

          expect(result, startsWith('customer-'));
        },
      );

      test('should generate anonymous ID when no customer info', () async {
        final result = await service.getOrCreateCustomerId();

        expect(result, startsWith('anonymous-'));
      });
    });

    group('determineSaleStatus', () {
      test('should return fullyPaid when fully paid', () {
        final result = service.determineSaleStatus(1000, 1000);
        expect(result, equals(SaleStatus.fullyPaid));
      });

      test('should return validated when partially paid', () {
        final result = service.determineSaleStatus(1000, 500);
        expect(result, equals(SaleStatus.validated));
      });

      test('should return validated when not paid', () {
        final result = service.determineSaleStatus(1000, 0);
        expect(result, equals(SaleStatus.validated));
      });
    });

    group('validateSale', () {
      test('should return error when productId is null', () async {
        final result = await service.validateSale(
          productId: null,
          quantity: 10,
          totalPrice: 1000,
          amountPaid: 1000,
        );

        expect(result, equals('Veuillez sélectionner un produit'));
      });

      test('should return error when quantity is null', () async {
        final result = await service.validateSale(
          productId: 'product1',
          quantity: null,
          totalPrice: 1000,
          amountPaid: 1000,
        );

        expect(result, equals('Veuillez remplir tous les champs'));
      });

      test('should return error when totalPrice is null', () async {
        final result = await service.validateSale(
          productId: 'product1',
          quantity: 10,
          totalPrice: null,
          amountPaid: 1000,
        );

        expect(result, equals('Veuillez remplir tous les champs'));
      });

      test('should return error when amountPaid is null', () async {
        final result = await service.validateSale(
          productId: 'product1',
          quantity: 10,
          totalPrice: 1000,
          amountPaid: null,
        );

        expect(result, equals('Veuillez remplir tous les champs'));
      });

      test('should return error when stock is insufficient', () async {
        mockStockRepository.setStock('product1', 5);

        final result = await service.validateSale(
          productId: 'product1',
          quantity: 10,
          totalPrice: 1000,
          amountPaid: 1000,
        );

        expect(result, equals('Stock insuffisant. Disponible: 5'));
      });

      test('should return null when sale is valid', () async {
        mockStockRepository.setStock('product1', 100);

        final result = await service.validateSale(
          productId: 'product1',
          quantity: 10,
          totalPrice: 1000,
          amountPaid: 1000,
        );

        expect(result, isNull);
      });
    });
  });
}
