import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/tour.dart';
import '../data/models/collecte_entry.dart';
import '../data/models/recharge_entry.dart';
import '../data/models/livraison_entry.dart';
import '../data/models/frais_entry.dart';
import '../data/models/bilan_tour.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/tour.dart' as domain;
import 'package:elyf_groupe_app/features/gaz/domain/entities/pos_remittance.dart';
import 'package:elyf_groupe_app/features/gaz/domain/repositories/tour_repository.dart';
import 'package:elyf_groupe_app/features/gaz/domain/services/tour_service.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/core/auth/providers.dart';
import 'package:elyf_groupe_app/core/offline/providers.dart';
import 'package:elyf_groupe_app/core/offline/offline_repository.dart';

// TourState contient TOUT l'état du tour en cours
class TourState {
  final String tourId;
  final TourStatus status;
  final List<CollecteEntry> collectes;
  final RechargeEntry? recharge;
  final List<LivraisonEntry> livraisons;
  final List<FraisEntry> frais;
  final TruckState truckState;
  final bool isLoading;
  final String? error;

  const TourState({
    required this.tourId,
    required this.status,
    this.collectes = const [],
    this.recharge,
    this.livraisons = const [],
    this.frais = const [],
    this.truckState = const TruckState(videsEnCamion: {}, pleinesEnCamion: {}, cashEncaisse: 0),
    this.isLoading = false,
    this.error,
  });

