import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/drift_service.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../domain/entities/sale.dart';
import '../../domain/repositories/sale_repository.dart';

/// Offline-first repository for Sale entities (eau_minerale module).
class SaleOfflineRepository extends OfflineRepository<Sale>
    implements SaleRepository {
  SaleOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
  });

  final String enterpriseId;

  @override
  String get collectionName => 'sales';

  @override
  Sale fromMap(Map<String, dynamic> map) {
    // Extract metadata if stored in notes
    Map<String, dynamic>? metadata;
    if (map['notes'] != null && map['notes'].toString().startsWith('{')) {
      try {
        metadata = jsonDecode(map['notes'] as String) as Map<String, dynamic>;
      } catch (e) {
        // Not JSON, treat as regular notes
      }
    }

    return Sale(
      id: map['id'] as String? ?? map['localId'] as String,
      productId: map['productId'] as String? ?? 
                 (metadata?['productId'] as String?) ?? '',
      productName: map['productName'] as String? ?? 
                   (metadata?['productName'] as String?) ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 
                (metadata?['quantity'] as int?) ?? 0,
      unitPrice: (map['unitPrice'] as num?)?.toInt() ?? 
                 (metadata?['unitPrice'] as int?) ?? 0,
      totalPrice: (map['totalPrice'] as num?)?.toInt() ?? 
                  (map['totalAmount'] as num?)?.toInt() ?? 0,
      amountPaid: (map['amountPaid'] as num?)?.toInt() ?? 
                  (map['paidAmount'] as num?)?.toInt() ?? 0,
      customerName: map['customerName'] as String? ?? '',
      customerPhone: map['customerPhone'] as String? ?? 
                     (metadata?['customerPhone'] as String?) ?? '',
      customerId: map['customerId'] as String? ?? 
                  (metadata?['customerId'] as String?) ?? '',
      date: map['date'] != null
          ? DateTime.parse(map['date'] as String)
          : (map['saleDate'] != null
              ? DateTime.parse(map['saleDate'] as String)
              : DateTime.now()),
      status: _parseSaleStatus(map['status'] as String? ?? 
                                (map['isComplete'] == true ? 'validated' : 'validated')),
      createdBy: map['createdBy'] as String? ?? 
                 map['soldBy'] as String? ?? '',
      customerCnib: map['customerCnib'] as String? ?? 
                    (metadata?['customerCnib'] as String?),
      notes: metadata == null ? map['notes'] as String? : null,
      cashAmount: (metadata?['cashAmount'] as int?) ?? 0,
      orangeMoneyAmount: (metadata?['orangeMoneyAmount'] as int?) ?? 0,
      productionSessionId: metadata?['productionSessionId'] as String?,
    );
  }

  @override
  Map<String, dynamic> toMap(Sale entity) {
    // Store additional fields in metadata JSON within notes
    final metadata = <String, dynamic>{
      if (entity.cashAmount > 0) 'cashAmount': entity.cashAmount,
      if (entity.orangeMoneyAmount > 0) 'orangeMoneyAmount': entity.orangeMoneyAmount,
      if (entity.productionSessionId != null) 'productionSessionId': entity.productionSessionId,
      'productId': entity.productId,
      'productName': entity.productName,
      'quantity': entity.quantity,
      'unitPrice': entity.unitPrice,
      if (entity.customerPhone.isNotEmpty) 'customerPhone': entity.customerPhone,
      if (entity.customerCnib != null) 'customerCnib': entity.customerCnib,
    };

    return {
      'id': entity.id,
      'date': entity.date.toIso8601String(),
      'saleDate': entity.date.toIso8601String(),
      'totalAmount': entity.totalPrice.toDouble(),
      'paidAmount': entity.amountPaid.toDouble(),
      'amountPaid': entity.amountPaid.toDouble(),
      'customerName': entity.customerName,
      'customerId': entity.customerId,
      'paymentMethod': entity.isCredit ? 'credit' : 'cash',
      'notes': entity.notes ?? jsonEncode(metadata),
      'soldBy': entity.createdBy,
      'isComplete': entity.isFullyPaid,
      'status': entity.status.name,
      // Store product info for SaleItem creation
      'productId': entity.productId,
      'productName': entity.productName,
      'quantity': entity.quantity,
      'unitPrice': entity.unitPrice,
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
    final map = toMap(entity);
    final localId = getLocalId(entity);
    map['localId'] = localId;
    await driftService.records.upsert(
      collectionName: collectionName,
      localId: localId,
      remoteId: getRemoteId(entity),
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
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
        moduleType: 'eau_minerale',
      );
      return;
    }
    await driftService.records.deleteByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
    );
  }

  @override
  Future<Sale?> getByLocalId(String localId) async {
    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
    );
    if (byRemote != null) {
      return fromMap(jsonDecode(byRemote.dataJson) as Map<String, dynamic>);
    }

    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
    );
    if (byLocal == null) return null;
    return fromMap(jsonDecode(byLocal.dataJson) as Map<String, dynamic>);
  }

  @override
  Future<List<Sale>> fetchRecentSales({int limit = 50}) async {
    final all = await getAllForEnterprise(enterpriseId);
    all.sort((a, b) => b.date.compareTo(a.date));
    return all.take(limit).toList();
  }

  @override
  Future<List<Sale>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
    );
    return rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .toList();
  }

  // SaleRepository interface implementation

  @override
  Future<List<Sale>> fetchSales({
    DateTime? startDate,
    DateTime? endDate,
    SaleStatus? status,
    String? customerId,
  }) async {
    try {
      developer.log(
        'Fetching sales for enterprise: $enterpriseId',
        name: 'SaleOfflineRepository',
      );
      var allSales = await getAllForEnterprise(enterpriseId);

      if (startDate != null) {
        allSales = allSales
            .where((s) => s.date.isAfter(startDate) || s.date.isAtSameMomentAs(startDate))
            .toList();
      }

      if (endDate != null) {
        allSales = allSales
            .where((s) => s.date.isBefore(endDate) || s.date.isAtSameMomentAs(endDate))
            .toList();
      }

      if (status != null) {
        allSales = allSales.where((s) => s.status == status).toList();
      }

      if (customerId != null) {
        allSales = allSales.where((s) => s.customerId == customerId).toList();
      }

      // Sort by date descending
      allSales.sort((a, b) => b.date.compareTo(a.date));

      return allSales;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching sales',
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

  @override
  Future<String> createSale(Sale sale) async {
    try {
      final localId = getLocalId(sale);
      final saleWithLocalId = Sale(
        id: localId,
        productId: sale.productId,
        productName: sale.productName,
        quantity: sale.quantity,
        unitPrice: sale.unitPrice,
        totalPrice: sale.totalPrice,
        amountPaid: sale.amountPaid,
        customerName: sale.customerName,
        customerPhone: sale.customerPhone,
        customerId: sale.customerId,
        date: sale.date,
        status: sale.status,
        createdBy: sale.createdBy,
        customerCnib: sale.customerCnib,
        notes: sale.notes,
        cashAmount: sale.cashAmount,
        orangeMoneyAmount: sale.orangeMoneyAmount,
        productionSessionId: sale.productionSessionId,
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
  Future<void> deleteSale(String saleId) async {
    try {
      final sale = await getSale(saleId);
      if (sale != null) {
        await delete(sale);
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error deleting sale: $saleId',
        name: 'SaleOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> updateSaleAmountPaid(String saleId, int newAmountPaid) async {
    try {
      final sale = await getSale(saleId);
      if (sale != null) {
        final updatedSale = Sale(
          id: sale.id,
          productId: sale.productId,
          productName: sale.productName,
          quantity: sale.quantity,
          unitPrice: sale.unitPrice,
          totalPrice: sale.totalPrice,
          amountPaid: newAmountPaid,
          customerName: sale.customerName,
          customerPhone: sale.customerPhone,
          customerId: sale.customerId,
          date: sale.date,
          status: newAmountPaid >= sale.totalPrice 
              ? SaleStatus.fullyPaid 
              : SaleStatus.validated,
          createdBy: sale.createdBy,
          customerCnib: sale.customerCnib,
          notes: sale.notes,
          cashAmount: sale.cashAmount,
          orangeMoneyAmount: sale.orangeMoneyAmount,
          productionSessionId: sale.productionSessionId,
        );
        await save(updatedSale);
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error updating sale amount paid: $saleId',
        name: 'SaleOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  SaleStatus _parseSaleStatus(String status) {
    switch (status) {
      case 'validated':
        return SaleStatus.validated;
      case 'fullyPaid':
        return SaleStatus.fullyPaid;
      default:
        return SaleStatus.validated;
    }
  }
}

