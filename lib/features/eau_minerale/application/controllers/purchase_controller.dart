import '../../domain/entities/purchase.dart';
import '../../domain/entities/supplier_settlement.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../../domain/repositories/stock_repository.dart';
import '../../domain/repositories/treasury_repository.dart';
import '../../domain/repositories/finance_repository.dart';
import '../../domain/repositories/supplier_repository.dart';
import '../../domain/entities/stock_movement.dart';
import '../../domain/entities/expense_record.dart';
import '../../../../shared/domain/entities/treasury_operation.dart';
import '../../../../core/logging/app_logger.dart';

import '../controllers/stock_controller.dart';

class PurchaseController {
  PurchaseController(
    this._purchaseRepository,
    this._stockRepository,
    this._stockController,
    this._treasuryRepository,
    this._financeRepository,
    this._supplierRepository,
  );

  final PurchaseRepository _purchaseRepository;
  final StockRepository _stockRepository;
  final StockController _stockController;
  final TreasuryRepository _treasuryRepository;
  final FinanceRepository _financeRepository;
  final SupplierRepository _supplierRepository;

  Future<List<Purchase>> fetchPurchases() async {
    return await _purchaseRepository.fetchPurchases();
  }

  Stream<List<Purchase>> watchPurchases({String? supplierId}) {
    return _purchaseRepository.watchPurchases(supplierId: supplierId);
  }

  Future<String> createPurchase(Purchase purchase) async {
    try {
      final id = await _purchaseRepository.createPurchase(purchase);
      final entity = purchase.copyWith(id: id);
      
      // If validated, update stock and financial data immediately
      if (entity.status == PurchaseStatus.validated) {
        await _updateStockForPurchase(entity);
        await _updateFinancialsForPurchase(entity);
      }
      
      return id;
    } catch (e) {
      AppLogger.error('Error creating purchase', error: e);
      rethrow;
    }
  }

  Future<void> validatePurchaseOrder(String purchaseId,
      {List<PurchaseItem>? verifiedItems}) async {
    try {
      var purchase = await _purchaseRepository.getPurchase(purchaseId);
      if (purchase != null && purchase.status == PurchaseStatus.draft) {
        if (verifiedItems != null) {
          // Si les items ont changé (quantités vérifiées), mettre à jour l'entité
          final totalAmount =
              verifiedItems.fold(0, (sum, item) => sum + item.totalPrice);
          purchase = purchase.copyWith(
            items: verifiedItems,
            totalAmount: totalAmount,
          );
          await _purchaseRepository.updatePurchase(purchase);
        }

        await _purchaseRepository.validatePurchaseOrder(purchaseId);
        final validatedPurchase =
            purchase.copyWith(status: PurchaseStatus.validated);
        await _updateStockForPurchase(validatedPurchase);
        await _updateFinancialsForPurchase(validatedPurchase);
      }
    } catch (e) {
      AppLogger.error('Error validating PO', error: e);
      rethrow;
    }
  }

