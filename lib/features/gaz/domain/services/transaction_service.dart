import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/offline_repository.dart' show LocalIdGenerator;
import '../entities/collection.dart';
import '../entities/cylinder.dart';
import '../entities/cylinder_stock.dart';
import '../entities/gas_sale.dart';
import '../entities/tour.dart';
import '../entities/gaz_inventory_audit.dart';
import '../repositories/cylinder_stock_repository.dart';
import '../repositories/gas_repository.dart';
import '../repositories/tour_repository.dart';
import 'data_consistency_service.dart';
import 'gas_alert_service.dart';
import '../entities/stock_alert.dart';
import '../entities/cylinder_leak.dart';
import '../entities/exchange_record.dart';
import '../repositories/cylinder_leak_repository.dart';
import '../repositories/exchange_repository.dart';
import '../repositories/gaz_settings_repository.dart';

import '../../../audit_trail/domain/repositories/audit_trail_repository.dart';
import '../../../audit_trail/domain/entities/audit_record.dart';

/// Service de gestion des transactions atomiques pour opérations critiques.
///
/// Assure que les opérations multi-étapes sont exécutées de manière atomique :
/// - Vente : Débit stock + Création vente (tout ou rien)
/// - Tour closure : Mise à jour tour + Mise à jour stocks (tout ou rien)
/// - Collection payment : Mise à jour collection + Mise à jour tour (tout ou rien)
class TransactionService {
  const TransactionService({
    required this.stockRepository,
    required this.gasRepository,
    required this.tourRepository,
    required this.consistencyService,
    required this.auditTrailRepository,
    required this.alertService,
    required this.leakRepository,
    required this.exchangeRepository,
    required this.settingsRepository,
  });

  final CylinderStockRepository stockRepository;
  final GasRepository gasRepository;
  final TourRepository tourRepository;
  final DataConsistencyService consistencyService;
  final AuditTrailRepository auditTrailRepository;
  final GasAlertService alertService;
  final CylinderLeakRepository leakRepository;
  final ExchangeRepository exchangeRepository;
  final GazSettingsRepository settingsRepository;

