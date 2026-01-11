import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../domain/entities/bobine_usage.dart';
import '../../domain/entities/production_day.dart';
import '../../domain/entities/production_event.dart';
import '../../domain/entities/production_session.dart';
import '../../domain/entities/production_session_status.dart';
import '../../domain/repositories/production_session_repository.dart';

/// Offline-first repository for ProductionSession entities.
class ProductionSessionOfflineRepository
    extends OfflineRepository<ProductionSession>
    implements ProductionSessionRepository {
  ProductionSessionOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
  });

  final String enterpriseId;

  @override
  String get collectionName => 'production_sessions';

  @override
  ProductionSession fromMap(Map<String, dynamic> map) {
    // Parse bobinesUtilisees from JSON
    List<BobineUsage> bobinesUtilisees = [];
    if (map['bobinesUtiliseesJson'] != null) {
      try {
        final bobinesList = jsonDecode(map['bobinesUtiliseesJson'] as String)
            as List<dynamic>;
        bobinesUtilisees = bobinesList
            .map((b) => _bobineUsageFromJson(b as Map<String, dynamic>))
            .toList();
      } catch (e) {
        developer.log(
          'Error parsing bobinesUtilisees: $e',
          name: 'ProductionSessionOfflineRepository',
        );
      }
    }

    // Parse events from JSON
    List<ProductionEvent> events = [];
    if (map['eventsJson'] != null) {
      try {
        final eventsList =
            jsonDecode(map['eventsJson'] as String) as List<dynamic>;
        events = eventsList
            .map((e) => _productionEventFromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        developer.log(
          'Error parsing events: $e',
          name: 'ProductionSessionOfflineRepository',
        );
      }
    }

    // Parse productionDays from JSON
    List<ProductionDay> productionDays = [];
    if (map['productionDaysJson'] != null) {
      try {
        final daysList =
            jsonDecode(map['productionDaysJson'] as String) as List<dynamic>;
        productionDays = daysList
            .map((d) => _productionDayFromJson(d as Map<String, dynamic>))
            .toList();
      } catch (e) {
        developer.log(
          'Error parsing productionDays: $e',
          name: 'ProductionSessionOfflineRepository',
        );
      }
    }

    return ProductionSession(
      id: map['id'] as String? ?? map['localId'] as String,
      date: DateTime.parse(map['date'] as String),
      period: map['period'] as int? ?? 0,
      heureDebut: DateTime.parse(map['heureDebut'] as String),
      heureFin: map['heureFin'] != null
          ? DateTime.parse(map['heureFin'] as String)
          : null,
      indexCompteurInitialKwh: map['indexCompteurInitialKwh'] as int?,
      indexCompteurFinalKwh: map['indexCompteurFinalKwh'] as int?,
      consommationCourant: (map['consommationCourant'] as num?)?.toDouble() ?? 0,
      machinesUtilisees: map['machinesUtilisees'] != null
          ? (map['machinesUtilisees'] as List).cast<String>()
          : [],
      bobinesUtilisees: bobinesUtilisees,
      quantiteProduite: map['quantiteProduite'] as int? ?? 0,
      quantiteProduiteUnite: map['quantiteProduiteUnite'] as String,
      emballagesUtilises: map['emballagesUtilises'] as int?,
      coutBobines: map['coutBobines'] as int?,
      coutElectricite: map['coutElectricite'] as int?,
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      status: _parseStatus(map['status'] as String? ?? 'draft'),
      events: events,
      productionDays: productionDays,
    );
  }

  @override
  Map<String, dynamic> toMap(ProductionSession entity) {
    return {
      'id': entity.id,
      'date': entity.date.toIso8601String(),
      'period': entity.period,
      'heureDebut': entity.heureDebut.toIso8601String(),
      'heureFin': entity.heureFin?.toIso8601String(),
      'indexCompteurInitialKwh': entity.indexCompteurInitialKwh,
      'indexCompteurFinalKwh': entity.indexCompteurFinalKwh,
      'consommationCourant': entity.consommationCourant,
      'machinesUtilisees': entity.machinesUtilisees,
      'bobinesUtiliseesJson': jsonEncode(
        entity.bobinesUtilisees.map((b) => _bobineUsageToJson(b)).toList(),
      ),
      'quantiteProduite': entity.quantiteProduite,
      'quantiteProduiteUnite': entity.quantiteProduiteUnite,
      'emballagesUtilises': entity.emballagesUtilises,
      'coutBobines': entity.coutBobines,
      'coutElectricite': entity.coutElectricite,
      'notes': entity.notes,
      'status': entity.status.name,
      'eventsJson': jsonEncode(
        entity.events.map((e) => _productionEventToJson(e)).toList(),
      ),
      'productionDaysJson': jsonEncode(
        entity.productionDays.map((d) => _productionDayToJson(d)).toList(),
      ),
      'createdAt': entity.createdAt?.toIso8601String(),
      'updatedAt': entity.updatedAt?.toIso8601String(),
    };
  }

  @override
  String getLocalId(ProductionSession entity) {
    if (entity.id.startsWith('local_')) {
      return entity.id;
    }
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(ProductionSession entity) {
    if (!entity.id.startsWith('local_')) {
      return entity.id;
    }
    return null;
  }

  @override
  String? getEnterpriseId(ProductionSession entity) => enterpriseId;

  @override
  Future<void> saveToLocal(ProductionSession entity) async {
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
  Future<void> deleteFromLocal(ProductionSession entity) async {
    final remoteId = getRemoteId(entity);
    if (remoteId != null) {
      await driftService.records.deleteByRemoteId(
        collectionName: collectionName,
        remoteId: remoteId,
        enterpriseId: enterpriseId,
        moduleType: 'eau_minerale',
      );
      return;
    }
    final localId = getLocalId(entity);
    await driftService.records.deleteByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
    );
  }

  @override
  Future<ProductionSession?> getByLocalId(String localId) async {
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
  Future<List<ProductionSession>> getAllForEnterprise(
    String enterpriseId,
  ) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
    );
    return rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .toList();
  }

  // ProductionSessionRepository interface implementation

  @override
  Future<List<ProductionSession>> fetchSessions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      developer.log(
        'Fetching production sessions for enterprise: $enterpriseId',
        name: 'ProductionSessionOfflineRepository',
      );
      var allSessions = await getAllForEnterprise(enterpriseId);

      if (startDate != null) {
        allSessions = allSessions
            .where((s) =>
                s.date.isAfter(startDate) || s.date.isAtSameMomentAs(startDate))
            .toList();
      }

      if (endDate != null) {
        allSessions = allSessions
            .where((s) =>
                s.date.isBefore(endDate) || s.date.isAtSameMomentAs(endDate))
            .toList();
      }

      // Sort by date descending
      allSessions.sort((a, b) => b.date.compareTo(a.date));

      return allSessions;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching production sessions',
        name: 'ProductionSessionOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<ProductionSession?> fetchSessionById(String id) async {
    try {
      return await getByLocalId(id);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting production session: $id',
        name: 'ProductionSessionOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<ProductionSession> createSession(ProductionSession session) async {
    try {
      final localId = getLocalId(session);
      final sessionWithLocalId = session.copyWith(id: localId);
      await save(sessionWithLocalId);
      return sessionWithLocalId;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error creating production session',
        name: 'ProductionSessionOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<ProductionSession> updateSession(ProductionSession session) async {
    try {
      await save(session);
      return session;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error updating production session: ${session.id}',
        name: 'ProductionSessionOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> deleteSession(String id) async {
    try {
      final session = await fetchSessionById(id);
      if (session != null) {
        await delete(session);
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error deleting production session: $id',
        name: 'ProductionSessionOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  ProductionSessionStatus _parseStatus(String status) {
    switch (status) {
      case 'draft':
        return ProductionSessionStatus.draft;
      case 'started':
        return ProductionSessionStatus.started;
      case 'inProgress':
        return ProductionSessionStatus.inProgress;
      case 'suspended':
        return ProductionSessionStatus.suspended;
      case 'completed':
        return ProductionSessionStatus.completed;
      default:
        return ProductionSessionStatus.draft;
    }
  }

  Map<String, dynamic> _bobineUsageToJson(BobineUsage bobine) {
    return {
      'bobineType': bobine.bobineType,
      'machineId': bobine.machineId,
      'machineName': bobine.machineName,
      'dateInstallation': bobine.dateInstallation.toIso8601String(),
      'heureInstallation': bobine.heureInstallation.toIso8601String(),
      'dateUtilisation': bobine.dateUtilisation?.toIso8601String(),
      'estInstallee': bobine.estInstallee,
      'estFinie': bobine.estFinie,
    };
  }

  BobineUsage _bobineUsageFromJson(Map<String, dynamic> json) {
    return BobineUsage(
      bobineType: json['bobineType'] as String,
      machineId: json['machineId'] as String,
      machineName: json['machineName'] as String,
      dateInstallation: DateTime.parse(json['dateInstallation'] as String),
      heureInstallation: DateTime.parse(json['heureInstallation'] as String),
      dateUtilisation: json['dateUtilisation'] != null
          ? DateTime.parse(json['dateUtilisation'] as String)
          : null,
      estInstallee: json['estInstallee'] as bool? ?? true,
      estFinie: json['estFinie'] as bool? ?? false,
    );
  }

  Map<String, dynamic> _productionEventToJson(ProductionEvent event) {
    return {
      'id': event.id,
      'productionId': event.productionId,
      'type': event.type.name,
      'date': event.date.toIso8601String(),
      'heure': event.heure.toIso8601String(),
      'motif': event.motif,
      'duree': event.duree?.inMinutes,
      'heureReprise': event.heureReprise?.toIso8601String(),
      'notes': event.notes,
      'createdAt': event.createdAt?.toIso8601String(),
      'estTermine': event.estTermine,
    };
  }

  ProductionEvent _productionEventFromJson(Map<String, dynamic> json) {
    return ProductionEvent(
      id: json['id'] as String,
      productionId: json['productionId'] as String,
      type: _parseEventType(json['type'] as String),
      date: DateTime.parse(json['date'] as String),
      heure: DateTime.parse(json['heure'] as String),
      motif: json['motif'] as String,
      duree: json['duree'] != null
          ? Duration(minutes: json['duree'] as int)
          : null,
      heureReprise: json['heureReprise'] != null
          ? DateTime.parse(json['heureReprise'] as String)
          : null,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> _productionDayToJson(ProductionDay day) {
    return {
      'id': day.id,
      'productionId': day.productionId,
      'date': day.date.toIso8601String(),
      'personnelIds': day.personnelIds,
      'nombrePersonnes': day.nombrePersonnes,
      'salaireJournalierParPersonne': day.salaireJournalierParPersonne,
      'packsProduits': day.packsProduits,
      'emballagesUtilises': day.emballagesUtilises,
      'notes': day.notes,
      'createdAt': day.createdAt?.toIso8601String(),
      'updatedAt': day.updatedAt?.toIso8601String(),
    };
  }

  ProductionDay _productionDayFromJson(Map<String, dynamic> json) {
    return ProductionDay(
      id: json['id'] as String,
      productionId: json['productionId'] as String,
      date: DateTime.parse(json['date'] as String),
      personnelIds: (json['personnelIds'] as List).cast<String>(),
      nombrePersonnes: json['nombrePersonnes'] as int,
      salaireJournalierParPersonne:
          json['salaireJournalierParPersonne'] as int,
      packsProduits: json['packsProduits'] as int? ?? 0,
      emballagesUtilises: json['emballagesUtilises'] as int? ?? 0,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  ProductionEventType _parseEventType(String type) {
    switch (type) {
      case 'panne':
        return ProductionEventType.panne;
      case 'coupure':
        return ProductionEventType.coupure;
      case 'arretForce':
        return ProductionEventType.arretForce;
      default:
        return ProductionEventType.panne;
    }
  }
}

