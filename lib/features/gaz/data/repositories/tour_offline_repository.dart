import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../domain/entities/collection.dart';
import '../../domain/entities/tour.dart';
import '../../domain/entities/transport_expense.dart';
import '../../domain/repositories/tour_repository.dart';

/// Offline-first repository for Tour entities.
class TourOfflineRepository extends OfflineRepository<Tour>
    implements TourRepository {
  TourOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
    required this.moduleType,
  });

  final String enterpriseId;
  final String moduleType;

  @override
  String get collectionName => 'tours';

  @override
  Tour fromMap(Map<String, dynamic> map) {
    return Tour(
      id: map['id'] as String? ?? map['localId'] as String,
      enterpriseId: map['enterpriseId'] as String,
      tourDate: DateTime.parse(map['tourDate'] as String),
      status: TourStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TourStatus.collection,
      ),
      collections: (map['collections'] as List<dynamic>?)
              ?.map((c) => _collectionFromMap(c as Map<String, dynamic>))
              .toList() ??
          [],
      loadingFeePerBottle: (map['loadingFeePerBottle'] as num).toDouble(),
      unloadingFeePerBottle: (map['unloadingFeePerBottle'] as num).toDouble(),
      transportExpenses: (map['transportExpenses'] as List<dynamic>?)
              ?.map((e) => _transportExpenseFromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      collectionCompletedDate: map['collectionCompletedDate'] != null
          ? DateTime.parse(map['collectionCompletedDate'] as String)
          : null,
      transportCompletedDate: map['transportCompletedDate'] != null
          ? DateTime.parse(map['transportCompletedDate'] as String)
          : null,
      returnCompletedDate: map['returnCompletedDate'] != null
          ? DateTime.parse(map['returnCompletedDate'] as String)
          : null,
      closureDate: map['closureDate'] != null
          ? DateTime.parse(map['closureDate'] as String)
          : null,
      cancelledDate: map['cancelledDate'] != null
          ? DateTime.parse(map['cancelledDate'] as String)
          : null,
      notes: map['notes'] as String?,
    );
  }

  Collection _collectionFromMap(Map<String, dynamic> map) {
    // Convert cylinderQuantities/pointOfSaleId to new structure
    final cylinderQuantities = (map['cylinderQuantities'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(int.parse(k), (v as num).toInt())) ??
        (map['emptyBottles'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(int.parse(k), (v as num).toInt())) ??
        {};
    
    return Collection(
      id: map['id'] as String? ?? map['pointOfSaleId'] as String? ?? '',
      type: CollectionType.values.firstWhere(
        (e) => e.name == (map['type'] as String?),
        orElse: () => CollectionType.pointOfSale,
      ),
      clientId: map['clientId'] as String? ?? map['pointOfSaleId'] as String? ?? '',
      clientName: map['clientName'] as String? ?? map['pointOfSaleName'] as String? ?? '',
      clientPhone: map['clientPhone'] as String? ?? '',
      emptyBottles: cylinderQuantities,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? (map['amountDue'] as num?)?.toDouble() ?? 0.0,
      amountPaid: (map['amountPaid'] as num?)?.toDouble() ?? 0.0,
      paymentDate: map['paymentDate'] != null ? DateTime.parse(map['paymentDate'] as String) : null,
    );
  }

  TransportExpense _transportExpenseFromMap(Map<String, dynamic> map) {
    return TransportExpense(
      id: map['id'] as String,
      description: map['description'] as String,
      amount: (map['amount'] as num).toDouble(),
      expenseDate: map['expenseDate'] != null 
          ? DateTime.parse(map['expenseDate'] as String)
          : DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toMap(Tour entity) {
    return {
      'id': entity.id,
      'enterpriseId': entity.enterpriseId,
      'tourDate': entity.tourDate.toIso8601String(),
      'status': entity.status.name,
      'collections': entity.collections.map(_collectionToMap).toList(),
      'loadingFeePerBottle': entity.loadingFeePerBottle,
      'unloadingFeePerBottle': entity.unloadingFeePerBottle,
      'transportExpenses':
          entity.transportExpenses.map(_transportExpenseToMap).toList(),
      'collectionCompletedDate':
          entity.collectionCompletedDate?.toIso8601String(),
      'transportCompletedDate':
          entity.transportCompletedDate?.toIso8601String(),
      'returnCompletedDate': entity.returnCompletedDate?.toIso8601String(),
      'closureDate': entity.closureDate?.toIso8601String(),
      'cancelledDate': entity.cancelledDate?.toIso8601String(),
      'notes': entity.notes,
    };
  }

  Map<String, dynamic> _collectionToMap(Collection collection) {
    return {
      'id': collection.id,
      'type': collection.type.name,
      'clientId': collection.clientId,
      'clientName': collection.clientName,
      'clientPhone': collection.clientPhone,
      'emptyBottles': collection.emptyBottles.map((k, v) => MapEntry(k.toString(), v)),
      'unitPrice': collection.unitPrice,
      'unitPricesByWeight': collection.unitPricesByWeight?.map((k, v) => MapEntry(k.toString(), v)),
      'leaks': collection.leaks.map((k, v) => MapEntry(k.toString(), v)),
      'amountPaid': collection.amountPaid,
      'paymentDate': collection.paymentDate?.toIso8601String(),
    };
  }

  Map<String, dynamic> _transportExpenseToMap(TransportExpense expense) {
    return {
      'id': expense.id,
      'description': expense.description,
      'amount': expense.amount,
      'expenseDate': expense.expenseDate.toIso8601String(),
    };
  }

  @override
  String getLocalId(Tour entity) {
    if (entity.id.startsWith('local_')) return entity.id;
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(Tour entity) {
    if (!entity.id.startsWith('local_')) return entity.id;
    return null;
  }

  @override
  String? getEnterpriseId(Tour entity) => entity.enterpriseId;

  @override
  Future<void> saveToLocal(Tour entity) async {
    final localId = getLocalId(entity);
    final remoteId = getRemoteId(entity);
    final map = toMap(entity)..['localId'] = localId;
    await driftService.records.upsert(
      collectionName: collectionName,
      localId: localId,
      remoteId: remoteId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
      dataJson: jsonEncode(map),
      localUpdatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteFromLocal(Tour entity) async {
    final remoteId = getRemoteId(entity);
    if (remoteId != null) {
      await driftService.records.deleteByRemoteId(
        collectionName: collectionName,
        remoteId: remoteId,
        enterpriseId: enterpriseId,
        moduleType: moduleType,
      );
      return;
    }
    final localId = getLocalId(entity);
    await driftService.records.deleteByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
  }

  @override
  Future<Tour?> getByLocalId(String localId) async {
    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byRemote != null) {
      return fromMap(jsonDecode(byRemote.dataJson) as Map<String, dynamic>);
    }
    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byLocal == null) return null;
    return fromMap(jsonDecode(byLocal.dataJson) as Map<String, dynamic>);
  }

  @override
  Future<List<Tour>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    return rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .toList();
  }

  // TourRepository implementation

  @override
  Future<List<Tour>> getTours(
    String enterpriseId, {
    TourStatus? status,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final tours = await getAllForEnterprise(enterpriseId);
      return tours.where((tour) {
        if (status != null && tour.status != status) return false;
        if (from != null && tour.tourDate.isBefore(from)) return false;
        if (to != null && tour.tourDate.isAfter(to)) return false;
        return true;
      }).toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting tours',
        name: 'TourOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<Tour?> getTourById(String id) async {
    try {
      return await getByLocalId(id);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting tour: $id',
        name: 'TourOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<String> createTour(Tour tour) async {
    try {
      final localId = getLocalId(tour);
      final tourWithLocalId = tour.copyWith(id: localId);
      await save(tourWithLocalId);
      return localId;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error creating tour',
        name: 'TourOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> updateTour(Tour tour) async {
    try {
      await save(tour);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error updating tour: ${tour.id}',
        name: 'TourOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> updateStatus(String id, TourStatus status) async {
    try {
      final tour = await getTourById(id);
      if (tour != null) {
        Tour updated;
        switch (status) {
          case TourStatus.collection:
            updated = tour.copyWith(status: status);
            break;
          case TourStatus.transport:
            updated = tour.copyWith(
              status: status,
              collectionCompletedDate: DateTime.now(),
            );
            break;
          case TourStatus.return_:
            updated = tour.copyWith(
              status: status,
              transportCompletedDate: DateTime.now(),
            );
            break;
          case TourStatus.closure:
            updated = tour.copyWith(
              status: status,
              returnCompletedDate: DateTime.now(),
              closureDate: DateTime.now(),
            );
            break;
          case TourStatus.cancelled:
            updated = tour.copyWith(
              status: status,
              cancelledDate: DateTime.now(),
            );
            break;
        }
        await save(updated);
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error updating tour status: $id',
        name: 'TourOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> cancelTour(String id) async {
    try {
      await updateStatus(id, TourStatus.cancelled);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error cancelling tour: $id',
        name: 'TourOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> deleteTour(String id) async {
    try {
      final tour = await getTourById(id);
      if (tour != null) {
        await delete(tour);
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error deleting tour: $id',
        name: 'TourOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }
}
