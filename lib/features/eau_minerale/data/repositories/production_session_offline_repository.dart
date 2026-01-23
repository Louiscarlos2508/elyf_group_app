import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../domain/entities/bobine_usage.dart';
import '../../domain/entities/payment_status.dart';
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
    // Support both our format (*Json string) and Firestore format (array)
    final bobinesUtilisees = _parseJsonList<BobineUsage>(
      map['bobinesUtiliseesJson'] ?? map['bobinesUtilisees'],
      (b) => _bobineUsageFromJson(b as Map<String, dynamic>),
      'bobinesUtilisees',
    );
    final events = _parseJsonList<ProductionEvent>(
      map['eventsJson'] ?? map['events'],
      (e) => _productionEventFromJson(e as Map<String, dynamic>),
      'events',
    );
    final productionDays = _parseJsonList<ProductionDay>(
      map['productionDaysJson'] ?? map['productionDays'],
      (d) => _productionDayFromJson(d as Map<String, dynamic>),
      'productionDays',
    );

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
      consommationCourant:
          (map['consommationCourant'] as num?)?.toDouble() ?? 0,
      machinesUtilisees: map['machinesUtilisees'] is List
          ? (map['machinesUtilisees'] as List)
              .map((e) => (e as Object?).toString())
              .toList()
          : <String>[],
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
      final session = fromMap(
        jsonDecode(byRemote.dataJson) as Map<String, dynamic>,
      );
      return _mergeLocalBobinesIfEmpty(session);
    }

    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
    );
    if (byLocal == null) return null;
    final session = fromMap(
      jsonDecode(byLocal.dataJson) as Map<String, dynamic>,
    );
    return _mergeLocalBobinesIfEmpty(session);
  }

  /// Si la session a des bobines vides, tente de les récupérer depuis une
  /// session locale (sans remoteId) même date+heure début — détail aligné
  /// avec la liste.
  Future<ProductionSession> _mergeLocalBobinesIfEmpty(
    ProductionSession session,
  ) async {
    if (session.bobinesUtilisees.isNotEmpty) return session;

    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
    );
    final key = _sessionKey(session);
    for (final r in rows) {
      final map = jsonDecode(r.dataJson) as Map<String, dynamic>;
      if (r.remoteId != null && r.remoteId!.isNotEmpty) continue;
      if (r.localId == session.id) continue;
      try {
        final other = fromMap(map);
        if (_sessionKey(other) != key) continue;
        if (other.bobinesUtilisees.isEmpty) continue;
        return session.copyWith(bobinesUtilisees: other.bobinesUtilisees);
      } catch (_) {
        continue;
      }
    }
    return session;
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
    final entities = rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .toList();

    var deduped = deduplicateByRemoteId(entities);
    deduped = _mergeLocalBobinesIntoSync(deduped);
    return deduped;
  }

  /// Clé pour matcher deux enregistrements de la même session (date + heure début).
  static String _sessionKey(ProductionSession s) {
    final d = s.date;
    final h = s.heureDebut;
    return '${d.year}-${d.month}-${d.day}-${h.hour}-${h.minute}';
  }

  /// Fusionne les bobines des sessions locales (sans remoteId) dans les sessions
  /// sync (avec remoteId) quand la sync a des bobines vides, pour éviter
  /// "détail montre bobines, ailleurs non" (list/card).
  List<ProductionSession> _mergeLocalBobinesIntoSync(
    List<ProductionSession> sessions,
  ) {
    final localByKey = <String, ProductionSession>{};
    final syncList = <ProductionSession>[];

    for (final s in sessions) {
      final key = _sessionKey(s);
      if (getRemoteId(s) != null) {
        syncList.add(s);
      } else {
        final existing = localByKey[key];
        if (existing == null ||
            (s.bobinesUtilisees.isNotEmpty &&
                existing.bobinesUtilisees.isEmpty)) {
          localByKey[key] = s;
        }
      }
    }

    final merged = <ProductionSession>[];
    for (final sync in syncList) {
      final key = _sessionKey(sync);
      final local = localByKey[key];
      if (sync.bobinesUtilisees.isEmpty &&
          local != null &&
          local.bobinesUtilisees.isNotEmpty) {
        merged.add(
          sync.copyWith(bobinesUtilisees: local.bobinesUtilisees),
        );
        localByKey.remove(key);
      } else {
        merged.add(sync);
      }
    }
    merged.addAll(localByKey.values);
    return merged;
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
            .where(
              (s) =>
                  s.date.isAfter(startDate) ||
                  s.date.isAtSameMomentAs(startDate),
            )
            .toList();
      }

      if (endDate != null) {
        allSessions = allSessions
            .where(
              (s) =>
                  s.date.isBefore(endDate) || s.date.isAtSameMomentAs(endDate),
            )
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
      AppLogger.error(
        'Error getting production session: $id - ${appException.message}',
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
      AppLogger.error(
        'Error creating production session: ${appException.message}',
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
      AppLogger.error(
        'Error updating production session: ${session.id} - ${appException.message}',
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
      AppLogger.error(
        'Error deleting production session: $id - ${appException.message}',
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

  /// Parse a JSON list field that may be stored as List or as JSON string.
  /// If the string was sanitized (quotes escaped as \\u0022), tries to reverse
  /// that before decoding to fix "Unexpected character" FormatException.
  List<T> _parseJsonList<T>(
    dynamic value,
    T Function(dynamic) itemMapper,
    String fieldName,
  ) {
    if (value == null) return [];
    if (value is List) {
      try {
        return value.map(itemMapper).toList();
      } catch (e, st) {
        AppLogger.warning(
          'Error parsing $fieldName (list): ${ErrorHandler.instance.handleError(e, st).message}',
          name: 'ProductionSessionOfflineRepository',
          error: e,
          stackTrace: st,
        );
        return [];
      }
    }
    if (value is! String) return [];
    Object? lastError;
    StackTrace? lastStack;
    for (final raw in [value, value.replaceAll(r'\u0022', '"')]) {
      try {
        var decoded = jsonDecode(raw);
        // Double-encoded: decoded is a JSON string to decode again
        if (decoded is String) {
          decoded = jsonDecode(decoded);
        }
        if (decoded is! List) return [];
        return List<dynamic>.from(decoded).map(itemMapper).toList();
      } catch (e, st) {
        lastError = e;
        lastStack = st;
      }
    }
    AppLogger.warning(
      'Error parsing $fieldName: ${ErrorHandler.instance.handleError(lastError!, lastStack!).message}',
      name: 'ProductionSessionOfflineRepository',
      error: lastError,
      stackTrace: lastStack,
    );
    return [];
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
    final map = <String, dynamic>{
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
      'paymentStatus': day.paymentStatus.name,
      'paymentId': day.paymentId,
      'datePaiement': day.datePaiement?.toIso8601String(),
    };
    if (day.coutTotalPersonnelStored != null) {
      map['coutTotalPersonnelStored'] = day.coutTotalPersonnelStored;
    }
    return map;
  }

  ProductionDay _productionDayFromJson(Map<String, dynamic> json) {
    return ProductionDay(
      id: json['id'] as String,
      productionId: json['productionId'] as String,
      date: DateTime.parse(json['date'] as String),
      personnelIds: (json['personnelIds'] as List).cast<String>(),
      nombrePersonnes: json['nombrePersonnes'] as int,
      salaireJournalierParPersonne: json['salaireJournalierParPersonne'] as int,
      coutTotalPersonnelStored:
          (json['coutTotalPersonnelStored'] as num?)?.toInt(),
      packsProduits: json['packsProduits'] as int? ?? 0,
      emballagesUtilises: json['emballagesUtilises'] as int? ?? 0,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      paymentStatus: _parsePaymentStatus(json['paymentStatus'] as String?),
      paymentId: json['paymentId'] as String?,
      datePaiement: json['datePaiement'] != null
          ? DateTime.parse(json['datePaiement'] as String)
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

  PaymentStatus _parsePaymentStatus(String? status) {
    if (status == null) return PaymentStatus.unpaid;
    switch (status) {
      case "unpaid":
        return PaymentStatus.unpaid;
      case "partial":
        return PaymentStatus.partial;
      case "paid":
        return PaymentStatus.paid;
      case "verified":
        return PaymentStatus.verified;
      default:
        return PaymentStatus.unpaid;
    }
  }