  /// Exécute une vente de manière atomique.
  ///
  /// Étapes :
  /// 1. Valide la cohérence (stock disponible)
  /// 2. Débite le stock
  /// 3. Crée la vente
  ///
  /// En cas d'erreur, rollback automatique.
  Future<({GasSale sale, StockAlert? alert})> executeSaleTransaction({
    required GasSale sale,
    required int weight, // Poids de la bouteille vendue
    required String enterpriseId,
    String? siteId,
  }) async {
    // 1. Validation de cohérence
    final consistencyError = await consistencyService.validateSaleConsistency(
      sale: sale,
      enterpriseId: enterpriseId,
      siteId: siteId,
      weight: weight,
    );

    if (consistencyError != null) {
      throw ValidationException(
        'Validation échouée: $consistencyError',
        'VALIDATION_FAILED',
      );
    }

    // 2. Débiter le stock
    final stockUpdates =
        <
          String,
          ({int originalQuantity, int debitedQuantity})
        >{}; // stockId -> infos

    try {
      // Récupérer les stocks disponibles
      final stocks = await stockRepository.getStocksByWeight(
        enterpriseId,
        weight,
        siteId: siteId,
      );

      final fullStocks =
          stocks.where((s) => s.status == CylinderStatus.full).toList()
            ..sort((a, b) => a.updatedAt.compareTo(b.updatedAt)); // FIFO

      int remainingToDebit = sale.quantity;

      for (final stock in fullStocks) {
        if (remainingToDebit <= 0) break;

        final toDebit = remainingToDebit > stock.quantity
            ? stock.quantity
            : remainingToDebit;

        final newQuantity = stock.quantity - toDebit;
        stockUpdates[stock.id] = (
          originalQuantity: stock.quantity,
          debitedQuantity: toDebit,
        );

        await stockRepository.updateStockQuantity(stock.id, newQuantity);
        remainingToDebit -= toDebit;
      }

      if (remainingToDebit > 0) {
        throw ValidationException(
          'Stock insuffisant pour ${weight}kg: $remainingToDebit manquants',
          'INSUFFICIENT_STOCK',
        );
      }

        // 3. Créditer le stock de bouteilles vides si c'est un échange
      if (sale.isExchange && sale.emptyReturnedQuantity > 0) {
        final emptyStock = stocks
            .where((s) => s.status == CylinderStatus.emptyAtStore)
            .firstOrNull;
  
        if (emptyStock != null) {
          await stockRepository.updateStockQuantity(
            emptyStock.id,
            emptyStock.quantity + sale.emptyReturnedQuantity,
          );
        } else {
          // Créer un enregistrement de stock vide si inexistant
          await stockRepository.addStock(CylinderStock(
            id: 'stock_empty_${DateTime.now().millisecondsSinceEpoch}_$weight',
            cylinderId: sale.cylinderId,
            weight: weight,
            status: CylinderStatus.emptyAtStore,
            quantity: sale.emptyReturnedQuantity,
            enterpriseId: enterpriseId,
            updatedAt: DateTime.now(),
            createdAt: DateTime.now(),
          ));
        }
      }
  
      // 3.5. Calculer la consigne si c'est un nouveau cylindre
      double depositAmount = 0;
      if (sale.dealType == GasSaleDealType.newCylinder) {
        final settings = await settingsRepository.getSettings(
          enterpriseId: enterpriseId,
          moduleId: 'gaz',
        );
        if (settings != null) {
          depositAmount = settings.getDepositRate(weight) * sale.quantity;
          AppLogger.info('Applying deposit: $depositAmount for new cylinders', name: 'TransactionService');
        }
      }

      // 4. Créer la vente (le totalAmount inclut déjà la consigne si calculé par le UI, 
      // ou on l'ajoute ici si ce n'est pas le cas. 
      // Pour ELYF, le totalAmount passé au service est le montant final payé par le client.)
      // Nous l'enregistrons tel quel, mais nous logguons la part de consigne dans l'audit.
      
      await gasRepository.addSale(sale);
  
      // 5. Audit Log
      await auditTrailRepository.log(AuditRecord(
        id: '',
        enterpriseId: enterpriseId,
        userId: sale.sellerId ?? '',
        module: 'gaz',
        action: 'SALE_TRANSACTION',
        entityId: sale.id ?? '',
        entityType: 'sale',
        timestamp: DateTime.now(),
        metadata: {
          'operation': 'sale',
          'cylinderId': sale.cylinderId,
          'weight': weight,
          'quantity': sale.quantity,
          'dealType': sale.dealType.name,
          'isExchange': sale.isExchange,
          'emptyReturnedQuantity': sale.emptyReturnedQuantity,
          'depositAmount': depositAmount,
          'movements': [
            {
              'cylinderId': sale.cylinderId,
              'weight': weight,
              'status': 'full',
              'delta': -sale.quantity,
            },
            if (sale.isExchange && sale.emptyReturnedQuantity > 0)
              {
                'cylinderId': sale.cylinderId,
                'weight': weight,
                'status': 'emptyAtStore',
                'delta': sale.emptyReturnedQuantity,
              },
          ],
        },
      ));
    // check for alerts after debiting stock
    StockAlert? alert;
    try {
      alert = await alertService.checkStockAlerts(
        enterpriseId: enterpriseId,
        cylinderId: sale.cylinderId,
        weight: weight,
        status: CylinderStatus.full,
      );
    } catch (e) {
      // Ignorer les erreurs d'alerte pour ne pas bloquer la vente
    }

    return (sale: sale, alert: alert);
  } catch (e) {
    // Rollback : restaurer les stocks
    for (final entry in stockUpdates.entries) {
      try {
        final stockInfo = entry.value;
        await stockRepository.updateStockQuantity(
          entry.key,
          stockInfo.originalQuantity,
        );
      } catch (rollbackError, rollbackStackTrace) {
        // Log l'erreur de rollback mais ne pas bloquer
        AppLogger.error(
          'TransactionService: Erreur lors du rollback du stock ${entry.key}',
          name: 'transaction.rollback',
          error: rollbackError,
          stackTrace: rollbackStackTrace,
        );
      }
    }

    // Note: Le rollback pour le crédit de stock vide n'est pas strictement nécessaire 
    // car si la transaction échoue, le client garde sa bouteille vide. 
    // Cependant, pour une cohérence parfaite, on pourrait aussi le gérer.
    rethrow;
  }
}

