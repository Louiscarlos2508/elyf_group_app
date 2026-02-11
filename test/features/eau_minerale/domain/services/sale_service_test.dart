import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/services/sale_service.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/repositories/stock_repository.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/repositories/customer_repository.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/repositories/product_repository.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/adapters/pack_stock_adapter.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/sale.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/product.dart';
// import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/stock_movement.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/pack_constants.dart';

class MockStockRepository extends Mock implements StockRepository {
  @override
  Future<int> getStock(String productId) => super.noSuchMethod(
        Invocation.method(#getStock, [productId]),
        returnValue: Future.value(0),
      );
}

class MockCustomerRepository extends Mock implements CustomerRepository {}

class MockPackStockAdapter extends Mock implements PackStockAdapter {
  @override
  Future<int> getPackStock({String? productId}) => super.noSuchMethod(
        Invocation.method(#getPackStock, [], {#productId: productId}),
        returnValue: Future.value(0),
      );
}

class MockProductRepository extends Mock implements ProductRepository {
  @override
  Future<Product?> getProduct(String id) => super.noSuchMethod(
        Invocation.method(#getProduct, [id]),
        returnValue: Future.value(null),
      );
}

void main() {
  late SaleService saleService;
  late MockStockRepository mockStockRepo;
  late MockCustomerRepository mockCustomerRepo;
  late MockPackStockAdapter mockPackAdapter;
  late MockProductRepository mockProductRepo;

  setUp(() {
    mockStockRepo = MockStockRepository();
    mockCustomerRepo = MockCustomerRepository();
    mockPackAdapter = MockPackStockAdapter();
    mockProductRepo = MockProductRepository();
    saleService = SaleService(
      stockRepository: mockStockRepo,
      customerRepository: mockCustomerRepo,
      packStockAdapter: mockPackAdapter,
      productRepository: mockProductRepo,
    );
  });

  group('SaleService - determineSaleStatus', () {
    test('returns fullyPaid when amount matches total', () {
      final status = saleService.determineSaleStatus(1000, 1000);
      expect(status, SaleStatus.fullyPaid);
    });

    test('returns validated when amount is less than total', () {
      final status = saleService.determineSaleStatus(1000, 500);
      expect(status, SaleStatus.validated);
    });
  });

  group('SaleService - getCurrentStock', () {
    test('uses PackStockAdapter for packProductId', () async {
      when(mockPackAdapter.getPackStock(productId: packProductId))
          .thenAnswer((_) async => 50);

      final stock = await saleService.getCurrentStock(packProductId);
      expect(stock, 50);
      verify(mockPackAdapter.getPackStock(productId: packProductId)).called(1);
    });

    test('uses PackStockAdapter for finished goods', () async {
      final pf = Product(
        id: 'PF1',
        name: 'PF1',
        type: ProductType.finishedGood,
        unitPrice: 500,
        unit: 'unit',
      );
      when(mockProductRepo.getProduct('PF1')).thenAnswer((_) async => pf);
      when(mockPackAdapter.getPackStock(productId: 'PF1'))
          .thenAnswer((_) async => 30);

      final stock = await saleService.getCurrentStock('PF1');
      expect(stock, 30);
    });

    test('uses StockRepository for raw materials', () async {
      final mp = Product(
        id: 'MP1',
        name: 'MP1',
        type: ProductType.rawMaterial,
        unitPrice: 100,
        unit: 'kg',
      );
      when(mockProductRepo.getProduct('MP1')).thenAnswer((_) async => mp);
      when(mockStockRepo.getStock('MP1')).thenAnswer((_) async => 10);

      final stock = await saleService.getCurrentStock('MP1');
      expect(stock, 10);
    });
  });

  group('SaleService - validateSale', () {
    test('returns error if productId is null', () async {
      final error = await saleService.validateSale(
        productId: null,
        quantity: 1,
        totalPrice: 100,
        amountPaid: 100,
      );
      expect(error, 'Veuillez sélectionner un produit');
    });

    test('requires customer details for credit sales', () async {
      final error = await saleService.validateSale(
        productId: 'PF1',
        quantity: 1,
        totalPrice: 1000,
        amountPaid: 500,
        customerName: '',
        customerPhone: '',
      );
      expect(error, contains('obligatoires pour une vente à crédit'));
    });

    test('validates sufficient stock', () async {
      when(mockPackAdapter.getPackStock(productId: packProductId))
          .thenAnswer((_) async => 5);

      final error = await saleService.validateSale(
        productId: packProductId,
        quantity: 10,
        totalPrice: 1000,
        amountPaid: 1000,
      );
      expect(error, contains('Stock insuffisant'));
    });

    test('returns null if validation passes', () async {
      when(mockPackAdapter.getPackStock(productId: packProductId))
          .thenAnswer((_) async => 50);

      final error = await saleService.validateSale(
        productId: packProductId,
        quantity: 10,
        totalPrice: 5000,
        amountPaid: 5000,
      );
      expect(error, isNull);
    });
  });
}
