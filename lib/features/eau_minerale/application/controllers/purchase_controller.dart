import '../../domain/entities/purchase.dart';
import '../../domain/entities/supplier_settlement.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../../domain/repositories/treasury_repository.dart';
import '../../domain/repositories/finance_repository.dart';
import '../../domain/repositories/supplier_repository.dart';
import '../../domain/entities/expense_record.dart';
import '../../../../shared/domain/entities/treasury_operation.dart';
import '../../../../core/logging/app_logger.dart';
import '../controllers/stock_controller.dart';

class PurchaseController {
  PurchaseController(
    this._purchaseRepository,
    this._stockController,
    this._treasuryRepository,
    this._financeRepository,
    this._supplierRepository,
  );

  final PurchaseRepository _purchaseRepository;
  final StockController _stockController;
  final TreasuryRepository _treasuryRepository;
  final FinanceRepository _financeRepository;
  final SupplierRepository _supplierRepository;

  Future<List<Purchase>> fetchPurchases() async {
    return _purchaseRepository.fetchPurchases();
  }

  Stream<List<Purchase>> watchPurchases({String? supplierId}) {
    return _purchaseRepository.watchPurchases(supplierId: supplierId);
  }

  Future<String> createPurchase(Purchase purchase) async {
    try {
      final id = await _purchaseRepository.createPurchase(purchase);
      final entity = purchase.copyWith(id: id);
      
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

      await _treasuryRepository.createOperation(TreasuryOperation(
        id: 'local_trs_settle_$id',
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

      await _financeRepository.createExpense(ExpenseRecord(
        id: 'local_exp_settle_$id',
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

      final supplier =
          await _supplierRepository.getSupplier(settlement.supplierId);
      if (supplier != null) {
        final updatedSupplier = supplier.copyWith(
          balance: supplier.balance - settlement.amount,
          updatedAt: DateTime.now(),
        );
        await _supplierRepository.updateSupplier(updatedSupplier);
      }

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
      if (purchase.paidAmount > 0) {
        await _financeRepository.createExpense(ExpenseRecord(
          id: 'local_exp_pur_${purchase.id}',
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

        await _treasuryRepository.createOperation(TreasuryOperation(
          id: 'local_trs_pur_${purchase.id}',
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
    }
  }

  Future<void> _updateStockForPurchase(Purchase purchase) async {
    for (final item in purchase.items) {
      try {
        final isLotBased = item.metadata['isLotBased'] as bool? ?? false;
        final unitsPerLot = item.metadata['unitsPerLot'] as int? ?? 1;
        final baseUnit = item.metadata['baseUnit'] as String? ?? item.unit;
        
        final stockQuantity = isLotBased ? (item.quantity * unitsPerLot).toDouble() : item.quantity.toDouble();

        // Idempotency: Use deterministic ID for stock entry
        final stockMovementId = 'local_stk_pur_item_${purchase.id}_${item.productId}';

        await _stockController.recordEntry(
          id: stockMovementId,
          productId: item.productId,
          productName: item.productName,
          quantite: stockQuantity,
          unit: baseUnit,
          raison: 'Achat (Auto)',
          notes: 'Achat #${purchase.number ?? purchase.id}${isLotBased ? " (${item.quantity} ${item.unit})" : ""}',
        );
      } catch (e) {
        AppLogger.error('Failed to update stock for item ${item.productName}', error: e);
      }
    }
  }
}

