import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/drift_service.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../domain/entities/collection.dart';
import '../../domain/entities/transport_expense.dart';
import '../../domain/entities/tour.dart';
import '../../domain/repositories/tour_repository.dart';

/// Offline-first repository for Tour entities (gaz module).
class TourOfflineRepository extends OfflineRepository<Tour>
    implements TourRepository {
  TourOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
  });

  final String enterpriseId;

  @override
  String get collectionName => 'tours';

  @override
  Tour fromMap(Map<String, dynamic> map) {
    return Tour(
      id: map['id'] as String? ?? map['localId'] as String,
      enterpriseId: map['enterpriseId'] as String? ?? enterpriseId,
      tourDate: DateTime.parse(map['tourDate'] as String),
      status: _parseStatus(map['status'] as String? ?? 'collection'),
      collections: (map['collections'] as List<dynamic>?)
              ?.map((c) => _collectionFromMap(c as Map<String, dynamic>))
              .toList() ??
          [],
      loadingFeePerBottle: (map['loadingFeePerBottle'] as num?)?.toDouble() ?? 0.0,
      unloadingFeePerBottle: (map['unloadingFeePerBottle'] as num?)?.toDouble() ?? 0.0,
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

  @override
  Map<String, dynamic> toMap(Tour entity) {
    return {
      'id': entity.id,
      'enterpriseId': entity.enterpriseId,
      'tourDate': entity.tourDate.toIso8601String(),
      'status': entity.status.name,
      'collections': entity.collections.map((c) => _collectionToMap(c)).toList(),
      'loadingFeePerBottle': entity.loadingFeePerBottle,
      'unloadingFeePerBottle': entity.unloadingFeePerBottle,
      'transportExpenses':
          entity.transportExpenses.map((e) => _transportExpenseToMap(e)).toList(),
      'collectionCompletedDate': entity.collectionCompletedDate?.toIso8601String(),
      'transportCompletedDate': entity.transportCompletedDate?.toIso8601String(),
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
      'clientAddress': collection.clientAddress,
      'emptyBottles': collection.emptyBottles,
      'leaks': collection.leaks,
      'unitPrice': collection.unitPrice,
      'unitPricesByWeight': collection.unitPricesByWeight,
      'amountPaid': collection.amountPaid,
      'paymentDate': collection.paymentDate?.toIso8601String(),
    };
  }

  Collection _collectionFromMap(Map<String, dynamic> map) {
    return Collection(
      id: map['id'] as String,
      type: _parseCollectionType(map['type'] as String? ?? 'wholesaler'),
      clientId: map['clientId'] as String,
      clientName: map['clientName'] as String,
      clientPhone: map['clientPhone'] as String,
      clientAddress: map['clientAddress'] as String?,
      emptyBottles: (map['emptyBottles'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(int.parse(key), value as int)) ??
          {},
      leaks: (map['leaks'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(int.parse(key), value as int)) ??
          {},
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      unitPricesByWeight: (map['unitPricesByWeight'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(int.parse(key), value as double)),
      amountPaid: (map['amountPaid'] as num?)?.toDouble() ?? 0.0,
      paymentDate: map['paymentDate'] != null
          ? DateTime.parse(map['paymentDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> _transportExpenseToMap(TransportExpense expense) {
    return {
      'id': expense.id,
      'description': expense.description,
      'amount': expense.amount,
      'expenseDate': expense.expenseDate.toIso8601String(),
    };
  }

  TransportExpense _transportExpenseFromMap(Map<String, dynamic> map) {
    return TransportExpense(
      id: map['id'] as String,
      description: map['description'] as String,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      expenseDate: DateTime.parse(map['expenseDate'] as String),
    );
  }

  @override
  String getLocalId(Tour entity) {
    if (entity.id.startsWith('local_')) {
      return entity.id;
    }
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(Tour entity) {
    if (!entity.id.startsWith('local_')) {
      return entity.id;
    }
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
      moduleType: 'gaz',
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
        moduleType: 'gaz',
      );
      return;
    }
    final localId = getLocalId(entity);
    await driftService.records.deleteByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'gaz',
    );
  }

  @override
  Future<Tour?> getByLocalId(String localId) async {
    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'gaz',
    );
    if (byRemote != null) {
      final map = jsonDecode(byRemote.dataJson) as Map<String, dynamic>;
      return fromMap(map);
    }

    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'gaz',
    );
    if (byLocal == null) return null;

    final map = jsonDecode(byLocal.dataJson) as Map<String, dynamic>;
    return fromMap(map);
  }

  @override
  Future<List<Tour>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: 'gaz',
    );
    return rows
        .map((row) {
          try {
            final map = jsonDecode(row.dataJson) as Map<String, dynamic>;
            return fromMap(map);
          } catch (e) {
            developer.log(
              'Error parsing tour: $e',
              name: 'TourOfflineRepository',
            );
            return null;
          }
        })
        .whereType<Tour>()
        .toList();
  }

  // Implémentation de TourRepository

  @override
  Future<List<Tour>> getTours(
    String enterpriseId, {
    TourStatus? status,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      var tours = await getAllForEnterprise(enterpriseId);

      if (status != null) {
        tours = tours.where((t) => t.status == status).toList();
      }

      if (from != null) {
        tours = tours
            .where((t) => t.tourDate.isAfter(from) || t.tourDate.isAtSameMomentAs(from))
            .toList();
      }

      if (to != null) {
        tours = tours
            .where((t) => t.tourDate.isBefore(to) || t.tourDate.isAtSameMomentAs(to))
            .toList();
      }

      tours.sort((a, b) => b.tourDate.compareTo(a.tourDate));
      return tours;
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching tours',
        name: 'TourOfflineRepository',
        error: appException,
      );
      return [];
    }
  }

  @override
  Future<Tour?> getTourById(String id) async {
    try {
      return await getByLocalId(id);
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting tour',
        name: 'TourOfflineRepository',
        error: appException,
      );
      return null;
    }
  }

  @override
  Future<String> createTour(Tour tour) async {
    try {
      final tourWithId = tour.id.isEmpty
          ? tour.copyWith(id: LocalIdGenerator.generate())
          : tour;
      await save(tourWithId);
      return tourWithId.id;
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error creating tour',
        name: 'TourOfflineRepository',
        error: appException,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateTour(Tour tour) async {
    try {
      await save(tour);
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error updating tour',
        name: 'TourOfflineRepository',
        error: appException,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateStatus(String id, TourStatus status) async {
    try {
      final tour = await getTourById(id);
      if (tour != null) {
        final updated = tour.copyWith(status: status);
        await save(updated);
      }
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error updating tour status',
        name: 'TourOfflineRepository',
        error: appException,
      );
      rethrow;
    }
  }

  @override
  Future<void> cancelTour(String id) async {
    try {
      final tour = await getTourById(id);
      if (tour != null) {
        final updated = tour.copyWith(
          status: TourStatus.cancelled,
          cancelledDate: DateTime.now(),
        );
        await save(updated);
      }
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error cancelling tour',
        name: 'TourOfflineRepository',
        error: appException,
      );
      rethrow;
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
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error deleting tour',
        name: 'TourOfflineRepository',
        error: appException,
      );
      rethrow;
    }
  }

  TourStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'collection':
      case 'collecte':
        return TourStatus.collection;
      case 'transport':
        return TourStatus.transport;
      case 'return':
      case 'retour':
        return TourStatus.return_;
      case 'closure':
      case 'clôture':
        return TourStatus.closure;
      case 'cancelled':
      case 'annulé':
        return TourStatus.cancelled;
      default:
        return TourStatus.collection;
    }
  }

  CollectionType _parseCollectionType(String type) {
    switch (type.toLowerCase()) {
      case 'wholesaler':
      case 'grossiste':
        return CollectionType.wholesaler;
      case 'pointofsale':
      case 'point_of_sale':
      case 'point de vente':
        return CollectionType.pointOfSale;
      default:
        return CollectionType.wholesaler;
    }
  }
}

