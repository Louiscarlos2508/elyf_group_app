import 'dart:developer' as developer;

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/isar_service.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../../../core/offline/collections/sale_collection.dart';
import '../../domain/entities/sale.dart';
import '../../domain/repositories/sale_repository.dart';

/// Offline-first repository for Sale entities.
class SaleOfflineRepository extends OfflineRepository<Sale>
    implements SaleRepository {
  SaleOfflineRepository({
    required super.isarService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
    required this.moduleType,
  });

  final String enterpriseId;
  final String moduleType;

  @override
  String get collectionName => 'sales';

  @override
  Sale fromMap(Map<String, dynamic> map) {
    final items = (map['items'] as List<dynamic>?)
            ?.map((item) => SaleItem(
                  productId: item['productId'] as String,
                  productName: item['productName'] as String,
                  quantity: (item['quantity'] as num).toInt(),
                  unitPrice: (item['unitPrice'] as num).toInt(),
                  totalPrice: (item['totalPrice'] as num).toInt(),
                ))
            .toList() ??
        [];

    return Sale(
      id: map['id'] as String? ?? map['localId'] as String,
      date: DateTime.parse(map['date'] as String? ?? map['saleDate'] as String),
      items: items,
      totalAmount: (map['totalAmount'] as num).toInt(),
      amountPaid: (map['amountPaid'] as num?)?.toInt() ?? 0,
      customerName: map['customerName'] as String?,
      paymentMethod: map['paymentMethod'] != null
          ? (map['paymentMethod'] == 'cash'
              ? PaymentMethod.cash
              : PaymentMethod.mobileMoney)
          : null,
      notes: map['notes'] as String?,
    );
  }

  @override
  Map<String, dynamic> toMap(Sale entity) {
    return {
      'id': entity.id,
      'date': entity.date.toIso8601String(),
      'saleDate': entity.date.toIso8601String(),
      'items': entity.items.map((item) => {
            'productId': item.productId,
            'productName': item.productName,
            'quantity': item.quantity,
            'unitPrice': item.unitPrice,
            'totalPrice': item.totalPrice,
          }).toList(),
      'totalAmount': entity.totalAmount.toDouble(),
      'paidAmount': entity.amountPaid.toDouble(),
      'amountPaid': entity.amountPaid.toDouble(),
      'paymentMethod': entity.paymentMethod?.name ?? 'cash',
      'customerName': entity.customerName,
      'notes': entity.notes,
      'isComplete': entity.amountPaid >= entity.totalAmount,
    };
  }

  @override
  String getLocalId(Sale entity) {
    if (entity.id.startsWith('local_')) {
      return entity.id;
    }
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(Sale entity) {
    if (!entity.id.startsWith('local_')) {
      return entity.id;
    }
    return null;
  }

  @override
  String? getEnterpriseId(Sale entity) => enterpriseId;

  @override
  Future<void> saveToLocal(Sale entity) async {
    final collection = SaleCollection.fromMap(
      toMap(entity),
      enterpriseId: enterpriseId,
      moduleType: moduleType,
      localId: getLocalId(entity),
    );
    collection.remoteId = getRemoteId(entity);
    collection.localUpdatedAt = DateTime.now();

    await isarService.isar.writeTxn(() async {
      await isarService.isar.saleCollections.put(collection);

      // Save sale items
      for (var i = 0; i < entity.items.length; i++) {
        final item = entity.items[i];
        final itemCollection = SaleItemCollection.fromMap(
          {
            'productId': item.productId,
            'productName': item.productName,
            'quantity': item.quantity.toDouble(),
            'unitPrice': item.unitPrice.toDouble(),
            'totalPrice': item.totalPrice.toDouble(),
          },
          saleLocalId: collection.localId,
        );
        await isarService.isar.saleItemCollections.put(itemCollection);
      }
    });
  }

  @override
  Future<void> deleteFromLocal(Sale entity) async {
    final remoteId = getRemoteId(entity);
    final localId = getLocalId(entity);

    await isarService.isar.writeTxn(() async {
      // Delete sale items first
      await isarService.isar.saleItemCollections
          .filter()
          .saleLocalIdEqualTo(localId)
          .deleteAll();

      // Delete sale
      if (remoteId != null) {
        await isarService.isar.saleCollections
            .filter()
            .remoteIdEqualTo(remoteId)
            .and()
            .enterpriseIdEqualTo(enterpriseId)
            .deleteAll();
      } else {
        await isarService.isar.saleCollections
            .filter()
            .localIdEqualTo(localId)
            .and()
            .enterpriseIdEqualTo(enterpriseId)
            .deleteAll();
      }
    });
  }

  @override
  Future<Sale?> getByLocalId(String localId) async {
    var collection = await isarService.isar.saleCollections
        .filter()
        .localIdEqualTo(localId)
        .and()
        .enterpriseIdEqualTo(enterpriseId)
        .findFirst();

    if (collection == null) {
      collection = await isarService.isar.saleCollections
          .filter()
          .remoteIdEqualTo(localId)
          .and()
          .enterpriseIdEqualTo(enterpriseId)
          .findFirst();
    }

    if (collection == null) return null;

    // Load sale items
    final items = await isarService.isar.saleItemCollections
        .filter()
        .saleLocalIdEqualTo(collection.localId)
        .findAll();

    final saleMap = collection.toMap();
    saleMap['items'] = items.map((item) => item.toMap()).toList();
    return fromMap(saleMap);
  }

  @override
  Future<List<Sale>> getAllForEnterprise(String enterpriseId) async {
    final collections = await isarService.isar.saleCollections
        .filter()
        .enterpriseIdEqualTo(enterpriseId)
        .and()
        .moduleTypeEqualTo(moduleType)
        .sortBySaleDateDesc()
        .findAll();

    final sales = <Sale>[];
    for (final collection in collections) {
      final items = await isarService.isar.saleItemCollections
          .filter()
          .saleLocalIdEqualTo(collection.localId)
          .findAll();

      final saleMap = collection.toMap();
      saleMap['items'] = items.map((item) => item.toMap()).toList();
      sales.add(fromMap(saleMap));
    }

    return sales;
  }

  // SaleRepository interface implementation

  @override
  Future<List<Sale>> fetchRecentSales({int limit = 50}) async {
    try {
      developer.log(
        'Fetching recent sales for enterprise: $enterpriseId',
        name: 'SaleOfflineRepository',
      );
      final allSales = await getAllForEnterprise(enterpriseId);
      return allSales.take(limit).toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching recent sales',
        name: 'SaleOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<String> createSale(Sale sale) async {
    try {
      final localId = getLocalId(sale);
      final saleWithLocalId = Sale(
        id: localId,
        date: sale.date,
        items: sale.items,
        totalAmount: sale.totalAmount,
        amountPaid: sale.amountPaid,
        customerName: sale.customerName,
        paymentMethod: sale.paymentMethod,
        notes: sale.notes,
      );
      await save(saleWithLocalId);
      return localId;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error creating sale',
        name: 'SaleOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<Sale?> getSale(String id) async {
    try {
      return await getByLocalId(id);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting sale: $id',
        name: 'SaleOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }
}

