import 'dart:convert';

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../domain/entities/tour.dart';
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
  Tour fromMap(Map<String, dynamic> map) =>
      Tour.fromMap(map, enterpriseId);

  @override
  Map<String, dynamic> toMap(Tour entity) => entity.toMap();

  @override
  String getLocalId(Tour entity) {
    if (entity.id.isNotEmpty) return entity.id;
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
    
    AppLogger.debug(
      'Tour sauvegardé - localId: $localId, remoteId: $remoteId, entity.id: ${entity.id}, existing: ${existingLocalId != null}',
      name: 'TourOfflineRepository.saveToLocal',
    );
  }

  @override
  Future<void> deleteFromLocal(Tour entity) async {
    // Soft-delete
    final deletedTour = entity.copyWith(
      deletedAt: DateTime.now(),
    );
    await saveToLocal(deletedTour);
    
    AppLogger.info(
      'Soft-deleted tour: ${entity.id}',
      name: 'TourOfflineRepository',
    );
  }

  @override
  Future<Tour?> getByLocalId(String id) async {
    AppLogger.debug(
      'getByLocalId appelé avec ID: $id',
      name: 'TourOfflineRepository.getByLocalId',
    );
    
    // Si l'ID commence par 'local_', c'est un localId, chercher directement par localId
    if (id.startsWith('local_')) {
      AppLogger.debug(
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
        AppLogger.debug(
          'Tour trouvé par localId',
          name: 'TourOfflineRepository.getByLocalId',
        );
        final map = jsonDecode(byLocal.dataJson) as Map<String, dynamic>;
        map['id'] = byLocal.localId;
        map['localId'] = byLocal.localId;
        return fromMap(map);
      }
      AppLogger.debug(
        'Tour non trouvé par localId',
        name: 'TourOfflineRepository.getByLocalId',
      );
      return null;
    }
    
    // Sinon, c'est peut-être un remoteId, chercher d'abord par remoteId
    AppLogger.debug(
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
      AppLogger.debug(
        'Tour trouvé par remoteId, localId: ${byRemote.localId}',
        name: 'TourOfflineRepository.getByLocalId',
      );
      final map = jsonDecode(byRemote.dataJson) as Map<String, dynamic>;
      map['id'] = byRemote.localId;
      map['localId'] = byRemote.localId;
      final tour = fromMap(map);
      return tour.isDeleted ? null : tour;
    }
    
    // Si pas trouvé par remoteId, essayer par localId au cas où
    AppLogger.debug(
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
      AppLogger.debug(
        'Tour trouvé par localId (fallback)',
        name: 'TourOfflineRepository.getByLocalId',
      );
      final map = jsonDecode(byLocal.dataJson) as Map<String, dynamic>;
      map['id'] = byLocal.localId;
      map['localId'] = byLocal.localId;
      final tour = fromMap(map);
      return tour.isDeleted ? null : tour;
    }
    
    AppLogger.debug(
      'Tour non trouvé avec ID: $id',
      name: 'TourOfflineRepository.getByLocalId',
    );
    return null;
  }

  @override
  Future<List<Tour>> getTours(
    String enterpriseId, {
    TourStatus? status,
    DateTime? from,
    DateTime? to,
  }) async {
    final allTours = await getAllForEnterprise(enterpriseId);
    return allTours.where((tour) {
      if (status != null && tour.status != status) return false;
      if (from != null && tour.tourDate.isBefore(from)) return false;
      if (to != null && tour.tourDate.isAfter(to)) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.tourDate.compareTo(a.tourDate));
  }

  @override
  Future<List<Tour>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    final tours = rows
        .map((r) {
          final map = jsonDecode(r.dataJson) as Map<String, dynamic>;
          map['id'] = r.localId;
          map['localId'] = r.localId;
          return fromMap(map);
        })
        .where((t) => !t.isDeleted)
        .toList();
    
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
    
    AppLogger.debug(
      'Tours récupérés: ${rows.length}, après déduplication par ID: ${toursByLocalId.length}',
      name: 'TourOfflineRepository.getAllForEnterprise',
    );
    
    // Déduplication intelligente finale basée sur le contenu (tourDate, etc.)
    return deduplicateIntelligently(toursByLocalId.values.toList());
  }

  // TourRepository implementation

  @override
  Stream<List<Tour>> watchTours(
    String enterpriseId, {
    TourStatus? status,
    DateTime? from,
    DateTime? to,
  }) {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((rows) {
          final tours = rows
              .map((r) {
                try {
                  final map = jsonDecode(r.dataJson) as Map<String, dynamic>;
                  map['id'] = r.localId;
                  map['localId'] = r.localId;
                  final tour = fromMap(map);
                  return tour.isDeleted ? null : tour;
                } catch (e) {
                  return null;
                }
              })
              .whereType<Tour>()
              .toList();

          final deduplicated = deduplicateByRemoteId(tours);
          
          final Map<String, Tour> toursByLocalId = {};
          for (final tour in deduplicated) {
            if (tour.id.startsWith('local_')) {
              if (!toursByLocalId.containsKey(tour.id)) {
                toursByLocalId[tour.id] = tour;
              }
            } else {
              toursByLocalId[tour.id] = tour;
            }
          }

          final intelligent = deduplicateIntelligently(toursByLocalId.values.toList());

          return intelligent.where((tour) {
            if (status != null && tour.status != status) return false;
            if (from != null && tour.tourDate.isBefore(from)) return false;
            if (to != null && tour.tourDate.isAfter(to)) return false;
            return true;
          }).toList()
            ..sort((a, b) => b.tourDate.compareTo(a.tourDate));
        });
  }

  @override
  Future<Tour?> getTourById(String id) async {
    try {
      AppLogger.debug(
        'Recherche du tour avec ID: $id',
        name: 'TourOfflineRepository.getTourById',
      );
      
      // Essayer d'abord avec getByLocalId
      var tour = await getByLocalId(id);
      
      // Si pas trouvé, essayer de chercher dans tous les tours de l'entreprise
      // au cas où l'ID dans le JSON ne correspond pas au localId
      if (tour == null) {
        AppLogger.debug(
          'Tour non trouvé avec getByLocalId, recherche dans tous les tours',
          name: 'TourOfflineRepository.getTourById',
        );
        final allTours = await getAllForEnterprise(enterpriseId);
        try {
          tour = allTours.firstWhere((t) => t.id == id);
          AppLogger.debug(
            'Tour trouvé dans la liste avec ID: ${tour.id}',
            name: 'TourOfflineRepository.getTourById',
          );
        } catch (e, stackTrace) {
          final appException = ErrorHandler.instance.handleError(e, stackTrace);
          AppLogger.warning(
            'Tour non trouvé dans la liste avec ID exact: $id - ${appException.message}',
            name: 'TourOfflineRepository.getTourById',
            error: e,
            stackTrace: stackTrace,
          );
          return null;
        }
      } else {
        AppLogger.debug(
          'Tour trouvé avec getByLocalId, ID: ${tour.id}',
          name: 'TourOfflineRepository.getTourById',
        );
      }
      
      return tour;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Erreur lors de la recherche du tour: $id - ${appException.message}',
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
      final tourWithLocalId = tour.copyWith(
        id: localId,
        updatedAt: DateTime.now(),
      );
      await save(tourWithLocalId);
      return localId;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error creating tour: ${appException.message}',
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
      final updatedTour = tour.copyWith(updatedAt: DateTime.now());
      await save(updatedTour);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error updating tour: ${tour.id} - ${appException.message}',
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
      AppLogger.debug(
        'Mise à jour du statut du tour: $id vers $status',
        name: 'TourOfflineRepository.updateStatus',
      );
      
      final tour = await getTourById(id);
      if (tour == null) {
        throw NotFoundException(
          'Tour introuvable avec ID: $id',
          'TOUR_NOT_FOUND',
        );
      }
      
      // Logger les données existantes pour vérifier qu'elles sont préservées
      AppLogger.debug(
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
      
      // Update updatedAt
      updated = updated.copyWith(updatedAt: DateTime.now());
      
      // Vérifier que les données sont préservées
      AppLogger.debug(
        'Tour mis à jour - Collections: ${updated.collections.length}, TransportExpenses: ${updated.transportExpenses.length}, Status: ${updated.status}',
        name: 'TourOfflineRepository.updateStatus',
      );
      
      await save(updated);
      
      AppLogger.debug(
        'Tour sauvegardé avec succès',
        name: 'TourOfflineRepository.updateStatus',
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Erreur lors de la mise à jour du statut du tour: $id - ${appException.message}',
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
      AppLogger.error(
        'Error cancelling tour: $id - ${appException.message}',
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
      AppLogger.error(
        'Error deleting tour: $id - ${appException.message}',
        name: 'TourOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }
}
