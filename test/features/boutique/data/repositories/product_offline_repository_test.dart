import 'package:flutter_test/flutter_test.dart';

import 'package:elyf_groupe_app/core/offline/connectivity_service.dart';
import 'package:elyf_groupe_app/core/offline/drift_service.dart';
import 'package:elyf_groupe_app/core/offline/sync_manager.dart';
import 'package:elyf_groupe_app/features/boutique/data/repositories/product_offline_repository.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/product.dart';

void main() {
  group('ProductOfflineRepository', () {
    late DriftService driftService;
    late ConnectivityService connectivityService;
    late SyncManager syncManager;
    late ProductOfflineRepository repository;

    setUpAll(() async {
      // TODO: enable these tests by using an in-memory Drift database.
      await DriftService.instance.initialize();
    });

    setUp(() {
      driftService = DriftService.instance;
      connectivityService = ConnectivityService();
      syncManager = SyncManager(
        driftService: driftService,
        connectivityService: connectivityService,
      );
      repository = ProductOfflineRepository(
        driftService: driftService,
        syncManager: syncManager,
        connectivityService: connectivityService,
        enterpriseId: 'test_enterprise',
        moduleType: 'boutique',
      );
    });

    tearDown(() async {
      await driftService.clearAll();
    });

    test(
      'createProduct should save product locally and return localId',
      () async {
      final product = Product(
        id: 'test-product-1',
        name: 'Test Product',
        price: 1000,
        stock: 10,
      );

      final localId = await repository.createProduct(product);

      expect(localId, isNotEmpty);
      expect(localId, startsWith('local_'));

      final saved = await repository.getProduct(localId);
      expect(saved, isNotNull);
      expect(saved!.name, 'Test Product');
      expect(saved.price, 1000);
      expect(saved.stock, 10);
      },
      skip: true,
    );

    test(
      'getProduct should return product by localId',
      () async {
      final product = Product(
        id: 'test-product-1',
        name: 'Test Product',
        price: 1000,
        stock: 10,
      );

      final localId = await repository.createProduct(product);
      final retrieved = await repository.getProduct(localId);

      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Test Product');
      },
      skip: true,
    );

    test(
      'updateProduct should update existing product',
      () async {
      final product = Product(
        id: 'test-product-1',
        name: 'Test Product',
        price: 1000,
        stock: 10,
      );

      final localId = await repository.createProduct(product);
      final updated = Product(
        id: localId,
        name: 'Updated Product',
        price: 2000,
        stock: 20,
      );

      await repository.updateProduct(updated);
      final retrieved = await repository.getProduct(localId);

      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Updated Product');
      expect(retrieved.price, 2000);
      expect(retrieved.stock, 20);
      },
      skip: true,
    );

    test(
      'deleteProduct should remove product from local storage',
      () async {
      final product = Product(
        id: 'test-product-1',
        name: 'Test Product',
        price: 1000,
        stock: 10,
      );

      final localId = await repository.createProduct(product);
      await repository.deleteProduct(localId);
      final retrieved = await repository.getProduct(localId);

      expect(retrieved, isNull);
      },
      skip: true,
    );

    test(
      'fetchProducts should return products for enterprise',
      () async {
      final product1 = Product(
        id: 'test-product-1',
        name: 'Product 1',
        price: 1000,
        stock: 10,
      );
      final product2 = Product(
        id: 'test-product-2',
        name: 'Product 2',
        price: 2000,
        stock: 20,
      );

      await repository.createProduct(product1);
      await repository.createProduct(product2);

      final products = await repository.fetchProducts();

      expect(products.length, greaterThanOrEqualTo(2));
      expect(products.any((p) => p.name == 'Product 1'), isTrue);
      expect(products.any((p) => p.name == 'Product 2'), isTrue);
      },
      skip: true,
    );

    test(
      'getProductByBarcode should return product with matching barcode',
      () async {
      final product = Product(
        id: 'test-product-1',
        name: 'Test Product',
        price: 1000,
        stock: 10,
        barcode: '123456789',
      );

      await repository.createProduct(product);
      final retrieved = await repository.getProductByBarcode('123456789');

      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Test Product');
      expect(retrieved.barcode, '123456789');
      },
      skip: true,
    );
  });
}