  TourState copyWith({
    String? tourId,
    TourStatus? status,
    List<CollecteEntry>? collectes,
    RechargeEntry? recharge,
    List<LivraisonEntry>? livraisons,
    List<FraisEntry>? frais,
    TruckState? truckState,
    bool? isLoading,
    String? error,
  }) {
    return TourState(
      tourId: tourId ?? this.tourId,
      status: status ?? this.status,
      collectes: collectes ?? this.collectes,
      recharge: recharge ?? this.recharge,
      livraisons: livraisons ?? this.livraisons,
      frais: frais ?? this.frais,
      truckState: truckState ?? this.truckState,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  BilanTour toBilan() {
    final totalVidesCollectes = collectes.fold(0, (sum, c) => sum + c.quantitesVides.values.fold(0, (a, b) => a + b));
    final totalPleinesLivrees = livraisons.fold(0, (sum, l) => sum + l.totalBouteilles);
    final totalEncaisse = livraisons.fold(0, (sum, l) => sum + l.montantEncaisse);
    final totalFrais = frais.fold(0, (sum, f) => sum + f.montant);
    final coutRecharge = recharge?.coutAchat ?? 0;
    final stockResiduel = truckState.totalPleines + truckState.totalVides;

    // Génération du détail par site
    final Map<String, SiteBilan> siteMap = {};

    for (final c in collectes) {
      final existing = siteMap[c.siteId];
      final Map<int, int> entrees = TourState._mapFormatToWeight(c.quantitesVides);
      
      if (existing != null) {
        final Map<int, int> aggregatedEntrees = Map.from(existing.entrees);
        entrees.forEach((w, q) => aggregatedEntrees[w] = (aggregatedEntrees[w] ?? 0) + q);
        siteMap[c.siteId] = SiteBilan(
          siteName: existing.siteName,
          entrees: aggregatedEntrees,
          sorties: existing.sorties,
          encaissement: existing.encaissement,
        );
      } else {
        siteMap[c.siteId] = SiteBilan(
          siteName: c.siteName,
          entrees: entrees,
          sorties: {},
          encaissement: 0,
        );
      }
    }

    for (final l in livraisons) {
      final existing = siteMap[l.siteId];
      final Map<int, int> sorties = TourState._mapFormatToWeight(
        l.lignes.fold<Map<FormatBouteille, int>>({}, (map, ligne) {
          map[ligne.format] = (map[ligne.format] ?? 0) + ligne.quantiteLivree;
          return map;
        }),
      );

      if (existing != null) {
        final Map<int, int> aggregatedSorties = Map.from(existing.sorties);
        sorties.forEach((w, q) => aggregatedSorties[w] = (aggregatedSorties[w] ?? 0) + q);
        
        siteMap[l.siteId] = SiteBilan(
          siteName: existing.siteName,
          entrees: existing.entrees,
          sorties: aggregatedSorties,
          encaissement: existing.encaissement + l.montantEncaisse.toDouble(),
        );
      } else {
        siteMap[l.siteId] = SiteBilan(
          siteName: l.siteName,
          entrees: {},
          sorties: sorties,
          encaissement: l.montantEncaisse.toDouble(),
        );
      }
    }

    return BilanTour(
      siteBreakdowns: siteMap.values.toList(),
      totalVidesCollectes: totalVidesCollectes,
      totalPleinesLivrees: totalPleinesLivrees,
      stockResiduel: stockResiduel,
      totalEncaisse: totalEncaisse,
      coutRecharge: coutRecharge,
      totalFrais: totalFrais,
    );
  }

  static Map<int, int> _mapFormatToWeight(Map<FormatBouteille, int> formats) {
    return formats.map((f, q) => MapEntry(_getWeightFromLabel(f.label), q));
  }

  static int _getWeightFromLabel(String label) {
    return int.tryParse(label.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }
}

// TourNotifier gère toutes les transitions
class TourNotifier extends AsyncNotifier<TourState> {
  final String tourId;
  TourNotifier(this.tourId);

  late final TourRepository _repository;
  late final TourService _service;

  @override
  FutureOr<TourState> build() async {
    _repository = ref.watch(tourRepositoryProvider);
    _service = ref.watch(tourServiceProvider);

    if (tourId.isEmpty) {
      return const TourState(
        tourId: '',
        status: TourStatus.created,
      );
    }

    // Chargement du tour existant
    final tour = await _repository.getTourById(tourId);
    if (tour == null) throw Exception('Tour introuvable');

    final formats = ref.watch(formatsActifsProvider);
    if (formats.isEmpty) {
      // Retourner un état de chargement si les formats ne sont pas encore prêts
      return TourState(tourId: tourId, status: TourStatus.created, isLoading: true);
    }

    return _mapDomainToState(tour, formats);
  }

  TourState _mapDomainToState(domain.Tour tour, List<FormatBouteille> formats) {

    // 1. Collectes
    final collectes = tour.siteInteractions
        .where((i) => i.emptyBottlesCollected.isNotEmpty)
        .map((i) => CollecteEntry(
              siteId: i.siteId,
              siteName: i.siteName,
              siteType: i.siteType == domain.SiteType.pos ? TypeSite.pos : TypeSite.grossiste,
              quantitesVides: _mapWeightToFormat(i.emptyBottlesCollected, formats),
              timestamp: i.timestamp,
            ))
        .toList();

    // 2. Recharge
    RechargeEntry? recharge;
    if (tour.receptionCompletedDate != null) {
      recharge = RechargeEntry(
        videsRendus: _mapWeightToFormat(tour.emptyBottlesReturned, formats),
        pleinesRecues: _mapWeightToFormat(tour.fullBottlesReceived, formats),
        coutAchat: (tour.gasPurchaseCost ?? 0).toInt(),
        timestamp: tour.receptionCompletedDate!,
      );
    }

    // 3. Livraisons
    final livraisons = tour.siteInteractions
        .where((i) => i.fullBottlesDelivered.isNotEmpty)
        .map((i) => LivraisonEntry(
              siteId: i.siteId,
              siteName: i.siteName,
              typeSite: i.siteType == domain.SiteType.pos ? TypeSite.pos : TypeSite.grossiste,
              montantEncaisse: i.cashCollected.toInt(),
              timestamp: i.timestamp,
              lignes: i.fullBottlesDelivered.entries.map((e) {
                final format = formats.firstWhere(
                  (f) => _getWeightFromLabel(f.label) == e.key,
                  orElse: () => formats.first,
                );
                return LivraisonLigne(
                  format: format,
                  quantiteLivree: e.value,
                  prixUnitaire: format.prixVente,
                );
              }).toList(),
            ))
        .toList();

    // 4. Frais
    final fraisList = tour.transportExpenses.map((e) => FraisEntry(
          id: e.id,
          categorie: _mapDomainCategoryToUI(e.category),
          montant: e.amount.toInt(),
          timestamp: e.expenseDate,
          note: e.description,
        )).toList();

    final status = _mapDomainStatusToUI(tour);

    final state = TourState(
      tourId: tour.id,
      status: status,
      collectes: collectes,
      recharge: recharge,
      livraisons: livraisons,
      frais: fraisList,
    );

    return state.copyWith(truckState: _recalculateTruckState(state));
  }

  Map<FormatBouteille, int> _mapWeightToFormat(Map<int, int> weights, List<FormatBouteille> formats) {
    return weights.map((w, q) {
      final format = formats.firstWhere(
        (f) => _getWeightFromLabel(f.label) == w,
        orElse: () => formats.first,
      );
      return MapEntry(format, q);
    });
  }

  int _getWeightFromLabel(String label) {
    return int.tryParse(label.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  CategorieFrais _mapDomainCategoryToUI(String category) {
    return switch (category.toLowerCase()) {
      'fuel' || 'carburant' => CategorieFrais.carburant,
      'meal' || 'repas'     => CategorieFrais.repas,
      'toll' || 'peage'     => CategorieFrais.peage,
      _                     => CategorieFrais.autre,
    };
  }

  TourStatus _mapDomainStatusToUI(domain.Tour tour) {
    return TourStatusExtension.fromDomain(tour);
  }

  // Transitions d'état
  Future<void> startTour() async {
    state = const AsyncLoading();
    try {
      final activeEnterprise = ref.read(activeEnterpriseProvider).value;
      if (activeEnterprise == null) throw Exception('Aucune entreprise active');

      final tour = domain.Tour(
        id: '', 
        enterpriseId: activeEnterprise.id,
        tourDate: DateTime.now(),
        status: domain.TourStatus.open,
      );

      final newId = await _repository.createTour(tour);
      
      // Sync immédiat
      await ref.read(syncManagerProvider).syncPendingOperations();
      
      final newState = TourState(
        tourId: newId,
        status: TourStatus.collecting,
      );
      state = AsyncData(newState);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> goToRecharge() async {
    final s = state.value!;
    if (s.collectes.isEmpty) throw Exception('Aucune collecte enregistrée');
    
    await _service.validateTransport(s.tourId);
    
    // Sync immédiat
    await ref.read(syncManagerProvider).syncPendingOperations();
    
    state = AsyncData(s.copyWith(status: TourStatus.recharging));
  }

  Future<void> confirmRecharge(RechargeEntry r) async {
    final s = state.value!;
    if (r.coutAchat <= 0) throw Exception('Le coût d\'achat doit être supérieur à 0');
    
    final userId = ref.read(currentUserProvider).value?.id ?? 'unknown';
    final formats = ref.read(formatsActifsProvider);
    final weightToCylinderId = {
      for (final f in formats) _getWeightFromLabel(f.label): f.id
    };

    await _service.updateSupplierRecharge(
      tourId: s.tourId,
      userId: userId,
      fullReceived: _mapFormatToWeight(r.pleinesRecues),
      emptyReturned: _mapFormatToWeight(r.videsRendus),
      weightToCylinderId: weightToCylinderId,
      gasCost: r.coutAchat.toDouble(),
    );

    // Sync immédiat
    await ref.read(syncManagerProvider).syncPendingOperations();
    

    final newState = s.copyWith(
      recharge: r,
      status: TourStatus.delivering,
    );
    state = AsyncData(newState.copyWith(truckState: _recalculateTruckState(newState)));
  }

  Future<void> startClosing() async {
    final s = state.value!;
    if (s.status == TourStatus.closing) return; // Déjà en cours
    if (s.livraisons.isEmpty) throw Exception('Aucune livraison enregistrée');
    
    try {
      await _service.validateClosing(s.tourId);
      state = AsyncData(s.copyWith(status: TourStatus.closing));
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }

  Future<void> validateClosure() async {
    final s = state.value!;
    final userId = ref.read(currentUserProvider).value?.id ?? 'unknown';

    // 1. Construire la map poids -> cylinderId basée sur les formats actifs
    final formats = ref.read(formatsActifsProvider);
    final weightToCylinderId = {
      for (final f in formats) _getWeightFromLabel(f.label): f.id
    };

    try {
      await _service.closeTour(
        s.tourId,
        userId,
        remainingFull: _mapFormatToWeight(s.truckState.pleinesEnCamion),
        remainingEmpty: _mapFormatToWeight(s.truckState.videsEnCamion),
        weightToCylinderId: weightToCylinderId,
      );

      // Sync immédiat
      await ref.read(syncManagerProvider).syncPendingOperations();

      if (ref.mounted) {
        state = AsyncData(s.copyWith(status: TourStatus.closed));
      }
    } catch (e) {
      // Ne pas laisser le notifier dans un état indéfini en cas d'erreur de clôture
      // Mais on re-throw pour que l'UI puisse afficher l'erreur
      rethrow;
    }
  }

  // Actions métier
  Future<void> addCollecte(CollecteEntry entry) async {
    final s = state.value!;
    
    final userId = ref.read(currentUserProvider).value?.id ?? 'unknown';
    final formats = ref.read(formatsActifsProvider);
    final weightToCylinderId = {
      for (final f in formats) _getWeightFromLabel(f.label): f.id
    };

    final siteInteraction = domain.TourSiteInteraction(
      id: LocalIdGenerator.generate(),
      siteId: entry.siteId,
      siteName: entry.siteName,
      siteType: entry.siteType == TypeSite.pos ? domain.SiteType.pos : domain.SiteType.wholesaler,
      emptyBottlesCollected: _mapFormatToWeight(entry.quantitesVides),
      fullBottlesDelivered: {},
      timestamp: entry.timestamp,
    );

    await _service.addSiteInteraction(
      tourId: s.tourId,
      record: siteInteraction,
      userId: userId,
      weightToCylinderId: weightToCylinderId,
    );

    // Sync immédiat
    await ref.read(syncManagerProvider).syncPendingOperations();

    final updatedCollectes = List<CollecteEntry>.from(s.collectes)..add(entry);
    final newState = s.copyWith(collectes: updatedCollectes);
    state = AsyncData(newState.copyWith(truckState: _recalculateTruckState(newState)));
  }

  // Helper pour le mapping
  Map<int, int> _mapFormatToWeight(Map<FormatBouteille, int> data) {
    return data.map((f, q) {
      final weight = _getWeightFromLabel(f.label);
      return MapEntry(weight, q);
    });
  }

  Future<void> updateCollecte(String siteId, CollecteEntry updated) async {
    final s = state.value!;
    final userId = ref.read(currentUserProvider).value?.id ?? 'unknown';
    final formats = ref.read(formatsActifsProvider);
    final weightToCylinderId = {
      for (final f in formats) _getWeightFromLabel(f.label): f.id
    };
    
    // 1. Persistance domaine et correction de stock
    final tour = await _repository.getTourById(s.tourId);
    if (tour != null) {
      final oldInteraction = tour.siteInteractions.firstWhere((i) => i.siteId == siteId && i.emptyBottlesCollected.isNotEmpty);
      final newInteraction = oldInteraction.copyWith(
        siteName: updated.siteName,
        emptyBottlesCollected: _mapFormatToWeight(updated.quantitesVides),
        timestamp: updated.timestamp,
      );

      // Calculer la différence pour la correction de stock
      final diffEmpty = <int, int>{};
      final allWeights = {...oldInteraction.emptyBottlesCollected.keys, ...newInteraction.emptyBottlesCollected.keys};
      for (final w in allWeights) {
        final d = (newInteraction.emptyBottlesCollected[w] ?? 0) - (oldInteraction.emptyBottlesCollected[w] ?? 0);
        if (d != 0) diffEmpty[w] = d;
      }

      if (diffEmpty.isNotEmpty) {
        // Appliquer la correction via une interaction technique
        final correction = domain.TourSiteInteraction(
          id: 'correction_${LocalIdGenerator.generate()}',
          siteId: siteId,
          siteName: updated.siteName,
          siteType: updated.siteType == TypeSite.pos ? domain.SiteType.pos : domain.SiteType.wholesaler,
          emptyBottlesCollected: diffEmpty,
          fullBottlesDelivered: {},
          timestamp: DateTime.now(),
        );
        // On ne passe pas par _service.addSiteInteraction car on ne veut pas ajouter une nouvelle ligne
        // mais on veut juste que le TransactionService traite le stock.
        // TODO: Ajouter une méthode dédiée dans TourService/TransactionService pour les corrections
        await _service.adjustStock(
          tourId: s.tourId,
          correction: correction,
          userId: userId,
          weightToCylinderId: weightToCylinderId,
        );
      }

      final updatedInteractions = tour.siteInteractions.map((i) {
        if (i.siteId == siteId && i.emptyBottlesCollected.isNotEmpty) {
          return newInteraction;
        }
        return i;
      }).toList();
      await _repository.updateTour(tour.copyWith(siteInteractions: updatedInteractions));

      // Sync immédiat
      await ref.read(syncManagerProvider).syncPendingOperations();
    }

    // 2. Mise à jour mémoire
    final updatedCollectes = s.collectes.map((c) => c.siteId == siteId ? updated : c).toList();
    final newState = s.copyWith(collectes: updatedCollectes);
    state = AsyncData(newState.copyWith(truckState: _recalculateTruckState(newState)));
  }

  Future<void> updateLivraison(String siteId, LivraisonEntry updated) async {
    final s = state.value!;
    final userId = ref.read(currentUserProvider).value?.id ?? 'unknown';
    final formats = ref.read(formatsActifsProvider);
    final weightToCylinderId = {
      for (final f in formats) _getWeightFromLabel(f.label): f.id
    };
    
    // 1. Persistance domaine et correction de stock
    final tour = await _repository.getTourById(s.tourId);
    if (tour != null) {
      final oldInteraction = tour.siteInteractions.firstWhere((i) => i.siteId == siteId && i.fullBottlesDelivered.isNotEmpty);
      
      final newFullBottles = updated.lignes.fold<Map<int, int>>({}, (map, ligne) {
        final w = _getWeightFromLabel(ligne.format.label);
        map[w] = (map[w] ?? 0) + ligne.quantiteLivree;
        return map;
      });

      final newInteraction = oldInteraction.copyWith(
        siteName: updated.siteName,
        fullBottlesDelivered: newFullBottles,
        timestamp: updated.timestamp,
      );

      // Calculer la différence pour la correction de stock
      final diffFull = <int, int>{};
      final allWeights = {...oldInteraction.fullBottlesDelivered.keys, ...newInteraction.fullBottlesDelivered.keys};
      for (final w in allWeights) {
        final d = (newInteraction.fullBottlesDelivered[w] ?? 0) - (oldInteraction.fullBottlesDelivered[w] ?? 0);
        if (d != 0) diffFull[w] = d;
      }

      if (diffFull.isNotEmpty) {
        final correction = domain.TourSiteInteraction(
          id: 'correction_${LocalIdGenerator.generate()}',
          siteId: siteId,
          siteName: updated.siteName,
          siteType: updated.typeSite == TypeSite.grossiste ? domain.SiteType.wholesaler : domain.SiteType.pos,
          emptyBottlesCollected: {},
          fullBottlesDelivered: diffFull,
          timestamp: DateTime.now(),
        );

        await _service.adjustStock(
          tourId: s.tourId,
          correction: correction,
          userId: userId,
          weightToCylinderId: weightToCylinderId,
        );
      }

      final updatedInteractions = tour.siteInteractions.map((i) {
        if (i.siteId == siteId && i.fullBottlesDelivered.isNotEmpty) {
          return newInteraction;
        }
        return i;
      }).toList();
      await _repository.updateTour(tour.copyWith(siteInteractions: updatedInteractions));

      // Sync immédiat
      await ref.read(syncManagerProvider).syncPendingOperations();
    }

    // 2. Mise à jour mémoire
    final updatedLivraisons = s.livraisons.map((c) => c.siteId == siteId ? updated : c).toList();
    final newState = s.copyWith(livraisons: updatedLivraisons);
    state = AsyncData(newState.copyWith(truckState: _recalculateTruckState(newState)));
  }

  Future<void> addLivraison(LivraisonEntry entry) async {
    final s = state.value!;
    
    final userId = ref.read(currentUserProvider).value?.id ?? 'unknown';
    final formats = ref.read(formatsActifsProvider);
    final weightToCylinderId = {
      for (final f in formats) _getWeightFromLabel(f.label): f.id
    };

    await _service.addSiteInteraction(
      tourId: s.tourId,
      record: domain.TourSiteInteraction(
        id: LocalIdGenerator.generate(),
        siteId: entry.siteId,
        siteName: entry.siteName,
        siteType: entry.typeSite == TypeSite.grossiste ? domain.SiteType.wholesaler : domain.SiteType.pos,
        emptyBottlesCollected: {},
        fullBottlesDelivered: _mapFormatToWeight(
          entry.lignes.fold<Map<FormatBouteille, int>>({}, (map, ligne) {
            map[ligne.format] = (map[ligne.format] ?? 0) + ligne.quantiteLivree;
            return map;
          }),
        ),
        cashCollected: entry.montantEncaisse.toDouble(),
        timestamp: entry.timestamp,
      ),
      userId: userId,
      weightToCylinderId: weightToCylinderId,
    );

    // Sync immédiat
    await ref.read(syncManagerProvider).syncPendingOperations();

    final updatedLivraisons = List<LivraisonEntry>.from(s.livraisons)..add(entry);
    final newState = s.copyWith(livraisons: updatedLivraisons);
    state = AsyncData(newState.copyWith(truckState: _recalculateTruckState(newState)));
  }

  Future<void> addFrais(FraisEntry frais) async {
    final s = state.value!;
    
    // Ajout persistant dans le domaine
    final tour = await _repository.getTourById(s.tourId);
    if (tour != null) {
      final updatedExpenses = List<domain.TransportExpense>.from(tour.transportExpenses)
        ..add(domain.TransportExpense(
          id: frais.id,
          category: frais.categorie.name,
          amount: frais.montant.toDouble(),
          description: frais.note ?? '',
          expenseDate: DateTime.now(),
        ));
      
      final newStatus = tour.status == domain.TourStatus.open ? domain.TourStatus.collecting : tour.status;
    
    await _repository.updateTour(tour.copyWith(
      transportExpenses: updatedExpenses,
      status: newStatus,
    ));

      // Sync immédiat
      await ref.read(syncManagerProvider).syncPendingOperations();
    }

    final updatedFrais = List<FraisEntry>.from(s.frais)..add(frais);
    final newState = s.copyWith(frais: updatedFrais);
    state = AsyncData(newState.copyWith(truckState: _recalculateTruckState(newState)));
  }

  Future<void> deleteFrais(String fraisId) async {
    final s = state.value!;
    
    final tour = await _repository.getTourById(s.tourId);
    if (tour != null) {
      final updatedExpenses = tour.transportExpenses.where((e) => e.id != fraisId).toList();
      await _repository.updateTour(tour.copyWith(transportExpenses: updatedExpenses));
      
      // Sync immédiat
      await ref.read(syncManagerProvider).syncPendingOperations();
    }

    final updatedFrais = s.frais.where((f) => f.id != fraisId).toList();
    final newState = s.copyWith(frais: updatedFrais);
    state = AsyncData(newState.copyWith(truckState: _recalculateTruckState(newState)));
  }

  // Calculs automatiques
  TruckState _recalculateTruckState(TourState s) {
    final Map<FormatBouteille, int> vides = {};
    final Map<FormatBouteille, int> pleines = {};
    int cash = 0;

    // 1. Collectes (ajoute des vides au camion)
    for (final c in s.collectes) {
      c.quantitesVides.forEach((format, qty) {
        vides[format] = (vides[format] ?? 0) + qty;
      });
    }

    // 2. Recharge (vides quittent le camion, pleines entrent)
    if (s.recharge != null) {
      s.recharge!.videsRendus.forEach((format, qty) {
        vides[format] = (vides[format] ?? 0) - qty;
      });
      s.recharge!.pleinesRecues.forEach((format, qty) {
        pleines[format] = (pleines[format] ?? 0) + qty;
      });
    }

    // 3. Livraisons (pleines quittent le camion, cash entre)
    for (final l in s.livraisons) {
      for (final ligne in l.lignes) {
        pleines[ligne.format] = (pleines[ligne.format] ?? 0) - ligne.quantiteLivree;
      }
      cash += l.montantEncaisse;
    }

    return TruckState(
      videsEnCamion: vides,
      pleinesEnCamion: pleines,
      cashEncaisse: cash,
    );
  }
}

// Providers
final tourNotifierProvider = AsyncNotifierProvider.family.autoDispose<TourNotifier, TourState, String>(TourNotifier.new);

final truckStateProvider = Provider.family.autoDispose<TruckState, String>((ref, tourId) {
  return ref.watch(tourNotifierProvider(tourId)).value?.truckState ?? TruckState.empty();
});

final currentStepProvider = Provider.family.autoDispose<TourStatus, String>((ref, tourId) {
  return ref.watch(tourNotifierProvider(tourId)).value?.status ?? TourStatus.created;
});

final bilanProvider = Provider.family.autoDispose<BilanTour?, String>((ref, tourId) {
  return ref.watch(tourNotifierProvider(tourId)).value?.toBilan();
});

final enhancedBilanProvider = FutureProvider.family<BilanTour?, String>((ref, tourId) async {
  final basicBilan = ref.watch(bilanProvider(tourId));
  if (basicBilan == null) return null;

  final tourAsync = ref.watch(tourNotifierProvider(tourId));
  final tourState = tourAsync.value;
  if (tourState == null) return basicBilan;

  // 1. Récupérer l'entité Tour réelle pour avoir dates et enterpriseId
  final tourRepository = ref.read(tourRepositoryProvider);
  final tour = await tourRepository.getTourById(tourId);
  if (tour == null) return basicBilan;

  // Si le tour n'est pas clôturé, on s'arrête au bilan de base
  if (tour.status != domain.TourStatus.closed || tour.closureDate == null) {
    return basicBilan;
  }

  // 2. Trouver la date de début du PROCHAIN tour pour ce driver/entreprise
  final allTours = await tourRepository.getTours(tour.enterpriseId);
  final nextTour = allTours
      .where((t) => t.tourDate.isAfter(tour.closureDate!))
      .fold<domain.Tour?>(null, (prev, curr) => (prev == null || curr.tourDate.isBefore(prev.tourDate)) ? curr : prev);
  
  final startDateForSearch = tour.closureDate!;
  final endDateForSearch = nextTour?.tourDate ?? DateTime.now();

  // 3. Récupérer les fuites, opérations et versements POS dans l'intervalle [closureDate, nextStartDate]
  final leakRepo = ref.read(cylinderLeakRepositoryProvider(tour.enterpriseId));
  final treasuryRepo = ref.read(gazTreasuryRepositoryProvider);
  final posRemittanceRepo = ref.read(gazPOSRemittanceRepositoryProvider);

  final leaks = await leakRepo.getLeaks(tour.enterpriseId);
  final postClosureLeaks = leaks.where((l) => 
    l.reportedDate.isAfter(startDateForSearch) && 
    l.reportedDate.isBefore(endDateForSearch)
  ).length;

  final ops = await treasuryRepo.getOperations(tour.enterpriseId, from: startDateForSearch, to: endDateForSearch);
  final postClosureOpsCash = ops.fold(0.0, (sum, op) => sum + op.amount);

  // Versements POS validés
  final remittances = await posRemittanceRepo.getRemittances(
    tour.enterpriseId, 
    from: startDateForSearch, 
    to: endDateForSearch,
    status: RemittanceStatus.validated,
  );
  final postClosurePosCash = remittances.fold(0.0, (sum, r) => sum + r.amount);

  return basicBilan.copyWith(
    postClosureCash: postClosureOpsCash + postClosurePosCash,
    postClosureLeaks: postClosureLeaks,
  );
});

final formatsActifsProvider = Provider.autoDispose<List<FormatBouteille>>((ref) {
  final activeEnterprise = ref.watch(activeEnterpriseProvider).value;
  final enterpriseId = activeEnterprise?.id ?? 'default';
  
  final cylinders = ref.watch(cylindersProvider).value ?? [];
  final settings = ref.watch(gazSettingsProvider((enterpriseId: enterpriseId, moduleId: 'gaz'))).value;
  
  return cylinders.map((c) {
    final weight = c.weight;
    final wholesalePrice = settings?.wholesalePrices[weight]?.toInt() ?? c.sellPrice.toInt();
    
    return FormatBouteille(
      id: c.id,
      label: c.label,
      prixVente: c.sellPrice.toInt(),
      prixGros: wholesalePrice,
      prixAchat: c.buyPrice.toInt(),
    );
  }).toList();
});
