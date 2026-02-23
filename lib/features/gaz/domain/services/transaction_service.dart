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
import '../repositories/inventory_audit_repository.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';
import '../repositories/session_repository.dart';
import '../repositories/treasury_repository.dart';
import 'package:elyf_groupe_app/shared/domain/entities/treasury_operation.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';

import '../../../audit_trail/domain/repositories/audit_trail_repository.dart';
import '../../../audit_trail/domain/entities/audit_record.dart';
// For PhoneUtils if needed, but assuming internal logic

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
    required this.inventoryAuditRepository,
    required this.expenseRepository,
    required this.sessionRepository,
    required this.treasuryRepository,
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
  final GazInventoryAuditRepository inventoryAuditRepository;
  final GazExpenseRepository expenseRepository;
  final GazSessionRepository sessionRepository;
  final GazTreasuryRepository treasuryRepository;

  /// Exécute un approvisionnement (Réception Plein) de manière atomique.
  /// 
  /// Étapes :
  /// 1. Incrémente le stock PLEIN
  /// 2. Décrémente le stock VIDE (Échange standard)
  /// 3. Enregistre une dépense (Coût d'achat)
  /// 4. Log l'audit
  Future<({GazExpense expense, List<StockAlert> alerts})> executeReplenishmentTransaction({
    required String enterpriseId,
    required String cylinderId,
    required int weight,
    required int quantity,
    required double unitCost,
    required String userId,
    int leakySwappedQuantity = 0,
    String? siteId,
    String? supplierName,
  }) async {
    final totalAmount = unitCost * quantity;
    final totalFullToAdd = quantity + leakySwappedQuantity;
    
    // 1. Mise à jour des stocks
    final existingStocks = await stockRepository.getStocksByWeight(enterpriseId, weight, siteId: siteId);
    
    // Ajouter au stock FULL (Achat + Échange fuite)
    final fullStock = existingStocks.where((s) => s.status == CylinderStatus.full && s.cylinderId == cylinderId).firstOrNull;
    if (fullStock != null) {
      await stockRepository.updateStockQuantity(fullStock.id, fullStock.quantity + totalFullToAdd);
    } else {
      await stockRepository.addStock(CylinderStock(
        id: LocalIdGenerator.generate(),
        cylinderId: cylinderId,
        weight: weight,
        status: CylinderStatus.full,
        quantity: totalFullToAdd,
        enterpriseId: enterpriseId,
        siteId: siteId,
        updatedAt: DateTime.now(),
      ));
    }

    // Déduire du stock VIDE (Échange standard chez le fournisseur pour la quantité ACHETÉE)
    final emptyStock = existingStocks.where((s) => s.status == CylinderStatus.emptyAtStore && s.cylinderId == cylinderId).firstOrNull;
    if (emptyStock != null) {
      final newEmptyQty = (emptyStock.quantity - quantity).clamp(0, 1000000).toInt();
      await stockRepository.updateStockQuantity(emptyStock.id, newEmptyQty);
    }

    // Déduire du stock FUITE (Échange gratuit chez le fournisseur pour la quantité LEAK)
    if (leakySwappedQuantity > 0) {
      final leakStock = existingStocks.where((s) => s.status == CylinderStatus.leak && s.cylinderId == cylinderId).firstOrNull;
      if (leakStock != null) {
        final newLeakQty = (leakStock.quantity - leakySwappedQuantity).clamp(0, 1000000).toInt();
        await stockRepository.updateStockQuantity(leakStock.id, newLeakQty);
      }
    }

    // 2. Créer la dépense (Basée uniquement sur quantity, pas leakySwappedQuantity)
    final expense = GazExpense(
      id: LocalIdGenerator.generate(),
      enterpriseId: enterpriseId,
      category: ExpenseCategory.stockReplenishment,
      amount: totalAmount,
      description: 'Réapprovisionnement Gaz ${weight}kg x $quantity${leakySwappedQuantity > 0 ? " (+ $leakySwappedQuantity fuites)" : ""} (${supplierName ?? "Fournisseur"})',
      date: DateTime.now(),
      isFixed: false,
      notes: 'Coût unitaire: $unitCost',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await expenseRepository.addExpense(expense);
    
    // 2.5. Enregistrement Trésorerie (Epic 7)
    await treasuryRepository.saveOperation(TreasuryOperation(
      id: LocalIdGenerator.generate(),
      enterpriseId: enterpriseId,
      userId: userId,
      amount: totalAmount.toInt(),
      type: TreasuryOperationType.removal,
      fromAccount: PaymentMethod.cash, // Les dépenses sortent généralement du cash
      date: DateTime.now(),
      reason: expense.description,
      referenceEntityId: expense.id,
      referenceEntityType: 'gaz_expense',
      createdAt: DateTime.now(),
    ));

    // 3. Audit Trail
    await auditTrailRepository.log(AuditRecord(
      id: '',
      enterpriseId: enterpriseId,
      userId: userId,
      module: 'gaz',
      action: 'STOCK_REPLENISHMENT',
      entityId: expense.id,
      entityType: 'expense',
      timestamp: DateTime.now(),
      metadata: {
        'operation': 'replenishment',
        'cylinderId': cylinderId,
        'weight': weight,
        'quantity': quantity,
        'leakySwappedQuantity': leakySwappedQuantity,
        'unitCost': unitCost,
        'totalAmount': totalAmount,
        'supplierName': supplierName,
        'movements': [
          {'cylinderId': cylinderId, 'weight': weight, 'status': 'full', 'delta': totalFullToAdd},
          {'cylinderId': cylinderId, 'weight': weight, 'status': 'emptyAtStore', 'delta': -quantity},
          if (leakySwappedQuantity > 0)
            {'cylinderId': cylinderId, 'weight': weight, 'status': 'leak', 'delta': -leakySwappedQuantity},
        ],
      },
    ));

    // 4. Vérifier les alertes
    final alerts = <StockAlert>[];
    final alert = await alertService.checkStockLevel(
      enterpriseId: enterpriseId,
      cylinderId: cylinderId,
      weight: weight,
      status: CylinderStatus.full,
    );
    if (alert != null) alerts.add(alert);

    return (expense: expense, alerts: alerts);
  }

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
    // 0. Vérifier si une session est ouverte (Obligatoire pour vendre)
    final activeSession = await sessionRepository.getActiveSession(enterpriseId);
    if (activeSession == null) {
      throw ValidationException(
        'Aucune session active. Veuillez ouvrir une session avant de vendre.',
        'NO_ACTIVE_SESSION',
      );
    }

    // Lier la vente à la session active
    final saleWithSession = sale.copyWith(sessionId: activeSession.id);

    // 1. Validation de cohérence
    final consistencyError = await consistencyService.validateSaleConsistency(
      sale: saleWithSession,
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

      int remainingToDebit = saleWithSession.quantity;

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

        // 3. Créditer le stock de bouteilles vides si c'est un échange ou un retour
      if ((saleWithSession.isExchange || saleWithSession.dealType == GasSaleDealType.returnCylinder) && saleWithSession.emptyReturnedQuantity > 0) {
        final emptyStock = stocks
            .where((s) => s.status == CylinderStatus.emptyAtStore)
            .firstOrNull;
  
        if (emptyStock != null) {
          await stockRepository.updateStockQuantity(
            emptyStock.id,
            emptyStock.quantity + saleWithSession.emptyReturnedQuantity,
          );
        } else {
          // Créer un enregistrement de stock vide si inexistant
          await stockRepository.addStock(CylinderStock(
            id: 'stock_empty_${DateTime.now().millisecondsSinceEpoch}_$weight',
            cylinderId: saleWithSession.cylinderId,
            weight: weight,
            status: CylinderStatus.emptyAtStore,
            quantity: saleWithSession.emptyReturnedQuantity,
            enterpriseId: enterpriseId,
            updatedAt: DateTime.now(),
            createdAt: DateTime.now(),
          ));
        }
      }
  
      // 3.5. Calculer la consigne si c'est un nouveau cylindre
      double depositAmount = 0;
      if (saleWithSession.dealType == GasSaleDealType.newCylinder) {
        final settings = await settingsRepository.getSettings(
          enterpriseId: enterpriseId,
          moduleId: 'gaz',
        );
        if (settings != null) {
          depositAmount = settings.getDepositRate(weight) * saleWithSession.quantity;
          AppLogger.info('Applying deposit: $depositAmount for new cylinders', name: 'TransactionService');
        }
      }

      // 4. Créer la vente (le totalAmount inclut déjà la consigne si calculé par le UI, 
      // ou on l'ajoute ici si ce n'est pas le cas. 
      // Pour ELYF, le totalAmount passé au service est le montant final payé par le client.)
      // Nous l'enregistrons tel quel, mais nous logguons la part de consigne dans l'audit.
      
      await gasRepository.addSale(saleWithSession);
  
      // 4.5. Enregistrement Trésorerie (Epic 7)
      await treasuryRepository.saveOperation(TreasuryOperation(
        id: LocalIdGenerator.generate(),
        enterpriseId: enterpriseId,
        userId: saleWithSession.sellerId ?? '',
        amount: saleWithSession.totalAmount.toInt(),
        type: TreasuryOperationType.supply,
        toAccount: saleWithSession.paymentMethod,
        date: saleWithSession.saleDate,
        reason: 'Vente Gaz ${weight}kg x ${saleWithSession.quantity}',
        referenceEntityId: saleWithSession.id,
        referenceEntityType: 'gas_sale',
        createdAt: DateTime.now(),
      ));
  
      // 5. Audit Log
      await auditTrailRepository.log(AuditRecord(
        id: '',
        enterpriseId: enterpriseId,
        userId: saleWithSession.sellerId ?? '',
        module: 'gaz',
        action: 'SALE_TRANSACTION',
        entityId: saleWithSession.id,
        entityType: 'sale',
        timestamp: DateTime.now(),
        metadata: {
          'operation': 'sale',
          'cylinderId': saleWithSession.cylinderId,
          'weight': weight,
          'quantity': saleWithSession.quantity,
          'dealType': saleWithSession.dealType.name,
          'isExchange': saleWithSession.isExchange,
          'emptyReturnedQuantity': saleWithSession.emptyReturnedQuantity,
          'depositAmount': depositAmount,
          'sessionId': activeSession.id,
          'movements': [
            {
              'cylinderId': saleWithSession.cylinderId,
              'weight': weight,
              'status': 'full',
              'delta': -saleWithSession.quantity,
            },
            if ((saleWithSession.isExchange || saleWithSession.dealType == GasSaleDealType.returnCylinder) && saleWithSession.emptyReturnedQuantity > 0)
              {
                'cylinderId': saleWithSession.cylinderId,
                'weight': weight,
                'status': 'emptyAtStore',
                'delta': saleWithSession.emptyReturnedQuantity,
              },
          ],
        },
      ));
    // check for alerts after debiting stock
    StockAlert? alert;
    try {
      alert = await alertService.checkStockAlerts(
        enterpriseId: enterpriseId,
        cylinderId: saleWithSession.cylinderId,
        weight: weight,
        status: CylinderStatus.full,
      );
    } catch (e) {
      // Ignorer les erreurs d'alerte pour ne pas bloquer la vente
    }

    return (sale: saleWithSession, alert: alert);
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

  /// Exécute la clôture d'un tour d'approvisionnement fournisseur.
  ///
  /// Étapes :
  /// 1. Valide la cohérence du tour
  /// 2. Met à jour le statut du tour
  /// 3. Déduit les vides chargées (emptyBottlesLoaded) du stock société
  /// 4. Ajoute les pleines reçues (fullBottlesReceived) au stock société
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
    if (tour.fullBottlesReceived.isEmpty) {
      throw ValidationException(
        'Saisissez les bouteilles pleines reçues avant la clôture',
        'NO_FULLS_RECEIVED',
      );
    }

    // 2. Mettre à jour le tour
    final updatedTour = tour.copyWith(
      status: TourStatus.closed,
      closureDate: DateTime.now(),
    );

    await tourRepository.updateTour(updatedTour);

    // 3. Mise à jour des stocks
    try {
      final allCylinders = await gasRepository.getCylinders();
      final cylinders = allCylinders
          .where((c) => c.enterpriseId == updatedTour.enterpriseId)
          .toList();

      // Phase 3.1: Déduire les vides chargées du stock société
      for (final entry in updatedTour.emptyBottlesLoaded.entries) {
        final weight = entry.key;
        final quantityToDeduct = entry.value;
        if (quantityToDeduct <= 0) continue;

        final cylinder = cylinders.firstWhere(
          (c) => c.weight == weight,
          orElse: () => throw NotFoundException(
              'Cylindre $weight kg introuvable', 'CYLINDER_NOT_FOUND'),
        );

        final existingStocks = await stockRepository.getStocksByWeight(
            updatedTour.enterpriseId, weight);
        final emptyStock = existingStocks
            .where((s) =>
                s.status == CylinderStatus.emptyAtStore &&
                s.cylinderId == cylinder.id)
            .firstOrNull;

        if (emptyStock != null) {
          final newQty =
              (emptyStock.quantity - quantityToDeduct).clamp(0, 1000000);
          await stockRepository.updateStockQuantity(emptyStock.id, newQty);
        }
      }

      // Phase 3.2: Ajouter les pleines reçues au stock société
      for (final entry in updatedTour.fullBottlesReceived.entries) {
        final weight = entry.key;
        final quantityFull = entry.value;
        if (quantityFull <= 0) continue;

        final cylinder = cylinders.firstWhere(
          (c) => c.weight == weight,
          orElse: () => throw NotFoundException(
              'Cylindre $weight kg introuvable', 'CYLINDER_NOT_FOUND'),
        );

        final existingStocks = await stockRepository.getStocksByWeight(
            updatedTour.enterpriseId, weight);
        final fullStock = existingStocks
            .where((s) =>
                s.status == CylinderStatus.full &&
                s.cylinderId == cylinder.id)
            .firstOrNull;

        if (fullStock != null) {
          await stockRepository.updateStockQuantity(
              fullStock.id, fullStock.quantity + quantityFull);
        } else {
          await stockRepository.addStock(CylinderStock(
            id: LocalIdGenerator.generate(),
            cylinderId: cylinder.id,
            weight: weight,
            status: CylinderStatus.full,
            quantity: quantityFull,
            enterpriseId: updatedTour.enterpriseId,
            updatedAt: DateTime.now(),
            createdAt: DateTime.now(),
          ));
        }
      }

      // 4. Audit Log
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
          'operation': 'supplier_exchange',
          'tourId': updatedTour.id,
          'supplierName': updatedTour.supplierName,
          'emptyBottlesLoaded': updatedTour.emptyBottlesLoaded
              .map((k, v) => MapEntry(k.toString(), v)),
          'fullBottlesReceived': updatedTour.fullBottlesReceived
              .map((k, v) => MapEntry(k.toString(), v)),
          'totalExchangeFees': updatedTour.totalExchangeFees,
        },
      ));

      // 5. Enregistrement de l'impact financier
      final totalExpenses = updatedTour.totalExpenses;

      if (totalExpenses > 0) {
        await auditTrailRepository.log(AuditRecord(
          id: '',
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
            'loadingFees': updatedTour.totalLoadingFees,
            'unloadingFees': updatedTour.totalUnloadingFees,
            'exchangeFees': updatedTour.totalExchangeFees,
            'gasPurchaseCost': updatedTour.gasPurchaseCost ?? 0.0,
            'tourDate': updatedTour.tourDate.toIso8601String(),
          },
        ));
      }

      AppLogger.info(
        'TourClosure: Clôture réussie du tour ${updatedTour.id}. '
        'Vides chargées: ${updatedTour.totalBottlesToLoad}, '
        'Pleines reçues: ${updatedTour.totalBottlesReceived}',
        name: 'transaction.tour_closure',
      );

      // 6. Vérifier les seuils d'alerte
      final alerts = <StockAlert>[];
      final affectedWeights = {
        ...updatedTour.emptyBottlesLoaded.keys,
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

  /// Exécute une collecte indépendante (Hors Tour) de manière atomique.
  /// 
  /// Cette méthode décompose la collecte en plusieurs transactions de vente (Type retour)
  /// pour assurer la traçabilité et gérer le stock/trésorerie via les mécanismes existants.
  Future<void> executeIndependentCollectionTransaction({
    required Collection collection,
    required String enterpriseId,
    required String userId,
  }) async {
    // 0. Validation
    final activeSession = await sessionRepository.getActiveSession(enterpriseId);
    if (activeSession == null) {
      throw ValidationException(
        'Aucune session active. Veuillez ouvrir une session.',
        'NO_ACTIVE_SESSION',
      );
    }

    if (collection.emptyBottles.isEmpty) {
      throw ValidationException(
        'La collecte ne contient aucune bouteille.',
        'EMPTY_COLLECTION',
      );
    }

    // 1. Récupérer les bouteilles pour mapping ID
    final allCylinders = await gasRepository.getCylinders();
    final cylinders = allCylinders
        .where((c) => c.enterpriseId == enterpriseId)
        .toList();

    // 2. Pour chaque type de bouteille, traiter le stock
    for (final entry in collection.emptyBottles.entries) {
      final weight = entry.key;
      final quantity = entry.value;
      if (quantity <= 0) continue;

      final cylinder = cylinders.firstWhere(
        (c) => c.weight == weight,
        orElse: () => throw NotFoundException('Cylindre $weight kg introuvable', 'CYLINDER_NOT_FOUND'),
      );

      // 2a. Si c'est un POS, déduire les vides du stock du POS source
      if (collection.type == CollectionType.pointOfSale) {
        final posId = collection.clientId;
        final posCylinders = allCylinders
            .where((c) => c.enterpriseId == posId)
            .toList();
        final posCylinder = posCylinders.firstWhere(
          (c) => c.weight == weight,
          orElse: () => throw NotFoundException(
            'Cylindre $weight kg non configuré au POS $posId',
            'CYLINDER_NOT_FOUND',
          ),
        );

        final posStocks = await stockRepository.getStocksByWeight(posId, weight);
        final posEmptyStock = posStocks
            .where((s) => s.status == CylinderStatus.emptyAtStore && s.cylinderId == posCylinder.id)
            .firstOrNull;

        if (posEmptyStock != null && posEmptyStock.quantity >= quantity) {
          await stockRepository.updateStockQuantity(
            posEmptyStock.id,
            posEmptyStock.quantity - quantity,
          );
        } else {
          AppLogger.warning(
            'Stock vide insuffisant au POS $posId pour ${weight}kg: '
            '${posEmptyStock?.quantity ?? 0} disponible, $quantity demandé. Déduction partielle.',
            name: 'transaction.collection',
          );
          if (posEmptyStock != null) {
            await stockRepository.updateStockQuantity(posEmptyStock.id, 0);
          }
        }
      }

      // 2b. Ajouter les vides au stock de la société (entreprise courante)
      final existingStocks = await stockRepository.getStocksByWeight(enterpriseId, weight);
      final emptyStock = existingStocks
          .where((s) => s.status == CylinderStatus.emptyAtStore && s.cylinderId == cylinder.id)
          .firstOrNull;

      if (emptyStock != null) {
        await stockRepository.updateStockQuantity(
          emptyStock.id,
          emptyStock.quantity + quantity,
        );
      } else {
        await stockRepository.addStock(CylinderStock(
          id: LocalIdGenerator.generate(),
          cylinderId: cylinder.id,
          weight: weight,
          status: CylinderStatus.emptyAtStore,
          quantity: quantity,
          enterpriseId: enterpriseId,
          updatedAt: DateTime.now(),
          createdAt: DateTime.now(),
        ));
      }
    }

    // 3. Gérer l'aspect financier (Trésorerie / Dépense)
    if (collection.amountPaid > 0) {
       // C'est une sortie d'argent (on paye le client pour les bouteilles / ou retour consigne)
       // On enregistre une dépense OU une opération de trésorerie SORTIE
       
       await treasuryRepository.saveOperation(TreasuryOperation(
        id: LocalIdGenerator.generate(),
        enterpriseId: enterpriseId,
        userId: userId,
        amount: collection.amountPaid.toInt(),
        type: TreasuryOperationType.removal, // Sortie d'argent
        date: DateTime.now(),
        reason: 'Paiement Collecte Indépendante (${collection.clientName})',
        referenceEntityId: collection.id, // On réfère à l'ID de collection même si virtuelle
        referenceEntityType: 'gas_collection', // Nouveau type
        createdAt: DateTime.now(),
      ));
    }

    // 4. Audit global
    await auditTrailRepository.log(AuditRecord(
        id: '',
        enterpriseId: enterpriseId,
        userId: userId,
        module: 'gaz',
        action: 'INDEPENDENT_COLLECTION',
        entityId: collection.id, // ID virtuel
        entityType: 'collection',
        timestamp: DateTime.now(),
        metadata: {
          'clientName': collection.clientName,
          'bottles': collection.emptyBottles.entries
              .map((e) => {'weight': e.key, 'qty': e.value})
              .toList(),
          'amountPaid': collection.amountPaid,
        },
      ));
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
    final diff = newQuantity - oldQuantity;
    
    // 1. Mettre à jour le stock
    await stockRepository.updateStock(stock.copyWith(
      quantity: newQuantity,
      updatedAt: DateTime.now(),
    ));

    // 2. Calculer l'impact financier si c'est une perte (bouteilles pleines manquantes)
    if (diff != 0 && stock.status == CylinderStatus.full) {
      final cylinder = await gasRepository.getCylinderById(stock.cylinderId);
      if (cylinder != null) {
        final financialImpact = diff.abs() * cylinder.buyPrice;
        
        await expenseRepository.addExpense(GazExpense(
          id: LocalIdGenerator.generate(),
          enterpriseId: stock.enterpriseId,
          category: ExpenseCategory.stockAdjustment,
          amount: diff < 0 ? financialImpact.toDouble() : -financialImpact.toDouble(), // Perte = Montant positif (dépense), Gain = Montant négatif
          description: 'Ajustement de stock ${cylinder.weight}kg: ${diff > 0 ? "+" : ""}$diff unités (${reason ?? "Inventaire"})',
          date: DateTime.now(),
          isFixed: false,
          notes: 'Quantité ajustée de $oldQuantity à $newQuantity. Impact financier: $financialImpact',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }
    }

    // 3. Log l'audit
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
        'diff': diff,
        'reason': reason,
        'siteId': stock.siteId,
        'movements': [
          {
            'cylinderId': stock.cylinderId,
            'weight': stock.weight,
            'status': stock.status.name,
            'delta': diff
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
      // Find the existing stock ID by properties if not reliably provided or to ensure robustness
      final existingStocks = await stockRepository.getStocksByWeight(
        audit.enterpriseId, 
        item.weight, 
        siteId: audit.siteId,
      );
      
      final existingStock = existingStocks.where((s) => s.status == item.status && s.cylinderId == item.cylinderId).firstOrNull;

      if (existingStock != null) {
        await stockRepository.updateStockQuantity(existingStock.id, item.physicalQuantity);
      } else {
        // Create new stock record if it doesn't exist (e.g. initial audit)
        await stockRepository.addStock(CylinderStock(
          id: LocalIdGenerator.generate(),
          cylinderId: item.cylinderId,
          weight: item.weight,
          status: item.status,
          quantity: item.physicalQuantity,
          enterpriseId: audit.enterpriseId,
          siteId: audit.siteId,
          updatedAt: DateTime.now(),
          createdAt: DateTime.now(),
        ));
      }
    }

    // 2. Enregistrer l'audit dans l'historique
    await inventoryAuditRepository.saveAudit(audit);

    // 3. Log l'audit global
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

  /// Exécute un remplissage interne (Vide -> Plein) de manière atomique.
  Future<void> executeFillingTransaction({
    required String enterpriseId,
    required String userId,
    required Map<int, int> quantities,
    String? notes,
  }) async {
    final allCylinders = await gasRepository.getCylinders();
    final cylinders = allCylinders.where((c) => c.enterpriseId == enterpriseId).toList();

    for (final entry in quantities.entries) {
      final weight = entry.key;
      final quantity = entry.value;
      if (quantity <= 0) continue;

      final cylinder = cylinders.firstWhere(
        (c) => c.weight == weight,
        orElse: () => throw NotFoundException('Cylindre $weight kg introuvable', 'CYLINDER_NOT_FOUND'),
      );

      final stocks = await stockRepository.getStocksByWeight(enterpriseId, weight);
      
      // 1. Décrémenter stock VIDE
      final emptyStock = stocks.where((s) => s.status == CylinderStatus.emptyAtStore && s.cylinderId == cylinder.id).firstOrNull;
      if (emptyStock == null || emptyStock.quantity < quantity) {
        throw ValidationException('Stock vide insuffisant pour $weight kg', 'INSUFFICIENT_STOCK');
      }
      await stockRepository.updateStockQuantity(emptyStock.id, emptyStock.quantity - quantity);

      // 2. Incrémenter stock PLEIN
      final fullStock = stocks.where((s) => s.status == CylinderStatus.full && s.cylinderId == cylinder.id).firstOrNull;
      if (fullStock != null) {
        await stockRepository.updateStockQuantity(fullStock.id, fullStock.quantity + quantity);
      } else {
        await stockRepository.addStock(CylinderStock(
          id: LocalIdGenerator.generate(),
          cylinderId: cylinder.id,
          weight: weight,
          status: CylinderStatus.full,
          quantity: quantity,
          enterpriseId: enterpriseId,
          updatedAt: DateTime.now(),
          createdAt: DateTime.now(),
        ));
      }
    }

    // 3. Audit Trail
    await auditTrailRepository.log(AuditRecord(
      id: '',
      enterpriseId: enterpriseId,
      userId: userId,
      module: 'gaz',
      action: 'INTERNAL_FILLING',
      entityId: 'internal_filling_${DateTime.now().millisecondsSinceEpoch}',
      entityType: 'stock_filling',
      timestamp: DateTime.now(),
      metadata: {
        'operation': 'internal_filling',
        'quantities': quantities.map((k, v) => MapEntry(k.toString(), v)),
        'notes': notes,
      },
    ));
  }
}