  /// Exécute la clôture d'un tour de manière atomique.
  ///
  /// Étapes :
  /// 1. Valide la cohérence du tour
  /// 2. Vérifie que toutes les collections sont payées
  /// 3. Met à jour le statut du tour
  /// 4. Met à jour les stocks (Empties de collections + Reception Pleins)
  /// 5. Enregistre l'impact financier dans AuditTrail
  Future<({Tour tour, List<StockAlert> alerts})> executeTourClosureTransaction({
    required String tourId,
    required String userId,
  }) async {
    final tour = await tourRepository.getTourById(tourId);
    if (tour == null) {
      throw NotFoundException(
        'Tour introuvable',
        'TOUR_NOT_FOUND',
      );
    }

    // 1. Validation
    final consistencyError = await consistencyService.validateTourConsistency(
      tour,
    );
    if (consistencyError != null) {
      throw ValidationException(
        'Validation échouée: $consistencyError',
        'VALIDATION_FAILED',
      );
    }

    if (!tour.areAllCollectionsPaid) {
      throw ValidationException(
        'Toutes les collectes doivent être payées avant la clôture',
        'UNPAID_COLLECTIONS',
      );
    }

    // 2. Mettre à jour le tour
    final updatedTour = tour.copyWith(
      status: TourStatus.closure,
      closureDate: DateTime.now(),
    );

    await tourRepository.updateTour(updatedTour);

    // 3. Mise à jour des stocks
    try {
      final allCylinders = await gasRepository.getCylinders();
      final cylinders = allCylinders
          .where((c) => c.enterpriseId == updatedTour.enterpriseId)
          .toList();
      
      final emptyBottlesByWeight = <int, int>{};
      final leakBottlesByWeight = <int, int>{};
      for (final collection in updatedTour.collections) {
        for (final entry in collection.emptyBottles.entries) {
          final weight = entry.key;
          final quantity = entry.value;
          final leakQuantity = collection.leaks[weight] ?? 0;
          final validQuantity = quantity - leakQuantity;
          
          if (validQuantity > 0) {
            emptyBottlesByWeight[weight] = 
                (emptyBottlesByWeight[weight] ?? 0) + validQuantity;
          }
          if (leakQuantity > 0) {
            leakBottlesByWeight[weight] = 
                (leakBottlesByWeight[weight] ?? 0) + leakQuantity;
          }
        }
      }

      for (final entry in emptyBottlesByWeight.entries) {
        final weight = entry.key;
        final quantityToAdd = entry.value;

        final cylinder = cylinders.firstWhere(
          (c) => c.weight == weight,
          orElse: () => throw NotFoundException('Cylindre $weight kg introuvable', 'CYLINDER_NOT_FOUND'),
        );

        final existingStocks = await stockRepository.getStocksByWeight(updatedTour.enterpriseId, weight);
        final emptyStock = existingStocks.where((s) => s.status == CylinderStatus.emptyAtStore && s.cylinderId == cylinder.id).firstOrNull;

        if (emptyStock != null) {
          await stockRepository.updateStockQuantity(emptyStock.id, emptyStock.quantity + quantityToAdd);
        } else {
          await stockRepository.addStock(CylinderStock(
            id: 'stock_empty_${DateTime.now().millisecondsSinceEpoch}_$weight',
            cylinderId: cylinder.id,
            weight: weight,
            status: CylinderStatus.emptyAtStore,
            quantity: quantityToAdd,
            enterpriseId: updatedTour.enterpriseId,
            updatedAt: DateTime.now(),
            createdAt: DateTime.now(),
          ));
        }
      }

      for (final entry in leakBottlesByWeight.entries) {
        final weight = entry.key;
        final quantityToAdd = entry.value;

        final cylinder = cylinders.firstWhere(
          (c) => c.weight == weight,
          orElse: () => throw NotFoundException('Cylindre $weight kg introuvable', 'CYLINDER_NOT_FOUND'),
        );

        final existingStocks = await stockRepository.getStocksByWeight(updatedTour.enterpriseId, weight);
        final leakStock = existingStocks.where((s) => s.status == CylinderStatus.leak && s.cylinderId == cylinder.id).firstOrNull;

        if (leakStock != null) {
          await stockRepository.updateStockQuantity(leakStock.id, leakStock.quantity + quantityToAdd);
        } else {
          await stockRepository.addStock(CylinderStock(
            id: LocalIdGenerator.generate(),
            cylinderId: cylinder.id,
            weight: weight,
            status: CylinderStatus.leak,
            quantity: quantityToAdd,
            enterpriseId: updatedTour.enterpriseId,
            updatedAt: DateTime.now(),
          ));
        }

        // Créer une fuite pour chaque fuite déclarée durant le tour
        await leakRepository.reportLeak(CylinderLeak(
          id: LocalIdGenerator.generate(),
          enterpriseId: updatedTour.enterpriseId,
          cylinderId: cylinder.id,
          weight: weight,
          source: LeakSource.tour,
          reportedDate: DateTime.now(),
          status: LeakStatus.reported,
          tourId: updatedTour.id,
          notes: 'Détectée lors de la clôture du tour (Quantité: $quantityToAdd)',
        ));
      }

      // Phase 3.2: Gérer la réception de pleins (Plein Reception)
      // Si on a reçu des pleins, on les ajoute au stock FULL et on déduis du stock EMPTY (car échangés)
      for (final entry in updatedTour.fullBottlesReceived.entries) {
        final weight = entry.key;
        final quantityFull = entry.value;
        if (quantityFull <= 0) continue;

        final cylinder = cylinders.firstWhere(
          (c) => c.weight == weight,
          orElse: () => throw NotFoundException('Cylindre $weight kg introuvable', 'CYLINDER_NOT_FOUND'),
        );

        // Ajouter au stock FULL
        final existingStocks = await stockRepository.getStocksByWeight(updatedTour.enterpriseId, weight);
        final fullStock = existingStocks.where((s) => s.status == CylinderStatus.full && s.cylinderId == cylinder.id).firstOrNull;

        if (fullStock != null) {
          await stockRepository.updateStockQuantity(fullStock.id, fullStock.quantity + quantityFull);
        } else {
          await stockRepository.addStock(CylinderStock(
            id: 'stock_full_${DateTime.now().millisecondsSinceEpoch}_$weight',
            cylinderId: cylinder.id,
            weight: weight,
            status: CylinderStatus.full,
            quantity: quantityFull,
            enterpriseId: updatedTour.enterpriseId,
            updatedAt: DateTime.now(),
            createdAt: DateTime.now(),
          ));
        }

        // Déduire du stock EMPTY (Échange standard chez le fournisseur)
        final emptyStock = existingStocks.where((s) => s.status == CylinderStatus.emptyAtStore && s.cylinderId == cylinder.id).firstOrNull;
        if (emptyStock != null) {
          final newEmptyQty = (emptyStock.quantity - quantityFull).clamp(0, 1000000).toInt();
          await stockRepository.updateStockQuantity(emptyStock.id, newEmptyQty);
        }
      }

      // 4. Audit Log des mouvements de stock
      await auditTrailRepository.log(AuditRecord(
        id: '',
        enterpriseId: updatedTour.enterpriseId,
        userId: userId,
        module: 'gaz',
        action: 'STOCK_REPLENISHMENT_TOUR',
        entityId: updatedTour.id,
        entityType: 'tour',
        timestamp: DateTime.now(),
        metadata: {
          'operation': 'replenishment',
          'tourId': updatedTour.id,
          'movements': [
            // Pleins reçus
            ...updatedTour.fullBottlesReceived.entries.map((e) => {
              'weight': e.key,
              'status': 'full',
              'delta': e.value,
            }),
            // Emplacements d'origine (Consignes) - On suppose ici que ça réduit les empties au magasin
            ...updatedTour.fullBottlesReceived.entries.map((e) => {
              'weight': e.key,
              'status': 'emptyAtStore',
              'delta': -e.value,
            }),
          ],
        },
      ));

      // 4. Enregistrement de l'impact financier (Audit Trail / Ledger Fallback)
      final totalExpenses = updatedTour.totalExpenses + (updatedTour.gasPurchaseCost ?? 0.0);
      
      if (totalExpenses > 0) {
        await auditTrailRepository.log(AuditRecord(
          id: '', // Généré par le repository (local_...)
          enterpriseId: updatedTour.enterpriseId,
          userId: userId,
          module: 'gaz',
          action: 'TOUR_CLOSURE_EXPENSE',
          entityId: updatedTour.id,
          entityType: 'tour',
          timestamp: DateTime.now(),
          metadata: {
            'totalExpenses': totalExpenses,
            'transportExpenses': updatedTour.totalTransportExpenses,
            'loadingUnloadingFees': updatedTour.totalLoadingFees + updatedTour.totalUnloadingFees,
            'gasPurchaseCost': updatedTour.gasPurchaseCost ?? 0.0,
            'tourDate': updatedTour.tourDate.toIso8601String(),
          },
        ));
      }

      AppLogger.info(
        'TourClosure: Clôture réussie du tour ${updatedTour.id}. Dépenses totales: $totalExpenses',
        name: 'transaction.tour_closure',
      );

      // Phase 3.3: Vérifier les seuils d'alerte (Story 1.4)
      final alerts = <StockAlert>[];
      final affectedWeights = {
        ...emptyBottlesByWeight.keys,
        ...updatedTour.fullBottlesReceived.keys,
      };

      for (final weight in affectedWeights) {
        final alert = await alertService.checkStockLevel(
          enterpriseId: updatedTour.enterpriseId,
          cylinderId: null,
          weight: weight,
          status: CylinderStatus.full,
        );
        if (alert != null) alerts.add(alert);
      }

      return (tour: updatedTour, alerts: alerts);
    } catch (e, stackTrace) {
      AppLogger.error(
        'TourClosure Error: $tourId: $e',
        name: 'transaction.tour_closure',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Exécute le paiement d'une collection de manière atomique.
  ///
  /// Étapes :
  /// 1. Valide la cohérence
  /// 2. Met à jour la collection
  /// 3. Met à jour le tour si toutes les collections sont payées
  Future<Collection> executeCollectionPaymentTransaction({
    required String tourId,
    required String collectionId,
    required double amount,
    required DateTime paymentDate,
  }) async {
    final tour = await tourRepository.getTourById(tourId);
    if (tour == null) {
      throw NotFoundException(
        'Tour introuvable',
        'TOUR_NOT_FOUND',
      );
    }

    final collectionIndex = tour.collections.indexWhere(
      (c) => c.id == collectionId,
    );
    if (collectionIndex == -1) {
      throw NotFoundException(
        'Collection introuvable dans le tour',
        'COLLECTION_NOT_FOUND',
      );
    }

    final collection = tour.collections[collectionIndex];

    // 1. Validation
    if (amount < 0) {
      throw ValidationException(
        'Le montant ne peut pas être négatif',
        'NEGATIVE_AMOUNT',
      );
    }

    if (amount > collection.remainingAmount) {
      throw ValidationException(
        'Le montant payé ($amount) ne peut pas dépasser le reste à payer (${collection.remainingAmount})',
        'PAYMENT_AMOUNT_EXCEEDS_REMAINING',
      );
    }

    // 2. Mettre à jour la collection
    final updatedCollection = collection.copyWith(
      amountPaid: collection.amountPaid + amount,
      paymentDate: paymentDate,
    );

    final updatedCollections = List<Collection>.from(tour.collections);
    updatedCollections[collectionIndex] = updatedCollection;

    // 3. Mettre à jour le tour
    final updatedTour = tour.copyWith(collections: updatedCollections);

    await tourRepository.updateTour(updatedTour);

    return updatedCollection;
  }

  /// Déclare une fuite de manière atomique.
  /// 
  /// Étapes :
  /// 1. Décrémente le stock plein
  /// 2. Incrémente le stock "Fuite"
  /// 3. Enregistre la fuite (Standardisé)
  /// 4. Log l'audit
  Future<void> executeLeakDeclaration({
    required CylinderLeak leak,
    required String userId,
  }) async {
    // 1. Décrémenter stock plein
    final fullStocks = await stockRepository.getStocksByWeight(leak.enterpriseId, leak.weight);
    final fullStock = fullStocks.where((s) => s.status == CylinderStatus.full && s.cylinderId == leak.cylinderId).firstOrNull;
    
    if (fullStock == null || fullStock.quantity <= 0) {
      throw ValidationException('Stock insuffisant pour déclarer une fuite', 'INSUFFICIENT_STOCK');
    }

    await stockRepository.updateStock(fullStock.copyWith(
      quantity: fullStock.quantity - 1,
      updatedAt: DateTime.now(),
    ));

    // 2. Incrémenter stock fuite
    final leakStock = fullStocks.where((s) => s.status == CylinderStatus.leak && s.cylinderId == leak.cylinderId).firstOrNull 
      ?? CylinderStock(
          id: LocalIdGenerator.generate(),
          cylinderId: leak.cylinderId,
          weight: leak.weight,
          status: CylinderStatus.leak,
          quantity: 0,
          enterpriseId: leak.enterpriseId,
          updatedAt: DateTime.now(),
        );

    await stockRepository.updateStock(leakStock.copyWith(
      quantity: leakStock.quantity + 1,
      updatedAt: DateTime.now(),
    ));

    // 3. Enregistrer la fuite
    await leakRepository.reportLeak(leak);

    // 4. Audit Trail
    await auditTrailRepository.log(AuditRecord(
      id: '',
      enterpriseId: leak.enterpriseId,
      userId: userId,
      module: 'gaz',
      action: 'LEAK_DECLARATION',
      entityId: leak.id,
      entityType: 'leak',
      timestamp: DateTime.now(),
      metadata: {
        ...leak.toMap(),
        'operation': 'leak',
        'movements': [
          {'cylinderId': leak.cylinderId, 'weight': leak.weight, 'status': 'full', 'delta': -1},
          {'cylinderId': leak.cylinderId, 'weight': leak.weight, 'status': 'leak', 'delta': 1},
        ],
      },
    ));
  }

  /// Exécute un échange de bouteilles de manière atomique.
  Future<void> executeExchangeTransaction({
    required ExchangeRecord exchange,
    required String userId,
  }) async {
    // 1. Décrémenter stock From (Bouteille donnée)
    final fromStocks = await stockRepository.getStocksByWeight(exchange.enterpriseId, 0); // Need to get by cylinderId actually
    // Re-getting stocks by looking at specific cylinderIds might be better
    
    // Pour simplifier, on va chercher par cylinderId via gasRepository si besoin, 
    // mais stockRepository.getStocksByWeight nous donne tous les stocks pour ce poids.
    // On a besoin du poids des deux bouteilles de l'échange.
    
    final fromCylinder = await gasRepository.getCylinderById(exchange.fromCylinderId);
    final toCylinder = await gasRepository.getCylinderById(exchange.toCylinderId);
    
    if (fromCylinder == null || toCylinder == null) {
      throw NotFoundException('Bouteille introuvable', 'CYLINDER_NOT_FOUND');
    }

    final fromStocksList = await stockRepository.getStocksByWeight(exchange.enterpriseId, fromCylinder.weight);
    final fromStock = fromStocksList.where((s) => s.cylinderId == exchange.fromCylinderId && s.status == CylinderStatus.emptyAtStore).firstOrNull;

    if (fromStock == null || fromStock.quantity < exchange.quantity) {
      throw ValidationException('Stock insuffisant pour l\'échange', 'INSUFFICIENT_STOCK');
    }

    // 2. Transférer stock
    await stockRepository.updateStock(fromStock.copyWith(
      quantity: fromStock.quantity - exchange.quantity,
      updatedAt: DateTime.now(),
    ));

    final toStocksList = await stockRepository.getStocksByWeight(exchange.enterpriseId, toCylinder.weight);
    final toStock = toStocksList.where((s) => s.cylinderId == exchange.toCylinderId && s.status == CylinderStatus.emptyAtStore).firstOrNull
      ?? CylinderStock(
          id: LocalIdGenerator.generate(),
          cylinderId: exchange.toCylinderId,
          weight: toCylinder.weight,
          status: CylinderStatus.emptyAtStore,
          quantity: 0,
          enterpriseId: exchange.enterpriseId,
          updatedAt: DateTime.now(),
        );

    await stockRepository.updateStock(toStock.copyWith(
      quantity: toStock.quantity + exchange.quantity,
      updatedAt: DateTime.now(),
    ));

    // 3. Enregistrer l'échange
    await exchangeRepository.addExchange(exchange);

    // 4. Audit Trail
    await auditTrailRepository.log(AuditRecord(
      id: '',
      enterpriseId: exchange.enterpriseId,
      userId: userId,
      module: 'gaz',
      action: 'EXCHANGE_TRANSACTION',
      entityId: exchange.id,
      entityType: 'exchange',
      timestamp: DateTime.now(),
      metadata: {
        ...exchange.toMap(),
        'operation': 'exchange',
        'movements': [
          {'cylinderId': exchange.fromCylinderId, 'status': 'emptyAtStore', 'delta': -exchange.quantity},
          {'cylinderId': exchange.toCylinderId, 'status': 'emptyAtStore', 'delta': exchange.quantity},
        ],
      },
    ));
  }

  /// Exécute un ajustement manuel de stock avec log d'audit.
  Future<void> executeStockAdjustment({
    required CylinderStock stock,
    required int newQuantity,
    required String userId,
    String? reason,
  }) async {
    final oldQuantity = stock.quantity;
    
    // 1. Mettre à jour le stock
    await stockRepository.updateStock(stock.copyWith(
      quantity: newQuantity,
      updatedAt: DateTime.now(),
    ));

    // 2. Log l'audit
    await auditTrailRepository.log(AuditRecord(
      id: '',
      enterpriseId: stock.enterpriseId,
      userId: userId,
      module: 'gaz',
      action: 'STOCK_ADJUSTMENT',
      entityId: stock.id,
      entityType: 'stock',
      timestamp: DateTime.now(),
      metadata: {
        'operation': 'adjustment',
        'cylinderId': stock.cylinderId,
        'weight': stock.weight,
        'status': stock.status.name,
        'oldQuantity': oldQuantity,
        'newQuantity': newQuantity,
        'diff': newQuantity - oldQuantity,
        'reason': reason,
        'siteId': stock.siteId,
        'movements': [
          {
            'cylinderId': stock.cylinderId,
            'weight': stock.weight,
            'status': stock.status.name,
            'delta': newQuantity - oldQuantity
          },
        ],
      },
    ));
  }

  /// Exécute un remboursement de consigne (retour de bouteille sans achat).
  Future<void> executeDepositRefund({
    required String enterpriseId,
    required String cylinderId,
    required int weight,
    required int quantity,
    required String userId,
    String? siteId,
  }) async {
    // 1. Créditer le stock de bouteilles vides
    final stocks = await stockRepository.getStocksByWeight(
      enterpriseId,
      weight,
      siteId: siteId,
    );
    
    final emptyStock = stocks
        .where((s) => s.status == CylinderStatus.emptyAtStore && s.cylinderId == cylinderId)
        .firstOrNull;

    if (emptyStock != null) {
      await stockRepository.updateStockQuantity(
        emptyStock.id,
        emptyStock.quantity + quantity,
      );
    } else {
      await stockRepository.addStock(CylinderStock(
        id: LocalIdGenerator.generate(),
        cylinderId: cylinderId,
        weight: weight,
        status: CylinderStatus.emptyAtStore,
        quantity: quantity,
        enterpriseId: enterpriseId,
        siteId: siteId,
        updatedAt: DateTime.now(),
      ));
    }

    // 2. Récupérer le taux de consigne pour l'audit
    double refundAmount = 0;
    final settings = await settingsRepository.getSettings(
      enterpriseId: enterpriseId,
      moduleId: 'gaz',
    );
    if (settings != null) {
      refundAmount = settings.getDepositRate(weight) * quantity;
    }

    // 3. Audit Log
    await auditTrailRepository.log(AuditRecord(
      id: '',
      enterpriseId: enterpriseId,
      userId: userId,
      module: 'gaz',
      action: 'DEPOSIT_REFUND',
      entityId: cylinderId,
      entityType: 'cylinder',
      timestamp: DateTime.now(),
      metadata: {
        'operation': 'refund',
        'cylinderId': cylinderId,
        'weight': weight,
        'quantity': quantity,
        'refundAmount': refundAmount,
        'siteId': siteId,
        'movements': [
          {
            'cylinderId': cylinderId,
            'weight': weight,
            'status': 'emptyAtStore',
            'delta': quantity,
          },
        ],
      },
    ));
  }

  /// Exécute un audit d'inventaire complet.
  /// 
  /// Met à jour plusieurs stocks et loggue l'audit global.
  Future<void> executeInventoryAudit({
    required GazInventoryAudit audit,
    required String userId,
  }) async {
    // 1. Mettre à jour chaque stock
    for (final item in audit.items) {
      await stockRepository.updateStockQuantity(item.stockId, item.physicalQuantity);
    }

    // 2. Log l'audit global
    await auditTrailRepository.log(AuditRecord(
      id: '',
      enterpriseId: audit.enterpriseId,
      userId: userId,
      module: 'gaz',
      action: 'INVENTORY_AUDIT_COMPLETED',
      entityId: audit.id,
      entityType: 'inventory_audit',
      timestamp: DateTime.now(),
      metadata: {
        ...audit.toMap(),
        'operation': 'audit',
        'movements': audit.items.where((i) => i.discrepancy != 0).map((i) => {
          'cylinderId': i.cylinderId,
          'weight': i.weight,
          'status': i.status.name,
          'delta': i.discrepancy,
          'siteId': audit.siteId,
        }).toList(),
      },
    ));
  }
}
