import 'dart:convert';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../domain/entities/sale.dart';
import '../../domain/repositories/sale_repository.dart';

/// Offline-first repository for Sale entities.
class SaleOfflineRepository extends OfflineRepository<Sale>
    implements SaleRepository {
  SaleOfflineRepository({
    required super.driftService,
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
    final items =
        (map['items'] as List<dynamic>?)
            ?.map(
              (item) => SaleItem(
                productId: item['productId'] as String,
                productName: item['productName'] as String,
                quantity: (item['quantity'] as num).toInt(),
                unitPrice: (item['unitPrice'] as num).toInt(),
                totalPrice: (item['totalPrice'] as num).toInt(),
              ),
            )
            .toList() ??
        [];

    // Gérer l'enum PaymentMethod avec support pour "both"
    PaymentMethod? paymentMethod;
    if (map['paymentMethod'] != null) {
      final methodStr = map['paymentMethod'] as String;
      switch (methodStr) {
        case 'cash':
          paymentMethod = PaymentMethod.cash;
          break;
        case 'mobileMoney':
          paymentMethod = PaymentMethod.mobileMoney;
          break;
        case 'both':
          paymentMethod = PaymentMethod.both;
          break;
        default:
          paymentMethod = PaymentMethod.cash;
      }
    }

    return Sale(
      id: map['id'] as String? ?? map['localId'] as String,
      date: DateTime.parse(map['date'] as String? ?? map['saleDate'] as String),
      items: items,
      totalAmount: (map['totalAmount'] as num).toInt(),
      amountPaid: (map['amountPaid'] as num?)?.toInt() ?? 0,
      customerName: map['customerName'] as String?,
      paymentMethod: paymentMethod,
      notes: map['notes'] as String?,
      cashAmount: (map['cashAmount'] as num?)?.toInt() ?? 0,
      mobileMoneyAmount: (map['mobileMoneyAmount'] as num?)?.toInt() ?? 0,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  @override
  Map<String, dynamic> toMap(Sale entity) {
    return {
      'id': entity.id,
      'date': entity.date.toIso8601String(),
      'saleDate': entity.date.toIso8601String(),
      'items': entity.items
          .map(
            (item) => {
              'productId': item.productId,
              'productName': item.productName,
              'quantity': item.quantity,
              'unitPrice': item.unitPrice,
              'totalPrice': item.totalPrice,
            },
          )
          .toList(),
      'totalAmount': entity.totalAmount.toDouble(),
      'paidAmount': entity.amountPaid.toDouble(),
      'amountPaid': entity.amountPaid.toDouble(),
      'paymentMethod': entity.paymentMethod?.name ?? 'cash',
      'customerName': entity.customerName,
      'notes': entity.notes,
      'cashAmount': entity.cashAmount.toDouble(),
      'mobileMoneyAmount': entity.mobileMoneyAmount.toDouble(),
      'isComplete': entity.amountPaid >= entity.totalAmount,
      'updatedAt': entity.updatedAt?.toIso8601String(),
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
    final localId = getLocalId(entity);
    final map = toMap(entity)..['localId'] = localId;
    await driftService.records.upsert(
      collectionName: collectionName,
      localId: localId,
      remoteId: getRemoteId(entity),
      enterpriseId: enterpriseId,
      moduleType: moduleType,
      dataJson: jsonEncode(map),
      localUpdatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteFromLocal(Sale entity) async {
    final remoteId = getRemoteId(entity);
    final localId = getLocalId(entity);

    if (remoteId != null) {
      await driftService.records.deleteByRemoteId(
        collectionName: collectionName,
        remoteId: remoteId,
        enterpriseId: enterpriseId,
        moduleType: moduleType,
      );
      return;
    }
    await driftService.records.deleteByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
  }

  @override
  Future<Sale?> getByLocalId(String localId) async {
    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byLocal != null) {
      return fromMap(jsonDecode(byLocal.dataJson) as Map<String, dynamic>);
    }

    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byRemote == null) return null;
    return fromMap(jsonDecode(byRemote.dataJson) as Map<String, dynamic>);
  }

  @override
  Future<List<Sale>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    final sales = rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .toList();
    
    // Dédupliquer par remoteId pour éviter les doublons
    final deduplicatedSales = deduplicateByRemoteId(sales);
    
    // Trier par date décroissante
    deduplicatedSales.sort((a, b) => b.date.compareTo(a.date));
    return deduplicatedSales;
    return sales;
  }

  // SaleRepository interface implementation

  @override
  Future<List<Sale>> fetchRecentSales({int limit = 50}) async {
    try {
      AppLogger.debug(
        'Fetching recent sales for enterprise: $enterpriseId',
        name: 'SaleOfflineRepository',
      );
      final allSales = await getAllForEnterprise(enterpriseId);
      return allSales.take(limit).toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error fetching recent sales: ${appException.message}',
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
        cashAmount: sale.cashAmount,
        mobileMoneyAmount: sale.mobileMoneyAmount,
        updatedAt: DateTime.now(),
      );
      await save(saleWithLocalId);
      return localId;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error creating sale: ${appException.message}',
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
      AppLogger.error(
        'Error getting sale: $id - ${appException.message}',
        name: 'SaleOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Stream<List<Sale>> watchRecentSales({int limit = 50}) {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((rows) {
      final sales = rows
          .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
          .toList();
      final deduplicatedSales = deduplicateByRemoteId(sales);
      deduplicatedSales.sort((a, b) => b.date.compareTo(a.date));
      return deduplicatedSales.take(limit).toList();
    });
  }
}
