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
  Future<({Tour tour, List<StockAlert> alerts})> executeTourClosureTransaction({
    required String tourId,
    required String userId,
    Map<int, String> weightToCylinderId = const {},
  }) async {
    final tour = await tourRepository.getTourById(tourId);
    if (tour == null) {
      throw const NotFoundException(
        'Tour introuvable',
        'TOUR_NOT_FOUND',
      );
    }

    // 1. Validation : Autorisée si reception saisie OU si distributions effectuées
    final hasDistributions = tour.wholesaleDistributions.isNotEmpty || tour.posDistributions.isNotEmpty;
    if (tour.fullBottlesReceived.isEmpty && !hasDistributions) {
      throw const ValidationException(
        'Veuillez enregistrer la réception ou les distributions avant la clôture',
        'NO_FULLS_RECEIVED',
      );
    }

    // 2. Mettre à jour le tour
    // Si la réception n'a pas été saisie manuellement, on déduit qu'on a reçu ce qu'on a chargé (Échange Standard)
    Map<int, int> fullReceived = tour.fullBottlesReceived;
    if (fullReceived.isEmpty) {
      fullReceived = tour.emptyBottlesLoaded;
    }

    final updatedTour = tour.copyWith(
      status: TourStatus.closed,
      fullBottlesReceived: fullReceived,
      closureDate: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tourRepository.updateTour(updatedTour);

    // 3. Traiter les distributions aux grossistes (Ventes + Trésorerie)
    for (final dist in tour.wholesaleDistributions) {
      if (dist.isProcessed) continue;

      final distSessionId = 'whl_${tour.id}_${dist.wholesalerId}_${DateTime.now().millisecondsSinceEpoch}';
      
      // Calculer le prix au kg pour une répartition équitable
      double totalKg = 0;
      for (final entry in dist.quantities.entries) {
        totalKg += entry.key * entry.value;
      }
      final pricePerKg = totalKg > 0 ? dist.totalAmount / totalKg : 0.0;

      for (final entry in dist.quantities.entries) {
        final weight = entry.key;
        final qty = entry.value;
        if (qty <= 0) continue;

        final cylinderId = weightToCylinderId[weight];
        if (cylinderId == null) continue;

        final unitPrice = weight * pricePerKg; // Prix proportionnel au poids

        await gasRepository.addSale(GasSale(
          id: LocalIdGenerator.generate(),
          enterpriseId: tour.enterpriseId,
          cylinderId: cylinderId,
          quantity: qty,
          unitPrice: unitPrice,
          totalAmount: unitPrice * qty,
          saleDate: DateTime.now(),
          saleType: SaleType.wholesale,
          tourId: tour.id,
          wholesalerId: dist.wholesalerId,
          wholesalerName: dist.wholesalerName,
          sellerId: userId,
          paymentMethod: dist.paymentMethod,
          sessionId: distSessionId, // Unified for history grouping
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      if (dist.totalAmount > 0) {
        await treasuryRepository.saveOperation(TreasuryOperation(
          id: LocalIdGenerator.generate(),
          enterpriseId: tour.enterpriseId,
          userId: userId,
          amount: dist.totalAmount.toInt(),
          type: TreasuryOperationType.supply,
          toAccount: dist.paymentMethod,
          date: DateTime.now(),
          reason: 'Vente en Gros : ${dist.wholesalerName} (Tour ${tour.id})',
          referenceEntityId: tour.id,
          referenceEntityType: 'tour_wholesaler_sale',
          createdAt: DateTime.now(),
        ));
      }
    }

    // 4. Traiter les distributions aux POS (Mise à jour stock info / Audit)
    for (final posDist in tour.posDistributions) {
       await auditTrailRepository.log(AuditRecord(
        id: '',
        enterpriseId: updatedTour.enterpriseId,
        userId: userId,
        module: 'gaz',
        action: 'POS_DISTRIBUTION',
        entityId: updatedTour.id,
        entityType: 'tour',
        timestamp: DateTime.now(),
        metadata: {
          'posId': posDist.posId,
          'posName': posDist.posName,
          'quantities': posDist.quantities.map((k, v) => MapEntry(k.toString(), v)),
          'receivedDate': posDist.receivedDate?.toIso8601String(),
        },
      ));
    }

    // 5. Audit Log Global
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
        'loadingSources': updatedTour.loadingSources.map((s) => s.toMap()).toList(),
        'wholesaleDistributions': tour.wholesaleDistributions.map((d) => d.toMap()).toList(),
        'posDistributions': tour.posDistributions.map((d) => d.toMap()).toList(),
        'fullBottlesReceived': updatedTour.fullBottlesReceived
            .map((k, v) => MapEntry(k.toString(), v)),
        'emptyBottlesReturned': updatedTour.emptyBottlesReturned
            .map((k, v) => MapEntry(k.toString(), v)),
        'totalExchangeFees': updatedTour.totalExchangeFees,
      },
    ));

    // 6. Enregistrement de l'impact financier (Dépenses)
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
          'exchangeFees': updatedTour.totalExchangeFees,
          'gasPurchaseCost': updatedTour.totalGasPurchaseCost,
          'purchasePricesUsed': updatedTour.purchasePricesUsed
              .map((k, v) => MapEntry(k.toString(), v)),
          'tourDate': updatedTour.tourDate.toIso8601String(),
        },
      ));
    }

    AppLogger.info(
      'TourClosure: Clôture réussie du tour ${updatedTour.id}. '
      'Vides chargées: ${updatedTour.totalBottlesToLoad}, '
      'Pleines reçues: ${updatedTour.totalBottlesReceived}, '
      'Distributions grossistes: ${tour.wholesaleDistributions.length}',
      name: 'transaction.tour_closure',
    );

    return (tour: updatedTour, alerts: const <StockAlert>[]);
  }

  /// Exécute l'encaissement d'un grossiste individuellement lors de Step 3.
  Future<void> executeWholesaleCollection({
    required String tourId,
    required String wholesalerId,
    required String userId,
    required Map<int, String> weightToCylinderId,
  }) async {
    final tour = await tourRepository.getTourById(tourId);
    if (tour == null) throw const NotFoundException('Tour introuvable', 'TOUR_NOT_FOUND');

    final distIndex = tour.wholesaleDistributions.indexWhere((d) => d.wholesalerId == wholesalerId);
    if (distIndex == -1) throw const NotFoundException('Distribution grossiste introuvable', 'DISTRIBUTION_NOT_FOUND');

    final dist = tour.wholesaleDistributions[distIndex];
    if (dist.isProcessed) return; // Déjà encaissé

    final distSessionId = 'whl_${tour.id}_${dist.wholesalerId}_${DateTime.now().millisecondsSinceEpoch}';

    // 1. Enregistrer les ventes avec prix proportionnel au poids
    double totalKg = 0;
    for (final entry in dist.quantities.entries) {
      totalKg += entry.key * entry.value;
    }
    final pricePerKg = totalKg > 0 ? dist.totalAmount / totalKg : 0.0;

    for (final entry in dist.quantities.entries) {
      final weight = entry.key;
      final qty = entry.value;
      if (qty <= 0) continue;

      final cylinderId = weightToCylinderId[weight];
      if (cylinderId == null) continue;

      final unitPrice = weight * pricePerKg;

      await gasRepository.addSale(GasSale(
        id: LocalIdGenerator.generate(),
        enterpriseId: tour.enterpriseId,
        cylinderId: cylinderId,
        quantity: qty,
        unitPrice: unitPrice,
        totalAmount: unitPrice * qty,
        saleDate: DateTime.now(),
        saleType: SaleType.wholesale,
        tourId: tour.id,
        wholesalerId: dist.wholesalerId,
        wholesalerName: dist.wholesalerName,
        sellerId: userId,
        paymentMethod: dist.paymentMethod,
        sessionId: distSessionId, // Unified for history grouping
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }

    // 2. Enregistrer l'opération de trésorerie
    if (dist.totalAmount > 0) {
      await treasuryRepository.saveOperation(TreasuryOperation(
        id: LocalIdGenerator.generate(),
        enterpriseId: tour.enterpriseId,
        userId: userId,
        amount: dist.totalAmount.toInt(),
        type: TreasuryOperationType.supply,
        toAccount: dist.paymentMethod,
        date: DateTime.now(),
        reason: 'Encaissement Grossiste : ${dist.wholesalerName} (Tour ${tour.id})',
        referenceEntityId: tour.id,
        referenceEntityType: 'tour_wholesaler_sale',
        createdAt: DateTime.now(),
      ));
    }

    // 3. Marquer comme traité dans le tour
    final updatedDistributions = List<WholesaleDistribution>.from(tour.wholesaleDistributions);
    updatedDistributions[distIndex] = dist.copyWith(isProcessed: true);

    await tourRepository.updateTour(tour.copyWith(
      wholesaleDistributions: updatedDistributions,
      updatedAt: DateTime.now(),
    ));

    // 4. Audit Log
    await auditTrailRepository.log(AuditRecord(
      id: '',
      enterpriseId: tour.enterpriseId,
      userId: userId,
      module: 'gaz',
      action: 'WHOLESALE_COLLECTION',
      entityId: tour.id,
      entityType: 'tour',
      timestamp: DateTime.now(),
      metadata: {
        'wholesalerId': wholesalerId,
        'wholesalerName': dist.wholesalerName,
        'amount': dist.totalAmount,
        'paymentMethod': dist.paymentMethod.name,
      },
    ));
  }

  /// Met à jour les sources de chargement d'un tour.
  Future<void> executeTourLoadingTransaction({
    required String tourId,
    required String userId,
    required List<TourLoadingSource> loadingSources,
  }) async {
    final tour = await tourRepository.getTourById(tourId);
    if (tour == null) throw const NotFoundException('Tour introuvable', 'TOUR_NOT_FOUND');

    final oldLoadingSources = tour.loadingSources;

    // Agréger les chargements par poids pour la compatibilité descendante
    final aggregatedLoading = <int, int>{};
    for (final source in loadingSources) {
      for (final entry in source.quantities.entries) {
        aggregatedLoading[entry.key] = (aggregatedLoading[entry.key] ?? 0) + entry.value;
      }
    }

    // Mettre à jour le tour (Purement déclaratif)
    await tourRepository.updateTour(tour.copyWith(
      loadingSources: loadingSources,
      emptyBottlesLoaded: aggregatedLoading,
      updatedAt: DateTime.now(),
    ));

    // Audit Trail
    await auditTrailRepository.log(AuditRecord(
      id: '',
      enterpriseId: tour.enterpriseId,
      userId: userId,
      module: 'gaz',
      action: 'TOUR_LOADING_UPDATE',
      entityId: tour.id,
      entityType: 'tour',
      timestamp: DateTime.now(),
      metadata: {
        'oldLoadingSources': oldLoadingSources.map((s) => s.toMap()).toList(),
        'newLoadingSources': loadingSources.map((s) => s.toMap()).toList(),
      },
    ));
  }

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

  /// Helper pour déplacer du stock entre deux statuts.
  Future<void> _moveStock({
    required String enterpriseId,
    required String cylinderId,
    required int weight,
    required CylinderStatus fromStatus,
    required CylinderStatus toStatus,
    required int quantity,
    String? siteId,
  }) async {
    if (quantity <= 0) return;

    final stocks = await stockRepository.getStocksByWeight(enterpriseId, weight, siteId: siteId);
    
    // Décrémenter Source
    final sourceStocks = stocks.where((s) => s.status == fromStatus && s.cylinderId == cylinderId).toList();
    final totalSource = sourceStocks.fold<int>(0, (sum, s) => sum + s.quantity);
    
    if (totalSource < quantity) {
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

    // Incrémenter Destination
    final destStock = stocks.where((s) => s.status == toStatus && s.cylinderId == cylinderId).firstOrNull;
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




  /// Déclare une fuite de manière atomique et la convertit immédiatement en vide.
  /// 
  /// Étapes :
  /// 1. Décrémente le stock plein
  /// 2. Incrémente le stock "Vide au magasin"
  /// 3. Enregistre la fuite comme "Trace" (convertedToEmpty)
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

    // 2. Incrémenter stock vide au magasin
    final emptyStock = fullStocks.where((s) => s.status == CylinderStatus.emptyAtStore && s.cylinderId == leak.cylinderId).firstOrNull 
      ?? CylinderStock(
          id: LocalIdGenerator.generate(),
          cylinderId: leak.cylinderId,
          weight: leak.weight,
          status: CylinderStatus.emptyAtStore,
          quantity: 0,
          enterpriseId: leak.enterpriseId,
          updatedAt: DateTime.now(),
        );

    await stockRepository.updateStock(emptyStock.copyWith(
      quantity: emptyStock.quantity + 1,
      updatedAt: DateTime.now(),
    ));

    // 3. Enregistrer la trace de la fuite (Directement comme convertie)
    await leakRepository.reportLeak(leak.copyWith(status: LeakStatus.convertedToEmpty));

    // 4. Audit Trail
    await auditTrailRepository.log(AuditRecord(
      id: '',
      enterpriseId: leak.enterpriseId,
      userId: userId,
      module: 'gaz',
      action: 'LEAK_DECLARATION_AND_CONVERSION',
      entityId: leak.id,
      entityType: 'leak',
      timestamp: DateTime.now(),
      metadata: {
        ...leak.toMap(),
        'operation': 'leak',
        'movements': [
          {'cylinderId': leak.cylinderId, 'weight': leak.weight, 'status': 'full', 'delta': -1},
          {'cylinderId': leak.cylinderId, 'weight': leak.weight, 'status': 'emptyAtStore', 'delta': 1},
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

    Future<void> processMovement(Map<int, int> quantities, CylinderStatus status, bool isAddition) async {
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

        final existingStocks = await stockRepository.getStocksByWeight(
           enterpriseId, 
           weight, 
           siteId: siteId,
        );
        final targetStock = existingStocks
            .where((s) => s.status == status && s.cylinderId == cylinder.id)
            .firstOrNull;

        if (isAddition) {
          if (targetStock != null) {
            await stockRepository.updateStockQuantity(targetStock.id, targetStock.quantity + quantity);
          } else {
            await stockRepository.addStock(CylinderStock(
              id: LocalIdGenerator.generate(),
              cylinderId: cylinder.id,
              weight: weight,
              status: status,
              quantity: quantity,
              enterpriseId: enterpriseId,
              siteId: siteId,
              updatedAt: DateTime.now(),
              createdAt: DateTime.now(),
            ));
          }
        } else {
          // Prevention of negative stock for removals
          if (targetStock != null) {
            final newQuantity = (targetStock.quantity - quantity).clamp(0, double.infinity).toInt();
            await stockRepository.updateStockQuantity(targetStock.id, newQuantity);
          } else {
            // If no stock record exists, we don't create a negative one
            // We just create a 0 stock record if it's strictly necessary, but usually we just skip.
            // For audit consistency, let's just do nothing if targetStock is null and we are removing.
          }
        }
      }
    }

    try {
      // 1. Process all movements
      
      // Sortie de vides -> On enlève du Magasin, On met en Transit
      await processMovement(emptyExits, CylinderStatus.emptyAtStore, false);
      await processMovement(emptyExits, CylinderStatus.emptyInTransit, true);

      // Entrée de pleines -> On ajoute aux Pleines, On enlève du Transit
      await processMovement(fullEntries, CylinderStatus.full, true);
      await processMovement(fullEntries, CylinderStatus.emptyInTransit, false);

      // Entrée de vides (retours non-chargés) -> On ajoute au Magasin, On enlève du Transit
      await processMovement(emptyEntries, CylinderStatus.emptyAtStore, true);
      await processMovement(emptyEntries, CylinderStatus.emptyInTransit, false);

      // 2. Audit Trail
      await auditTrailRepository.log(AuditRecord(
        id: '',
        enterpriseId: enterpriseId,
        userId: userId,
        module: 'gaz',
        action: 'POS_STOCK_MOVEMENT',
        entityId: 'pos_movement_${DateTime.now().millisecondsSinceEpoch}',
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