  Future<void> recordSupplierSettlement(SupplierSettlement settlement,
      {String? purchaseId}) async {
    try {
      final id = await _supplierRepository.recordSettlement(settlement);

      // 1. Déduire de la trésorerie
      await _treasuryRepository.createOperation(TreasuryOperation(
        id: '',
        enterpriseId: settlement.enterpriseId,
        userId: settlement.createdBy ?? 'system',
        amount: settlement.amount,
        type: TreasuryOperationType.removal,
        fromAccount: settlement.paymentMethod,
        date: settlement.date,
        reason: 'Règlement Fournisseur: ${settlement.supplierId}',
        referenceEntityId: id,
        referenceEntityType: 'supplier_settlement',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      // 2. Enregistrer la dépense
      await _financeRepository.createExpense(ExpenseRecord(
        id: '',
        enterpriseId: settlement.enterpriseId,
        label: 'Règlement Fournisseur: ${settlement.supplierId}',
        amountCfa: settlement.amount,
        date: settlement.date,
        paymentMethod: settlement.paymentMethod,
        category: ExpenseCategory.achatMatieresPremieres,
        notes: settlement.notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      // 3. Mettre à jour la balance du fournisseur
      final supplier =
          await _supplierRepository.getSupplier(settlement.supplierId);
      if (supplier != null) {
        final updatedSupplier = supplier.copyWith(
          balance: supplier.balance - settlement.amount,
          updatedAt: DateTime.now(),
        );
        await _supplierRepository.updateSupplier(updatedSupplier);
      }

      // 4. Mettre à jour l'achat spécifique si fourni (pour le suivi du reste à payer)
      if (purchaseId != null) {
        final purchase = await _purchaseRepository.getPurchase(purchaseId);
        if (purchase != null) {
          final updatedPurchase = purchase.copyWith(
            paidAmount: purchase.paidAmount + settlement.amount,
          );
          await _purchaseRepository.updatePurchase(updatedPurchase);
        }
      }
    } catch (e) {
      AppLogger.error('Error recording supplier settlement', error: e);
      rethrow;
    }
  }

  Future<void> _updateFinancialsForPurchase(Purchase purchase) async {
    try {
      // 1. Enregistrer la dépense si montant payé > 0
      if (purchase.paidAmount > 0) {
        await _financeRepository.createExpense(ExpenseRecord(
          id: '',
          enterpriseId: purchase.enterpriseId,
          label: 'Achat: ${purchase.number ?? purchase.id}',
          amountCfa: purchase.paidAmount,
          date: purchase.date,
          paymentMethod: purchase.paymentMethod,
          category: ExpenseCategory.achatMatieresPremieres,
          notes: purchase.notes,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));

        // 2. Déduire de la trésorerie
        await _treasuryRepository.createOperation(TreasuryOperation(
          id: '',
          enterpriseId: purchase.enterpriseId,
          userId: purchase.createdBy ?? 'system',
          amount: purchase.paidAmount,
          type: TreasuryOperationType.removal,
          fromAccount: purchase.paymentMethod,
          date: purchase.date,
          reason: 'Paiement Achat ${purchase.number ?? purchase.id}',
          referenceEntityId: purchase.id,
          referenceEntityType: 'purchase',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      // 3. Mettre à jour la dette fournisseur si achat à crédit
      if (purchase.supplierId != null && purchase.debtAmount > 0) {
        final supplier = await _supplierRepository.getSupplier(purchase.supplierId!);
        if (supplier != null) {
          final updatedSupplier = supplier.copyWith(
            balance: supplier.balance + purchase.debtAmount,
            updatedAt: DateTime.now(),
          );
          await _supplierRepository.updateSupplier(updatedSupplier);
        }
      }
    } catch (e) {
      AppLogger.error('Failed to update financials for purchase ${purchase.id}', error: e);
      // We don't rethrow here to avoid failing the stock/validation if only financials fail,
      // but in a real production system we might want transactionality.
    }
  }

  Future<void> _updateStockForPurchase(Purchase purchase) async {
    for (final item in purchase.items) {
      try {
        final nameLower = item.productName.toLowerCase();
        
        // Robust category matching
        if (nameLower.contains('bobine') || nameLower.contains('film') || nameLower.contains('poly')) {
          // Utiliser le contrôleur spécialisé pour les bobines
          await _stockController.recordBobineEntry(
            productId: item.productId,
            bobineType: item.productName,
            quantite: item.quantity,
            prixUnitaire: item.unitPrice,
            notes: 'Achat #${purchase.number ?? purchase.id}',
          );
        } else if (nameLower.contains('emballage') || 
                   nameLower.contains('sachet') || 
                   nameLower.contains('sac') || 
                   nameLower.contains('bouteille') ||
                   nameLower.contains('preforme') ||
                   nameLower.contains('bouchon') ||
                   nameLower.contains('bidon') ||
                   nameLower.contains('etiquette') ||
                   nameLower.contains('film')) {
          // Utiliser le contrôleur spécialisé pour les emballages
          final isInLots = item.metadata['isInLots'] as bool? ?? false;
          final quantiteSaisie = (item.metadata['quantitySaisie'] as num?)?.toDouble() ?? item.quantity.toDouble();
          final unitsPerLot = item.metadata['unitsPerLot'] as int?;

          await _stockController.recordPackagingEntry(
            packagingId: item.productId,
            packagingType: item.productName,
            quantite: quantiteSaisie,
            isInLots: isInLots,
            unitsPerLot: unitsPerLot,
            prixUnitaire: item.unitPrice,
            notes: 'Achat #${purchase.number ?? purchase.id}',
            date: purchase.date,
          );
        } else {
          // Mouvement de stock générique pour les autres produits
          await _stockRepository.recordMovement(
            StockMovement(
              id: '', 
              enterpriseId: purchase.enterpriseId,
              productName: item.productName,
              quantity: item.quantity.toDouble(),
              unit: item.unit,
              type: StockMovementType.entry,
              reason: 'Achat',
              notes: 'Achat #${purchase.number ?? purchase.id}',
              date: purchase.date,
            ),
          );
        }
      } catch (e) {
        AppLogger.error('Failed to update stock for item ${item.productName}', error: e);
      }
    }
  }
}
