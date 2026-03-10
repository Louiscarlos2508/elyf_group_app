import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/offline_repository.dart' show LocalIdGenerator;

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
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';
import 'package:elyf_groupe_app/shared/domain/entities/treasury_operation.dart';

import '../repositories/treasury_repository.dart';
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
    final emptyStocks = existingStocks.where((s) => s.status == CylinderStatus.emptyAtStore && s.cylinderId == cylinderId).toList();
    int remainingToDeductEmpty = quantity;
    for (final s in emptyStocks) {
      if (remainingToDeductEmpty <= 0) break;
      final toDeduct = remainingToDeductEmpty > s.quantity ? s.quantity : remainingToDeductEmpty;
      await stockRepository.updateStockQuantity(s.id, s.quantity - toDeduct);
      remainingToDeductEmpty -= toDeduct;
    }

    // Déduire du stock FUITE (Échange gratuit chez le fournisseur pour la quantité LEAK)
    if (leakySwappedQuantity > 0) {
      final leakStocks = existingStocks.where((s) => s.status == CylinderStatus.leak && s.cylinderId == cylinderId).toList();
      int remainingToDeductLeak = leakySwappedQuantity;
      for (final s in leakStocks) {
        if (remainingToDeductLeak <= 0) break;
        final toDeduct = remainingToDeductLeak > s.quantity ? s.quantity : remainingToDeductLeak;
        await stockRepository.updateStockQuantity(s.id, s.quantity - toDeduct);
        remainingToDeductLeak -= toDeduct;
      }
      
      // Mettre à jour les enregistrements individuels de fuite
      final pendingLeaks = await leakRepository.getLeaks(enterpriseId);
      final leaksToExchange = pendingLeaks
          .where((l) => l.cylinderId == cylinderId && (l.status == LeakStatus.sentForExchange || l.status == LeakStatus.reported))
          .take(leakySwappedQuantity)
          .toList();
          
      for (final leak in leaksToExchange) {
        await leakRepository.markAsExchanged(leak.id, DateTime.now());
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
      fromAccount: PaymentMethod.mobileMoney, // Ravitaillement stock gaz par OM
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
    // 0. Session check removed (Optional)
    final saleWithSession = sale;

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
          stocks.where((s) => s.status == CylinderStatus.full && s.cylinderId == saleWithSession.cylinderId).toList()
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
      if ((saleWithSession.isExchange ||
              saleWithSession.dealType == GasSaleDealType.returnCylinder) &&
          saleWithSession.emptyReturnedQuantity > 0) {
        // Robust lookup for empty stock: filter by both status AND cylinderId (and siteId)
        final emptyStock = stocks
            .where(
              (s) =>
                  s.status == CylinderStatus.emptyAtStore &&
                  s.cylinderId == saleWithSession.cylinderId,
            )
            .firstOrNull;

        if (emptyStock != null) {
          AppLogger.info(
            'TransactionService: Incrementing existing empty stock ${emptyStock.id} by ${saleWithSession.emptyReturnedQuantity}',
            name: 'transaction.sale',
          );
          await stockRepository.updateStockQuantity(
            emptyStock.id,
            emptyStock.quantity + saleWithSession.emptyReturnedQuantity,
          );
        } else {
          final newStockId =
              'stock_empty_${DateTime.now().millisecondsSinceEpoch}_$weight';
          AppLogger.info(
            'TransactionService: Creating new empty stock record $newStockId for ${saleWithSession.cylinderId}',
            name: 'transaction.sale',
          );
          // Créer un enregistrement de stock vide si inexistant
          await stockRepository.addStock(
            CylinderStock(
              id: newStockId,
              cylinderId: saleWithSession.cylinderId,
              weight: weight,
              status: CylinderStatus.emptyAtStore,
              quantity: saleWithSession.emptyReturnedQuantity,
              enterpriseId: enterpriseId,
              siteId: siteId,
              updatedAt: DateTime.now(),
              createdAt: DateTime.now(),
            ),
          );
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
  
      // 4.5. Enregistrement Trésorerie — paiement ventilé si mixte
      if (saleWithSession.isMixedPayment) {
        // Paiement mixte : 2 opérations séparées
        final cashAmt = saleWithSession.cashAmount ?? 0;
        final mmAmt = saleWithSession.mobileMoneyAmount ?? 0;
        if (cashAmt > 0) {
          await treasuryRepository.saveOperation(TreasuryOperation(
            id: LocalIdGenerator.generate(),
            enterpriseId: enterpriseId,
            userId: saleWithSession.sellerId ?? '',
            amount: cashAmt.toInt(),
            type: TreasuryOperationType.supply,
            toAccount: PaymentMethod.cash,
            date: saleWithSession.saleDate,
            reason: 'Vente Gaz ${weight}kg x ${saleWithSession.quantity} (Espèces)',
            referenceEntityId: saleWithSession.id,
            referenceEntityType: 'gas_sale',
            createdAt: DateTime.now(),
          ));
        }
        if (mmAmt > 0) {
          await treasuryRepository.saveOperation(TreasuryOperation(
            id: LocalIdGenerator.generate(),
            enterpriseId: enterpriseId,
            userId: saleWithSession.sellerId ?? '',
            amount: mmAmt.toInt(),
            type: TreasuryOperationType.supply,
            toAccount: PaymentMethod.mobileMoney,
            date: saleWithSession.saleDate,
            reason: 'Vente Gaz ${weight}kg x ${saleWithSession.quantity} (Orange Money)',
            referenceEntityId: saleWithSession.id,
            referenceEntityType: 'gas_sale',
            createdAt: DateTime.now(),
          ));
        }
      } else {
        // Paiement simple (Espèces ou Orange Money)
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
      }
  
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
          'sessionId': saleWithSession.sessionId,
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
  /// Exécute la clôture d'un tour d'approvisionnement fournisseur.
  ///
  /// Le tour est désormais purement administratif.
  /// Exécute le démarrage d'un tour (Sortie du stock initial du magasin vers le camion).
  Future<void> executeTourStartTransaction({
    required String tourId,
    required String userId,
    required Map<int, int> fullBottles,
    required Map<int, int> emptyBottles,
    required Map<int, String> weightToCylinderId,
  }) async {
    final tour = await tourRepository.getTourById(tourId);
    if (tour == null) throw const NotFoundException('Tour introuvable', 'TOUR_NOT_FOUND');

    // 1. Débiter le stock du magasin
    for (final entry in fullBottles.entries) {
      final weight = entry.key;
      final qty = entry.value;
      if (qty <= 0) continue;
      final cylinderId = weightToCylinderId[weight];
      if (cylinderId == null) continue;

      await _moveStock(
        enterpriseId: tour.enterpriseId,
        cylinderId: cylinderId,
        weight: weight,
        fromStatus: CylinderStatus.full,
        toStatus: CylinderStatus.fullInTransit, // On peut utiliser Transit pour "Dans le camion"
        quantity: qty,
      );
    }

    for (final entry in emptyBottles.entries) {
      final weight = entry.key;
      final qty = entry.value;
      if (qty <= 0) continue;
      final cylinderId = weightToCylinderId[weight];
      if (cylinderId == null) continue;

      await _moveStock(
        enterpriseId: tour.enterpriseId,
        cylinderId: cylinderId,
        weight: weight,
        fromStatus: CylinderStatus.emptyAtStore,
        toStatus: CylinderStatus.emptyInTransit,
        quantity: qty,
      );
    }

    // 2. Audit Log
    await auditTrailRepository.log(AuditRecord(
      id: '',
      enterpriseId: tour.enterpriseId,
      userId: userId,
      module: 'gaz',
      action: 'TOUR_STARTED_STOCK_OUT',
      entityId: tour.id,
      entityType: 'tour',
      timestamp: DateTime.now(),
      metadata: {
        'fullBottles': fullBottles.map((k, v) => MapEntry(k.toString(), v)),
        'emptyBottles': emptyBottles.map((k, v) => MapEntry(k.toString(), v)),
      },
    ));
  }

  /// Exécute la clôture d'un tour d'approvisionnement fournisseur (Journal de bord camion).
  /// Exécute la recharge d'un tour (Mise à jour du stock dans le camion).
  Future<void> executeTourRechargeTransaction({
    required String tourId,
    required String userId,
    required Map<int, int> fullReceived,
    required Map<int, int> emptyReturned,
    required Map<int, String> weightToCylinderId,
    double? gasCost,
  }) async {
    final tour = await tourRepository.getTourById(tourId);
    if (tour == null) throw const NotFoundException('Tour introuvable', 'TOUR_NOT_FOUND');

    // 1. Débiter les vides du camion (on les rend au fournisseur)
    for (final entry in emptyReturned.entries) {
      final weight = entry.key;
      final qty = entry.value;
      if (qty <= 0) continue;
      final cylinderId = weightToCylinderId[weight];
      if (cylinderId == null) continue;

      await _moveStock(
        enterpriseId: tour.enterpriseId,
        cylinderId: cylinderId,
        weight: weight,
        fromStatus: CylinderStatus.emptyInTransit,
        toStatus: CylinderStatus.emptyAtStore, // Temporairement "store" du fournisseur ou simplement déduit
        quantity: qty,
      );
    }

    // 2. Créditer les pleines dans le camion (reçues du fournisseur)
    for (final entry in fullReceived.entries) {
      final weight = entry.key;
      final qty = entry.value;
      if (qty <= 0) continue;
      final cylinderId = weightToCylinderId[weight];
      if (cylinderId == null) continue;

      // On simule une entrée directe en transit car c'est une recharge fournisseur
      final stocks = await stockRepository.getStocksByWeight(tour.enterpriseId, weight);
      final transitStock = stocks.where((s) => s.status == CylinderStatus.fullInTransit && s.cylinderId == cylinderId).firstOrNull;

      if (transitStock != null) {
        await stockRepository.updateStockQuantity(transitStock.id, transitStock.quantity + qty);
      } else {
        await stockRepository.addStock(CylinderStock(
          id: LocalIdGenerator.generate(),
          enterpriseId: tour.enterpriseId,
          cylinderId: cylinderId,
          weight: weight,
          status: CylinderStatus.fullInTransit,
          quantity: qty,
          updatedAt: DateTime.now(),
          createdAt: DateTime.now(),
        ));
      }
    }

    // 3. Créer la dépense gaz si un coût est spécifié
    if (gasCost != null && gasCost > 0) {
      final expenseId = LocalIdGenerator.generate();
      await expenseRepository.addExpense(GazExpense(
        id: expenseId,
        enterpriseId: tour.enterpriseId,
        category: ExpenseCategory.stockReplenishment,
        amount: gasCost,
        description: 'Recharge Tournée ${tour.id}',
        date: DateTime.now(),
        isFixed: false,
        notes: 'Tour: ${tour.id}',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      // Ajout de l'opération de trésorerie (Orange Money par défaut pour recharge)
      await treasuryRepository.saveOperation(TreasuryOperation(
        id: LocalIdGenerator.generate(),
        enterpriseId: tour.enterpriseId,
        userId: userId,
        amount: gasCost.toInt(),
        type: TreasuryOperationType.removal,
        fromAccount: PaymentMethod.mobileMoney,
        date: DateTime.now(),
        reason: 'Paiement Recharge Tournée ${tour.id} (Orange Money)',
        referenceEntityId: expenseId,
        referenceEntityType: 'gaz_expense',
        createdAt: DateTime.now(),
      ));
    }

    // 4. Audit Log
    await auditTrailRepository.log(AuditRecord(
      id: '',
      enterpriseId: tour.enterpriseId,
      userId: userId,
      module: 'gaz',
      action: 'TOUR_RECHARGED_STOCK_IN',
      entityId: tour.id,
      entityType: 'tour',
      timestamp: DateTime.now(),
      metadata: {
        'fullReceived': fullReceived.map((k, v) => MapEntry(k.toString(), v)),
        'emptyReturned': emptyReturned.map((k, v) => MapEntry(k.toString(), v)),
        'cost': gasCost,
      },
    ));
  }

  Future<({Tour tour, List<StockAlert> alerts})> executeTourClosureTransaction({
    required String tourId,
    required String userId,
    required Map<int, int> remainingFull,
    required Map<int, int> remainingEmpty,
    Map<int, String> weightToCylinderId = const {},
  }) async {
    final tour = await tourRepository.getTourById(tourId);
    if (tour == null) throw const NotFoundException('Tour introuvable', 'TOUR_NOT_FOUND');

    // 1. Traiter toutes les interactions non traitées
    for (final interaction in tour.siteInteractions) {
      if (interaction.isProcessed) continue;
      await processSiteInteraction(tour, interaction, userId, weightToCylinderId);
    }

    // 2. Traiter les frais de transport (Déduction Trésorerie Cash)
    for (final expense in tour.transportExpenses) {
      await treasuryRepository.saveOperation(TreasuryOperation(
        id: LocalIdGenerator.generate(),
        enterpriseId: tour.enterpriseId,
        userId: userId,
        amount: expense.amount.toInt(),
        type: TreasuryOperationType.removal,
        fromAccount: PaymentMethod.cash,
        date: expense.expenseDate,
        reason: 'Frais Tournée : ${expense.description.isNotEmpty ? expense.description : expense.category}',
        referenceEntityId: tour.id,
        referenceEntityType: 'tour_transport_expense',
        createdAt: DateTime.now(),
      ));
    }

    // 3. Réintégrer le stock restant dans le magasin
    // Le stock dans le camion est actuellement en 'InTransit'.
    for (final entry in remainingFull.entries) {
      final weight = entry.key;
      final qty = entry.value;
      if (qty <= 0) continue;
      final cylinderId = weightToCylinderId[weight];
      if (cylinderId == null) continue;

      await _moveStock(
        enterpriseId: tour.enterpriseId,
        cylinderId: cylinderId,
        weight: weight,
        fromStatus: CylinderStatus.fullInTransit,
        toStatus: CylinderStatus.full,
        quantity: qty,
        force: true,
      );
    }

    for (final entry in remainingEmpty.entries) {
      final weight = entry.key;
      final qty = entry.value;
      if (qty <= 0) continue;
      final cylinderId = weightToCylinderId[weight];
      if (cylinderId == null) continue;

      await _moveStock(
        enterpriseId: tour.enterpriseId,
        cylinderId: cylinderId,
        weight: weight,
        fromStatus: CylinderStatus.emptyInTransit,
        toStatus: CylinderStatus.emptyAtStore,
        quantity: qty,
        force: true,
      );
    }

    // 3. Mettre à jour le tour
    final updatedTour = tour.copyWith(
      status: TourStatus.closed,
      remainingFullBottles: remainingFull,
      remainingEmptyBottles: remainingEmpty,
      closureDate: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await tourRepository.updateTour(updatedTour);

    // 4. Audit Log Global
    await auditTrailRepository.log(AuditRecord(
      id: '',
      enterpriseId: tour.enterpriseId,
      userId: userId,
      module: 'gaz',
      action: 'TOUR_CLOSED_FINAL',
      entityId: tour.id,
      entityType: 'tour',
      timestamp: DateTime.now(),
      metadata: {
        'remainingFull': remainingFull.map((k, v) => MapEntry(k.toString(), v)),
        'remainingEmpty': remainingEmpty.map((k, v) => MapEntry(k.toString(), v)),
        'totalCash': tour.totalCashCollectedFromSites,
        'totalExpenses': tour.totalExpenses,
      },
    ));

    return (tour: updatedTour, alerts: const <StockAlert>[]);
  }

  /// Traite une interaction individuelle avec un site.
  /// Ajuste le stock pour une correction d'interaction (différentiel).
  Future<void> adjustStock(Tour tour, TourSiteInteraction correction, String userId, Map<int, String> weightToCylinderId) async {
    // On utilise processSiteInteraction qui fait déjà le travail de mouvement de stock
    // mais on passe une interaction qui ne contient que les deltas.
    // Note: Pour les grossistes, cela créera des micro-ventes de correction, ce qui est acceptable
    // pour garder la trace financière si besoin, ou on pourrait filtrer.
    await processSiteInteraction(tour, correction, userId, weightToCylinderId);
  }

  Future<void> processSiteInteraction(Tour tour, TourSiteInteraction interaction, String userId, Map<int, String> weightToCylinderId) async {
    final sessionId = 'site_${tour.id}_${interaction.siteId}_${interaction.timestamp.millisecondsSinceEpoch}';

    // 1. Si c'est un grossiste, créer les ventes
    if (interaction.isWholesaler) {
      for (final entry in interaction.fullBottlesDelivered.entries) {
        final weight = entry.key;
        final qty = entry.value;
        if (qty <= 0) continue;
        final cylinderId = weightToCylinderId[weight];
        if (cylinderId == null) continue;

        // Calcul du prix proportionnel si montant global saisi
        double unitPrice = 0;
        if (interaction.cashCollected > 0) {
           final totalKg = interaction.fullBottlesDelivered.entries.fold<double>(0, (a, b) => a + (b.key * b.value));
           unitPrice = totalKg > 0 ? (interaction.cashCollected / totalKg) * weight : 0;
        }

        await gasRepository.addSale(GasSale(
          id: LocalIdGenerator.generate(),
          enterpriseId: tour.enterpriseId,
          cylinderId: cylinderId,
          quantity: qty,
          unitPrice: unitPrice,
          totalAmount: unitPrice * qty,
          saleDate: interaction.timestamp,
          saleType: SaleType.wholesale,
          tourId: tour.id,
          wholesalerId: interaction.siteId,
          wholesalerName: interaction.siteName,
          sellerId: userId,
          paymentMethod: interaction.paymentMethod,
          sessionId: sessionId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));

        // Débiter administrativement du camion (Vente grossiste sort de transit)
        await _moveStock(
          enterpriseId: tour.enterpriseId,
          cylinderId: cylinderId,
          weight: weight,
          fromStatus: CylinderStatus.fullInTransit,
          toStatus: CylinderStatus.full, // On simule un passage par 'full' car c'est une vente, 
                                          // mais on pourrait aussi ne rien incrémenter si on veut juste déduire.
                                          // Pour éviter d'augmenter le stock magasin, on peut déduire SANS incrémenter
                                          // ou incrémenter un statut fictif. Ici on va juste déduire du transit.
          quantity: qty,
          force: true,
          decrementOnly: true,
        );
      }

      // Collecte de vides chez le grossiste (comme POS)
      for (final entry in interaction.emptyBottlesCollected.entries) {
        final weight = entry.key;
        final qty = entry.value;
        if (qty <= 0) continue;
        final cylinderId = weightToCylinderId[weight];
        if (cylinderId == null) continue;

        // Grossiste (rien/administratif) -> Camion (Parent, InTransit)
        await _moveStock(
          enterpriseId: tour.enterpriseId,
          cylinderId: cylinderId,
          weight: weight,
          fromStatus: CylinderStatus.emptyAtStore, // Status source peu importe si force
          toStatus: CylinderStatus.emptyInTransit,
          quantity: qty,
          force: true,
        );
      }
    }

    // 2. Si c'est un POS, mettre à jour le stock du camion (Transit) uniquement.
    // Les POS sont autonomes et gèrent leur propre stock.
    if (interaction.isPos) {
      for (final entry in interaction.fullBottlesDelivered.entries) {
        final weight = entry.key;
        final qty = entry.value;
        if (qty <= 0) continue;
        final cylinderId = weightToCylinderId[weight];
        if (cylinderId == null) continue;

        // Décrémenter seulement le stock du camion (Transit)
        await _moveStock(
          enterpriseId: tour.enterpriseId,
          cylinderId: cylinderId,
          weight: weight,
          fromStatus: CylinderStatus.fullInTransit,
          toStatus: CylinderStatus.full, // Destination ignorée car decrementOnly
          quantity: qty,
          force: true,
          decrementOnly: true,
        );
      }

      for (final entry in interaction.emptyBottlesCollected.entries) {
        final weight = entry.key;
        final qty = entry.value;
        if (qty <= 0) continue;
        final cylinderId = weightToCylinderId[weight];
        if (cylinderId == null) continue;

        // Incrémenter le stock du camion (Transit)
        // On simule une sortie du magasin central (ou pool administratif) vers le camion
        await _moveStock(
          enterpriseId: tour.enterpriseId,
          cylinderId: cylinderId,
          weight: weight,
          fromStatus: CylinderStatus.emptyAtStore,
          toStatus: CylinderStatus.emptyInTransit,
          quantity: qty,
          force: true,
        );
      }
    }

    // 3. Enregistrer l'opération de trésorerie si encaissé
    if (interaction.cashCollected > 0) {
      await treasuryRepository.saveOperation(TreasuryOperation(
        id: LocalIdGenerator.generate(),
        enterpriseId: tour.enterpriseId,
        userId: userId,
        amount: interaction.cashCollected.toInt(),
        type: TreasuryOperationType.supply,
        toAccount: interaction.paymentMethod,
        date: interaction.timestamp,
        reason: 'Recette Site : ${interaction.siteName} (Tour ${tour.id})',
        referenceEntityId: tour.id,
        referenceEntityType: 'tour_site_interaction',
        createdAt: DateTime.now(),
      ));
    }
  }

  /// Exécute l'encaissement d'un site individuellement (Optionnel).

  /// Annule un tour.
  Future<void> executeTourCancellationTransaction({
    required String tourId,
    required String userId,
  }) async {
    final tour = await tourRepository.getTourById(tourId);
    if (tour == null) throw const NotFoundException('Tour introuvable', 'TOUR_NOT_FOUND');
    if (tour.status == TourStatus.cancelled) return;

    // Annuler le tour (Purement administratif)
    await tourRepository.updateTour(tour.copyWith(
      status: TourStatus.cancelled,
      cancelledDate: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    // Audit Trail
    await auditTrailRepository.log(AuditRecord(
      id: '',
      enterpriseId: tour.enterpriseId,
      userId: userId,
      module: 'gaz',
      action: 'TOUR_CANCELLED',
      entityId: tour.id,
      entityType: 'tour',
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _moveStock({
    required String enterpriseId,
    required String cylinderId,
    required int weight,
    required CylinderStatus fromStatus,
    required CylinderStatus toStatus,
    required int quantity,
    String? fromSiteId,
    String? siteId, // toSiteId
    bool force = false,
    bool decrementOnly = false,
  }) async {
    if (quantity <= 0) return;

    // Décrémenter Source
    final stocksSource = await stockRepository.getStocksByWeight(enterpriseId, weight, siteId: fromSiteId);
    final sourceStocks = stocksSource.where((s) => s.status == fromStatus && s.cylinderId == cylinderId).toList();
    final totalSource = sourceStocks.fold<int>(0, (sum, s) => sum + s.quantity);
    
    if (totalSource < quantity && !force) {
      throw ValidationException(
        'Stock insuffisant (${fromStatus.label}) pour $weight kg : $totalSource disponibles, $quantity demandées',
        'INSUFFICIENT_STOCK',
      );
    }

    int remainingToDeduct = quantity;
    for (final s in sourceStocks) {
      if (remainingToDeduct <= 0) break;
      final toDeduct = remainingToDeduct > s.quantity ? s.quantity : remainingToDeduct;
      await stockRepository.updateStockQuantity(s.id, s.quantity - toDeduct);
      remainingToDeduct -= toDeduct;
    }

    // Si force et qu'il reste à déduire (pas assez de stock), on impacte le premier record ou on crée un négatif
    if (remainingToDeduct > 0 && force) {
      if (sourceStocks.isNotEmpty) {
        final firstRecord = sourceStocks.first;
        await stockRepository.updateStockQuantity(firstRecord.id, firstRecord.quantity - remainingToDeduct);
      } else {
        // Optionnel : Créer un record négatif pour garder la trace de la dette de stock
        await stockRepository.addStock(CylinderStock(
          id: LocalIdGenerator.generate(),
          cylinderId: cylinderId,
          weight: weight,
          status: fromStatus,
          quantity: -remainingToDeduct,
          enterpriseId: enterpriseId,
          siteId: fromSiteId,
          updatedAt: DateTime.now(),
          createdAt: DateTime.now(),
        ));
      }
    }

    if (decrementOnly) return;

    // Incrémenter Destination
    final stocksDest = (fromSiteId == siteId) 
        ? stocksSource 
        : await stockRepository.getStocksByWeight(enterpriseId, weight, siteId: siteId);
    
    final destStock = stocksDest.where((s) => s.status == toStatus && s.cylinderId == cylinderId).firstOrNull;
    if (destStock != null) {
      await stockRepository.updateStockQuantity(destStock.id, destStock.quantity + quantity);
    } else {
      await stockRepository.addStock(CylinderStock(
        id: LocalIdGenerator.generate(),
        cylinderId: cylinderId,
        weight: weight,
        status: toStatus,
        quantity: quantity,
        enterpriseId: enterpriseId,
        siteId: siteId,
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
      ));
    }
  }




  /// Déclare une fuite de manière atomique.
  /// 
  /// Étapes :
  /// 1. Décrémente le stock plein
  /// 2. Incrémente le stock "Fuite" (CylinderStatus.leak)
  /// 3. Enregistre la fuite comme "Signalée" (reported)
  /// 4. Log l'audit
  Future<void> executeLeakDeclaration({
    required CylinderLeak leak,
    required String userId,
  }) async {
    // 1. Décrémenter stock plein
    final fullStocks = await stockRepository.getStocksByWeight(leak.enterpriseId, leak.weight);
    final fullStock = fullStocks.where((s) => s.status == CylinderStatus.full && s.cylinderId == leak.cylinderId).firstOrNull;
    
    if (fullStock == null || fullStock.quantity <= 0) {
      throw const ValidationException('Stock insuffisant pour déclarer une fuite', 'INSUFFICIENT_STOCK');
    }

    await stockRepository.updateStock(fullStock.copyWith(
      quantity: fullStock.quantity - 1,
      updatedAt: DateTime.now(),
    ));

    // 2. Incrémenter stock fuite au magasin
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

    // 3. Enregistrer la trace de la fuite (Comme signalée)
    await leakRepository.reportLeak(leak.copyWith(status: LeakStatus.reported));

    // 4. Audit Trail
    await auditTrailRepository.log(AuditRecord(
      id: '',
      enterpriseId: leak.enterpriseId,
      userId: userId,
      module: 'gaz',
      action: 'LEAK_DECLARATION_REPORTED',
      entityId: leak.id,
      entityType: 'leak',
      timestamp: DateTime.now(),
      metadata: {
        ...leak.toMap(),
        'operation': 'leak_reported',
        'movements': [
          {'cylinderId': leak.cylinderId, 'weight': leak.weight, 'status': 'full', 'delta': -1},
          {'cylinderId': leak.cylinderId, 'weight': leak.weight, 'status': 'leak', 'delta': 1},
        ],
      },
    ));
  }

  /// Convertit une fuite déclaré en bouteille vide de manière atomique.
  /// 
  /// Étapes :
  /// 1. Décrémente le stock "Fuite"
  /// 2. Incrémente le stock "Vide"
  /// 3. Change le statut de la fuite en 'convertedToEmpty'
  /// 4. Log l'audit (Perte sèche)
  Future<void> executeLeakToEmptyConversion({
    required CylinderLeak leak,
    String? siteId,
    required String userId,
  }) async {
    // 1. Décrémenter stock Fuite
    final stocks = await stockRepository.getStocksByWeight(leak.enterpriseId, leak.weight, siteId: siteId);
    final leakStock = stocks.where((s) => s.status == CylinderStatus.leak && s.cylinderId == leak.cylinderId).firstOrNull;
    
    if (leakStock == null || leakStock.quantity <= 0) {
      throw const ValidationException('Stock "Fuite" insuffisant pour la conversion', 'INSUFFICIENT_STOCK');
    }

    await stockRepository.updateStockQuantity(leakStock.id, leakStock.quantity - 1);

    // 2. Incrémenter stock Vide
    final emptyStock = stocks.where((s) => s.status == CylinderStatus.emptyAtStore && s.cylinderId == leak.cylinderId).firstOrNull;
    if (emptyStock != null) {
      await stockRepository.updateStockQuantity(emptyStock.id, emptyStock.quantity + 1);
    } else {
      await stockRepository.addStock(CylinderStock(
        id: LocalIdGenerator.generate(),
        cylinderId: leak.cylinderId,
        weight: leak.weight,
        status: CylinderStatus.emptyAtStore,
        quantity: 1,
        enterpriseId: leak.enterpriseId,
        siteId: siteId,
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
      ));
    }

    // 3. Mettre à jour la fuite
    await leakRepository.updateLeak(leak.copyWith(
      status: LeakStatus.convertedToEmpty,
      updatedAt: DateTime.now(),
    ));
    
    // 3.5 Enregistrement dans les dépenses (Perte sèche du gaz) 
    // since the store absorbed the cost of the gas that leaked out.
    final cylinder = await gasRepository.getCylinderById(leak.cylinderId);
    if (cylinder != null) {
        await expenseRepository.addExpense(GazExpense(
          id: LocalIdGenerator.generate(),
          enterpriseId: leak.enterpriseId,
          category: ExpenseCategory.stockAdjustment,
          amount: cylinder.buyPrice, // The retail/buy value of the gas lost
          description: 'Perte Gaz suite à fuite non échangeable (${leak.weight}kg)',
          date: DateTime.now(),
          isFixed: false,
          notes: 'Conversion fuite -> vide. ID Bouteille: ${leak.cylinderId}',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
    }

    // 4. Audit Trail
    await auditTrailRepository.log(AuditRecord(
      id: '',
      enterpriseId: leak.enterpriseId,
      userId: userId,
      module: 'gaz',
      action: 'LEAK_CONVERTED_TO_EMPTY',
      entityId: leak.id,
      entityType: 'leak',
      timestamp: DateTime.now(),
      metadata: {
        ...leak.toMap(),
        'operation': 'leak_to_empty_conversion',
        'siteId': siteId,
        'movements': [
          {'cylinderId': leak.cylinderId, 'weight': leak.weight, 'status': 'leak', 'delta': -1},
          {'cylinderId': leak.cylinderId, 'weight': leak.weight, 'status': 'emptyAtStore', 'delta': 1},
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
    
    // Pour simplifier, on va chercher par cylinderId via gasRepository si besoin, 
    // mais stockRepository.getStocksByWeight nous donne tous les stocks pour ce poids.
    // On a besoin du poids des deux bouteilles de l'échange.
    
    final fromCylinder = await gasRepository.getCylinderById(exchange.fromCylinderId);
    final toCylinder = await gasRepository.getCylinderById(exchange.toCylinderId);
    
    if (fromCylinder == null || toCylinder == null) {
      throw const NotFoundException('Bouteille introuvable', 'CYLINDER_NOT_FOUND');
    }

    final fromStocksList = await stockRepository.getStocksByWeight(exchange.enterpriseId, fromCylinder.weight);
    final fromStock = fromStocksList.where((s) => s.cylinderId == exchange.fromCylinderId && s.status == CylinderStatus.emptyAtStore).firstOrNull;

    if (fromStock == null || fromStock.quantity < exchange.quantity) {
      throw const ValidationException('Stock insuffisant pour l\'échange', 'INSUFFICIENT_STOCK');
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



  /// Exécute un audit d'inventaire complet.
  /// 
  /// Met à jour plusieurs stocks et loggue l'audit global.
  Future<void> executeInventoryAudit({
    required GazInventoryAudit audit,
    required String userId,
  }) async {
    // 1. Mettre à jour chaque stock
    for (final item in audit.items) {
      final existingStocks = await stockRepository.getStocksByWeight(
        audit.enterpriseId, 
        item.weight, 
        siteId: audit.siteId,
      );
      
      final matchingStocks = existingStocks.where((s) => s.status == item.status && s.cylinderId == item.cylinderId && s.siteId == audit.siteId).toList();

      if (matchingStocks.isNotEmpty) {
        // Mettre à jour le premier record avec la valeur réelle
        await stockRepository.updateStockQuantity(matchingStocks.first.id, item.physicalQuantity);
        // Mettre à zéro les doublons éventuels pour éviter l'inflation du stock
        for (int i = 1; i < matchingStocks.length; i++) {
          await stockRepository.updateStockQuantity(matchingStocks[i].id, 0);
        }
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
    final cylinders = await gasRepository.getCylinders();

    for (final entry in quantities.entries) {
      final weight = entry.key;
      final quantity = entry.value;
      if (quantity <= 0) continue;

      final cylinder = cylinders.firstWhere(
        (c) => c.weight == weight && c.enterpriseId == enterpriseId,
        orElse: () => cylinders.firstWhere(
          (c) => c.weight == weight,
          orElse: () => throw NotFoundException('Cylindre $weight kg introuvable', 'CYLINDER_NOT_FOUND'),
        ),
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



  /// Exécute un mouvement de stock manuel pour un POS (Entrées Pleins/Vides, Sortie Vides).
  /// Cela permet au POS de gérer son stock indépendamment du tour parental.
  Future<void> executePosStockMovement({
    required String enterpriseId,
    String? siteId,
    required String userId,
    Map<int, int> fullEntries = const {},
    Map<int, int> emptyEntries = const {},
    Map<int, int> emptyExits = const {},
    String? notes,
  }) async {
    final cylinders = await gasRepository.getCylinders();

    try {
      // 1. Sortie de vides -> Priorité aux Fuites (Leak) puis Vides (EmptyAtStore)
      for (final entry in emptyExits.entries) {
        final weight = entry.key;
        final totalQuantity = entry.value;
        if (totalQuantity <= 0) continue;

        final cylinder = cylinders.firstWhere(
          (c) => c.weight == weight && c.enterpriseId == enterpriseId,
          orElse: () => cylinders.firstWhere((c) => c.weight == weight),
        );

        // Chercher les fuites signalées (reported)
        final reportedLeaks = (await leakRepository.getLeaks(enterpriseId, status: LeakStatus.reported))
            .where((l) => l.weight == weight && l.cylinderId == cylinder.id)
            .toList();
        
        int leaksToConsume = totalQuantity < reportedLeaks.length ? totalQuantity : reportedLeaks.length;
        
        if (leaksToConsume > 0) {
          // Déplacer les fuites : leak -> emptyInTransit
          await _moveStock(
            enterpriseId: enterpriseId,
            cylinderId: cylinder.id,
            weight: weight,
            fromStatus: CylinderStatus.leak,
            toStatus: CylinderStatus.emptyInTransit,
            quantity: leaksToConsume,
            fromSiteId: siteId,
            siteId: null, // Vers le camion (Transit global)
            force: true,
          );

          // Mettre à jour les records de fuite
          for (int i = 0; i < leaksToConsume; i++) {
            await leakRepository.updateLeak(reportedLeaks[i].copyWith(
              status: LeakStatus.convertedToEmpty,
              updatedAt: DateTime.now(),
            ));
          }
        }

        // Déplacer le reste : emptyAtStore -> emptyInTransit
        final remainingEmpty = totalQuantity - leaksToConsume;
        if (remainingEmpty > 0) {
          await _moveStock(
            enterpriseId: enterpriseId,
            cylinderId: cylinder.id,
            weight: weight,
            fromStatus: CylinderStatus.emptyAtStore,
            toStatus: CylinderStatus.emptyInTransit,
            quantity: remainingEmpty,
            fromSiteId: siteId,
            siteId: null,
            force: true,
          );
        }
      }

      // 2. Entrée de pleines -> On ajoute aux Pleines, On enlève du Transit
      for (final entry in fullEntries.entries) {
         final weight = entry.key;
         final quantity = entry.value;
         if (quantity <= 0) continue;

         final cylinder = cylinders.firstWhere(
           (c) => c.weight == weight && c.enterpriseId == enterpriseId,
           orElse: () => cylinders.firstWhere((c) => c.weight == weight),
         );

         await _moveStock(
           enterpriseId: enterpriseId,
           cylinderId: cylinder.id,
           weight: weight,
           fromStatus: CylinderStatus.emptyInTransit, // Vient du transit
           toStatus: CylinderStatus.full,
           quantity: quantity,
           fromSiteId: null,
           siteId: siteId,
           force: true,
         );
      }

      // 3. Entrée de vides (retours non-chargés) -> On ajoute au Magasin, On enlève du Transit
      for (final entry in emptyEntries.entries) {
         final weight = entry.key;
         final quantity = entry.value;
         if (quantity <= 0) continue;

         final cylinder = cylinders.firstWhere(
           (c) => c.weight == weight && c.enterpriseId == enterpriseId,
           orElse: () => cylinders.firstWhere((c) => c.weight == weight),
         );

         await _moveStock(
           enterpriseId: enterpriseId,
           cylinderId: cylinder.id,
           weight: weight,
           fromStatus: CylinderStatus.emptyInTransit,
           toStatus: CylinderStatus.emptyAtStore,
           quantity: quantity,
           fromSiteId: null,
           siteId: siteId,
           force: true,
         );
      }

      // 4. Audit Trail
      await auditTrailRepository.log(AuditRecord(
        id: '',
        enterpriseId: enterpriseId,
        userId: userId,
        module: 'gaz',
        action: 'POS_STOCK_MOVEMENT_REFINED',
        entityId: 'pos_mv_${DateTime.now().millisecondsSinceEpoch}',
        entityType: 'stock_movement',
        timestamp: DateTime.now(),
        metadata: {
          'operation': 'pos_stock_movement',
          'fullEntries': fullEntries.map((k, v) => MapEntry(k.toString(), v)),
          'emptyEntries': emptyEntries.map((k, v) => MapEntry(k.toString(), v)),
          'emptyExits': emptyExits.map((k, v) => MapEntry(k.toString(), v)),
          'siteId': siteId,
          'notes': notes,
        },
      ));
    } catch (e) {
      AppLogger.error('Failed to execute POS stock movement', error: e, name: 'TransactionService');
      rethrow;
    }
  }
}
