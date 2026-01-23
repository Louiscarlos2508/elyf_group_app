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
    // Utiliser localId en priorité car c'est l'ID réellement utilisé dans la base de données
    // Si localId n'existe pas, utiliser id comme fallback
    final tourId = map['localId'] as String? ?? map['id'] as String? ?? '';
    return Tour(
      id: tourId,
      enterpriseId: map['enterpriseId'] as String,
      tourDate: DateTime.parse(map['tourDate'] as String),
      status: TourStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TourStatus.collection,
      ),
      collections:
          (map['collections'] as List<dynamic>?)
              ?.map((c) => _collectionFromMap(c as Map<String, dynamic>))
              .toList() ??
          [],
      loadingFeePerBottle: (map['loadingFeePerBottle'] as num).toDouble(),
      unloadingFeePerBottle: (map['unloadingFeePerBottle'] as num).toDouble(),
      transportExpenses:
          (map['transportExpenses'] as List<dynamic>?)
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
    final cylinderQuantities =
        (map['cylinderQuantities'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(int.parse(k), (v as num).toInt()),
        ) ??
        (map['emptyBottles'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(int.parse(k), (v as num).toInt()),
        ) ??
        {};

    // Récupérer unitPricesByWeight si disponible (pour prix en gros par poids)
    final unitPricesByWeightRaw =
        map['unitPricesByWeight'] as Map<String, dynamic>?;
    final unitPricesByWeight = unitPricesByWeightRaw?.map(
          (k, v) => MapEntry(int.parse(k), (v as num).toDouble()),
        );

    // Récupérer les fuites si disponibles
    final leaksRaw = map['leaks'] as Map<String, dynamic>?;
    final leaks = leaksRaw?.map(
          (k, v) => MapEntry(int.parse(k), (v as num).toInt()),
        ) ?? <int, int>{};

    return Collection(
      id: map['id'] as String? ?? map['pointOfSaleId'] as String? ?? '',
      type: CollectionType.values.firstWhere(
        (e) => e.name == (map['type'] as String?),
        orElse: () => CollectionType.pointOfSale,
      ),
      clientId:
          map['clientId'] as String? ?? map['pointOfSaleId'] as String? ?? '',
      clientName:
          map['clientName'] as String? ??
          map['pointOfSaleName'] as String? ??
          '',
      clientPhone: map['clientPhone'] as String? ?? '',
      emptyBottles: cylinderQuantities,
      unitPrice:
          (map['unitPrice'] as num?)?.toDouble() ??
          (map['amountDue'] as num?)?.toDouble() ??
          0.0,
      unitPricesByWeight: unitPricesByWeight,
      leaks: leaks,
      amountPaid: (map['amountPaid'] as num?)?.toDouble() ?? 0.0,
      paymentDate: map['paymentDate'] != null
          ? DateTime.parse(map['paymentDate'] as String)
          : null,
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
      'transportExpenses': entity.transportExpenses
          .map(_transportExpenseToMap)
          .toList(),
      'collectionCompletedDate': entity.collectionCompletedDate
          ?.toIso8601String(),
      'transportCompletedDate': entity.transportCompletedDate
          ?.toIso8601String(),
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
      'emptyBottles': collection.emptyBottles.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'unitPrice': collection.unitPrice,
      'unitPricesByWeight': collection.unitPricesByWeight?.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
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
    // Utiliser la méthode utilitaire pour trouver le localId existant
    final existingLocalId = await findExistingLocalId(entity, moduleType: moduleType);
    final localId = existingLocalId ?? getLocalId(entity);
    final remoteId = getRemoteId(entity);
    
    // S'assurer que le JSON contient le localId comme ID principal
    final map = toMap(entity)..['id'] = localId..['localId'] = localId;
    await driftService.records.upsert(
      collectionName: collectionName,
      localId: localId,
      remoteId: remoteId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
      dataJson: jsonEncode(map),
      localUpdatedAt: DateTime.now(),
    );
    
    developer.log(
      'Tour sauvegardé - localId: $localId, remoteId: $remoteId, entity.id: ${entity.id}, existing: ${existingLocalId != null}',
      name: 'TourOfflineRepository.saveToLocal',
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
  Future<Tour?> getByLocalId(String id) async {
    developer.log(
      'getByLocalId appelé avec ID: $id',
      name: 'TourOfflineRepository.getByLocalId',
    );
    
    // Si l'ID commence par 'local_', c'est un localId, chercher directement par localId
    if (id.startsWith('local_')) {
      developer.log(
        'Recherche par localId: $id',
        name: 'TourOfflineRepository.getByLocalId',
      );
      final byLocal = await driftService.records.findByLocalId(
        collectionName: collectionName,
        localId: id,
        enterpriseId: enterpriseId,
        moduleType: moduleType,
      );
      if (byLocal != null) {
        developer.log(
          'Tour trouvé par localId',
          name: 'TourOfflineRepository.getByLocalId',
        );
        final map = jsonDecode(byLocal.dataJson) as Map<String, dynamic>;
        map['id'] = byLocal.localId;
        map['localId'] = byLocal.localId;
        return fromMap(map);
      }
      developer.log(
        'Tour non trouvé par localId',
        name: 'TourOfflineRepository.getByLocalId',
      );
      return null;
    }
    
    // Sinon, c'est peut-être un remoteId, chercher d'abord par remoteId
    developer.log(
      'Recherche par remoteId: $id',
      name: 'TourOfflineRepository.getByLocalId',
    );
    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: id,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byRemote != null) {
      developer.log(
        'Tour trouvé par remoteId, localId: ${byRemote.localId}',
        name: 'TourOfflineRepository.getByLocalId',
      );
      final map = jsonDecode(byRemote.dataJson) as Map<String, dynamic>;
      map['id'] = byRemote.localId;
      map['localId'] = byRemote.localId;
      return fromMap(map);
    }
    
    // Si pas trouvé par remoteId, essayer par localId au cas où
    developer.log(
      'Tour non trouvé par remoteId, essai par localId: $id',
      name: 'TourOfflineRepository.getByLocalId',
    );
    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: id,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byLocal != null) {
      developer.log(
        'Tour trouvé par localId (fallback)',
        name: 'TourOfflineRepository.getByLocalId',
      );
      final map = jsonDecode(byLocal.dataJson) as Map<String, dynamic>;
      map['id'] = byLocal.localId;
      map['localId'] = byLocal.localId;
      return fromMap(map);
    }
    
    developer.log(
      'Tour non trouvé avec ID: $id',
      name: 'TourOfflineRepository.getByLocalId',
    );
    return null;
  }

  @override
  Future<List<Tour>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    final tours = rows.map((r) {
      final map = jsonDecode(r.dataJson) as Map<String, dynamic>;
      // Utiliser le localId de la base de données comme ID principal
      // C'est l'ID réellement utilisé pour stocker et rechercher le tour
      map['id'] = r.localId;
      map['localId'] = r.localId;
      final tour = fromMap(map);
      return tour;
    }).toList();
    
    // Dédupliquer par remoteId pour éviter les doublons
    final deduplicated = deduplicateByRemoteId(tours);
    
    // Dédupliquer également par localId pour éviter les doublons locaux
    final Map<String, Tour> toursByLocalId = {};
    for (final tour in deduplicated) {
      // Si le tour a un localId (commence par 'local_'), dédupliquer par localId
      if (tour.id.startsWith('local_')) {
        if (!toursByLocalId.containsKey(tour.id)) {
          toursByLocalId[tour.id] = tour;
        }
      } else {
        // Tour avec remoteId, déjà dédupliqué par deduplicateByRemoteId
        toursByLocalId[tour.id] = tour;
      }
    }
    
    developer.log(
      'Tours récupérés: ${rows.length}, après déduplication: ${toursByLocalId.length}',
      name: 'TourOfflineRepository.getAllForEnterprise',
    );
    
    return toursByLocalId.values.toList();
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
      developer.log(
        'Recherche du tour avec ID: $id',
        name: 'TourOfflineRepository.getTourById',
      );
      
      // Essayer d'abord avec getByLocalId
      var tour = await getByLocalId(id);
      
      // Si pas trouvé, essayer de chercher dans tous les tours de l'entreprise
      // au cas où l'ID dans le JSON ne correspond pas au localId
      if (tour == null) {
        developer.log(
          'Tour non trouvé avec getByLocalId, recherche dans tous les tours',
          name: 'TourOfflineRepository.getTourById',
        );
        final allTours = await getAllForEnterprise(enterpriseId);
        try {
          tour = allTours.firstWhere((t) => t.id == id);
          developer.log(
            'Tour trouvé dans la liste avec ID: ${tour.id}',
            name: 'TourOfflineRepository.getTourById',
          );
        } catch (e) {
          developer.log(
            'Tour non trouvé dans la liste avec ID exact: $id',
            name: 'TourOfflineRepository.getTourById',
          );
          return null;
        }
      } else {
        developer.log(
          'Tour trouvé avec getByLocalId, ID: ${tour.id}',
          name: 'TourOfflineRepository.getTourById',
        );
      }
      
      return tour;
    } catch (error, stackTrace) {
      developer.log(
        'Erreur lors de la recherche du tour: $id',
        name: 'TourOfflineRepository.getTourById',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
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
      developer.log(
        'Mise à jour du statut du tour: $id vers $status',
        name: 'TourOfflineRepository.updateStatus',
      );
      
      final tour = await getTourById(id);
      if (tour == null) {
        throw Exception('Tour introuvable avec ID: $id');
      }
      
      // Logger les données existantes pour vérifier qu'elles sont préservées
      developer.log(
        'Tour récupéré - Collections: ${tour.collections.length}, TransportExpenses: ${tour.transportExpenses.length}',
        name: 'TourOfflineRepository.updateStatus',
      );
      
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
      
      // Vérifier que les données sont préservées
      developer.log(
        'Tour mis à jour - Collections: ${updated.collections.length}, TransportExpenses: ${updated.transportExpenses.length}, Status: ${updated.status}',
        name: 'TourOfflineRepository.updateStatus',
      );
      
      await save(updated);
      
      developer.log(
        'Tour sauvegardé avec succès',
        name: 'TourOfflineRepository.updateStatus',
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Erreur lors de la mise à jour du statut du tour: $id',
        name: 'TourOfflineRepository.updateStatus',
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
