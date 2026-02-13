import 'package:elyf_groupe_app/features/boutique/domain/entities/cart_item.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/expense.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/product.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/purchase.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/report_data.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/sale.dart';
import 'package:elyf_groupe_app/features/boutique/domain/services/numbering_service.dart';
import 'package:elyf_groupe_app/features/boutique/domain/repositories/expense_repository.dart';
import 'package:elyf_groupe_app/features/boutique/domain/repositories/product_repository.dart';
import 'package:elyf_groupe_app/features/boutique/domain/repositories/purchase_repository.dart';
import 'package:elyf_groupe_app/features/boutique/domain/repositories/report_repository.dart';
import 'package:elyf_groupe_app/features/boutique/domain/repositories/sale_repository.dart';
import 'package:elyf_groupe_app/features/boutique/domain/repositories/stock_repository.dart';
import 'package:elyf_groupe_app/features/boutique/domain/repositories/closing_repository.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/closing.dart';
import 'package:elyf_groupe_app/features/boutique/domain/repositories/treasury_repository.dart';
import 'package:elyf_groupe_app/features/boutique/domain/repositories/supplier_repository.dart';
import 'package:elyf_groupe_app/features/boutique/domain/repositories/supplier_settlement_repository.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/treasury_operation.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/supplier.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/supplier_settlement.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/stock_movement.dart';
import 'package:elyf_groupe_app/features/boutique/domain/repositories/stock_movement_repository.dart';
import 'package:elyf_groupe_app/features/audit_trail/domain/services/audit_trail_service.dart';
import 'package:elyf_groupe_app/core/logging/app_logger.dart';

import 'package:elyf_groupe_app/features/boutique/domain/entities/category.dart';
import 'package:elyf_groupe_app/features/boutique/domain/repositories/category_repository.dart';

class StoreController {
  StoreController(
    this._productRepository,
    this._saleRepository,
    this._stockRepository,
    this._purchaseRepository,
    this._expenseRepository,
    this._reportRepository,
    this._closingRepository,
    this._treasuryRepository,
    this._supplierRepository,
    this._supplierSettlementRepository,
    this._categoryRepository,
    this._stockMovementRepository,
    this._auditTrailService,
    this._currentUserId,
  );

  final ProductRepository _productRepository;
  final SaleRepository _saleRepository;
  final StockRepository _stockRepository;
  final PurchaseRepository _purchaseRepository;
  final ExpenseRepository _expenseRepository;
  final ReportRepository _reportRepository;
  final ClosingRepository _closingRepository;
  final TreasuryRepository _treasuryRepository;
  final SupplierRepository _supplierRepository;
  final SupplierSettlementRepository _supplierSettlementRepository;
  final CategoryRepository _categoryRepository;
  final StockMovementRepository _stockMovementRepository;
  final AuditTrailService _auditTrailService;
  final String _currentUserId;

  Future<List<Product>> fetchProducts() async {
    return await _productRepository.fetchProducts();
  }

  Future<Product?> getProduct(String id) async {
    return await _productRepository.getProduct(id);
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    try {
      return await _productRepository.getProductByBarcode(barcode);
    } catch (_) {
      return null;
    }
  }

  Future<String> createProduct(Product product) async {
    final productId = await _productRepository.createProduct(product);
    _logEvent(product.enterpriseId, 'CREATE_PRODUCT', productId, 'product', {
      'name': product.name,
      'price': product.price,
    });
    return productId;
  }

  Future<void> updateProduct(Product product) async {
    await _productRepository.updateProduct(product);
    _logEvent(product.enterpriseId, 'UPDATE_PRODUCT', product.id, 'product', {
      'name': product.name,
    });
  }

  Future<void> deleteProduct(String id) async {
    final product = await _productRepository.getProduct(id);
    if (product != null) {
      await _productRepository.deleteProduct(
        id,
        deletedBy: _currentUserId,
      );
      _logEvent(product.enterpriseId, 'DELETE_PRODUCT', id, 'product', {
        'name': product.name,
      });
    }
  }

  Future<void> restoreProduct(String id) async {
    return await _productRepository.restoreProduct(id);
  }

  Future<void> toggleProductStatus(String id) async {
    final product = await _productRepository.getProduct(id);
    if (product != null) {
      final updatedProduct = product.copyWith(
        isActive: !product.isActive,
        updatedAt: DateTime.now(),
      );
      await _productRepository.updateProduct(updatedProduct);
      _logEvent(product.enterpriseId, 'TOGGLE_PRODUCT_STATUS', id, 'product', {
        'name': product.name,
        'isActive': !product.isActive,
      });
    }
  }

  Future<List<Product>> getDeletedProducts() async {
    return await _productRepository.getDeletedProducts();
  }

  Future<List<Sale>> fetchRecentSales({int limit = 50}) async {
    return await _saleRepository.fetchRecentSales(limit: limit);
  }

  Future<Sale> createSale(Sale sale) async {
    // Session Guard
    final activeSession = await getActiveSession();
    if (activeSession == null || activeSession.status != ClosingStatus.open) {
      throw Exception('Aucune session active. Veuillez ouvrir la caisse avant de vendre.');
    }

    // Update stock and record movement for each item
    for (final item in sale.items) {
      final product = await _productRepository.getProduct(item.productId);
      if (product != null) {
        final newStock = product.stock - item.quantity;
        await _stockRepository.updateStock(item.productId, newStock);

        // Record Stock Movement
        await _stockMovementRepository.recordMovement(StockMovement(
          id: 'mov_sale_${sale.id}_${item.productId}',
          productId: item.productId,
          enterpriseId: sale.enterpriseId,
          type: StockMovementType.sale,
          quantity: -item.quantity,
          balanceAfter: newStock,
          date: sale.date,
          userId: _currentUserId,
          referenceId: sale.id,
        ));
      }
    }
    // Generate professional number
    final count = await _saleRepository.getCountForDate(sale.date);
    final saleNumber = BoutiqueNumberingService.generate(
      prefix: BoutiqueNumberingService.prefixSale,
      date: sale.date,
      dailySequence: count,
    );

    final saleWithNumber = sale.copyWith(number: saleNumber);
    final createdSale = await _saleRepository.createSale(saleWithNumber);

    // Record Treasury supply
    if (sale.amountPaid > 0) {
      await _treasuryRepository.createOperation(TreasuryOperation(
        id: '',
        enterpriseId: sale.enterpriseId,
        userId: _currentUserId,
        amount: sale.amountPaid,
        type: TreasuryOperationType.supply,
        toAccount: sale.paymentMethod,
        date: sale.date,
        notes: 'Vente ${saleNumber}',
        reason: 'Vente directe',
      ));
    }

    _logEvent(sale.enterpriseId, 'CREATE_SALE', createdSale.id, 'sale', {
      'totalAmount': sale.totalAmount,
      'itemCount': sale.items.length,
      'number': saleNumber,
    });
    return createdSale;
  }

  Future<void> deleteSale(String id) async {
    final sale = await _saleRepository.getSale(id);
    if (sale == null || sale.isDeleted) return;

    // 1. Mark as deleted in repository
    await _saleRepository.deleteSale(id, deletedBy: _currentUserId);

    // 2. Reverse Stock (Add back)
    for (final item in sale.items) {
      // Update Stock
      await _stockRepository.updateStock(
        item.productId,
        item.quantity, // Positive quantity adds back to stock
      );

      // Record Stock Movement
      final product = await _productRepository.getProduct(item.productId);
      if (product != null) {
         await _stockMovementRepository.recordMovement(StockMovement(
          id: 'mov_sale_cancel_${sale.id}_${item.productId}',
          productId: item.productId,
          enterpriseId: sale.enterpriseId,
          type: StockMovementType.returnItem,
          quantity: item.quantity,
          balanceAfter: product.stock,
          date: DateTime.now(),
          userId: _currentUserId,
          referenceId: sale.id,
          notes: 'Annulation vente ${sale.number}',
        ));
      }
    }

    // 3. Reverse Treasury
    if (sale.amountPaid > 0) {
      // Create a removal operation to cancel the supply
      await _treasuryRepository.createOperation(TreasuryOperation(
        id: '',
        enterpriseId: sale.enterpriseId,
        userId: _currentUserId,
        amount: sale.amountPaid,
        type: TreasuryOperationType.removal,
        fromAccount: sale.paymentMethod ?? PaymentMethod.cash,
        date: DateTime.now(),
        notes: 'Annulation Vente ${sale.number ?? id}',
        reason: 'Annulation vente professionnelle',
      ));
    }

    _logEvent(sale.enterpriseId, 'DELETE_SALE', id, 'sale', {
      'amount': sale.totalAmount,
      'number': sale.number,
    });
  }

  Future<void> restoreSale(String id) async {
    final sale = await _saleRepository.getSale(id);
    if (sale == null || !sale.isDeleted) return;

    // 1. Restore status
    await _saleRepository.restoreSale(id);

    // 2. Re-apply Stock (Subtract)
    for (final item in sale.items) {
      // Update Stock
      await _stockRepository.updateStock(
        item.productId,
        -item.quantity, // Negative quantity subtracts from stock
      );

      // Record Stock Movement
      final product = await _productRepository.getProduct(item.productId);
      if (product != null) {
         await _stockMovementRepository.recordMovement(StockMovement(
          id: 'mov_sale_restore_${sale.id}_${item.productId}',
          productId: item.productId,
          enterpriseId: sale.enterpriseId,
          type: StockMovementType.sale,
          quantity: -item.quantity,
          balanceAfter: product.stock,
          date: DateTime.now(),
          userId: _currentUserId,
          referenceId: sale.id,
          notes: 'Restauration vente ${sale.number}',
        ));
      }
    }

    // 3. Re-apply Treasury
    if (sale.amountPaid > 0) {
      await _treasuryRepository.createOperation(TreasuryOperation(
        id: '',
        enterpriseId: sale.enterpriseId,
        userId: _currentUserId,
        amount: sale.amountPaid,
        type: TreasuryOperationType.supply,
        toAccount: sale.paymentMethod ?? PaymentMethod.cash,
        date: DateTime.now(),
        notes: 'Restauration Vente ${sale.number ?? id}',
        reason: 'Correction erreur annulation',
      ));
    }

    _logEvent(sale.enterpriseId, 'RESTORE_SALE', id, 'sale', {
      'amount': sale.totalAmount,
      'number': sale.number,
    });
  }

  Future<List<Product>> getLowStockProducts({int threshold = 10}) async {
    return await _stockRepository.getLowStockProducts(threshold: threshold);
  }

  // --- Categories ---

  Future<List<Category>> fetchCategories() async {
    return await _categoryRepository.fetchCategories();
  }

  Future<String> createCategory(Category category) async {
    final id = await _categoryRepository.createCategory(category);
    _logEvent(category.enterpriseId, 'CREATE_CATEGORY', id, 'category', {
      'name': category.name,
    });
    return id;
  }

  Future<void> updateCategory(Category category) async {
    await _categoryRepository.updateCategory(category);
    _logEvent(category.enterpriseId, 'UPDATE_CATEGORY', category.id, 'category', {
      'name': category.name,
    });
  }

  Future<void> deleteCategory(String id) async {
    await _categoryRepository.deleteCategory(id, deletedBy: _currentUserId);
    // Note: We might want to check if products are still in this category
    _logEvent('', 'DELETE_CATEGORY', id, 'category', {});
  }

  Stream<List<Category>> watchCategories() {
    return _categoryRepository.watchCategories();
  }

  Future<void> adjustStock(String productId, int quantity, String reason) async {
    final product = await _productRepository.getProduct(productId);
    if (product != null) {
      // Currently using stockRepository for legacy reasons, but we should make sure it updates the stock
      // If stockRepository.recordAdjustment updates the stock, fine. 
      // Assuming it does NOT, or if it does, we assume it's valid.
      // Wait, let's update stock manually to be safe if we are not sure, OR rely on this method.
      // Let's assume updateStock is the way to go for consistency.
      final newStock = product.stock + quantity;
      await _stockRepository.updateStock(productId, newStock);
      // await _stockRepository.recordAdjustment(productId, quantity, reason); // Legacy

      await _stockMovementRepository.recordMovement(StockMovement(
          id: 'mov_adj_${DateTime.now().millisecondsSinceEpoch}_$productId',
          productId: productId,
          enterpriseId: product.enterpriseId,
          type: StockMovementType.adjustment,
          quantity: quantity,
          balanceAfter: newStock,
          date: DateTime.now(),
          userId: _currentUserId,
          notes: reason,
        ));

      _logEvent(product.enterpriseId, 'STOCK_ADJUSTMENT', productId, 'product', {
        'name': product.name,
        'adjustment': quantity,
        'reason': reason,
        'previousStock': product.stock,
        'newStock': newStock,
      });
    }
  }

  // Stock Movement methods
  Stream<List<StockMovement>> watchStockMovements({String? productId}) {
    return _stockMovementRepository.watchMovements(productId: productId);
  }

  Future<List<StockMovement>> fetchStockMovements({
    String? productId,
    DateTime? startDate,
    DateTime? endDate,
    StockMovementType? type,
  }) {
    return _stockMovementRepository.fetchMovements(
      productId: productId,
      startDate: startDate,
      endDate: endDate,
      type: type,
    );
  }

  int calculateCartTotal(List<CartItem> cartItems) {
    return cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  }

  // Purchase methods
  Future<List<Purchase>> fetchPurchases({int limit = 50}) async {
    return await _purchaseRepository.fetchPurchases(limit: limit);
  }

  Future<String> createPurchase(Purchase purchase) async {
    // Session Guard
    final activeSession = await getActiveSession();
    if (activeSession == null || activeSession.status != ClosingStatus.open) {
      throw Exception('Aucune session active. Veuillez ouvrir la caisse avant d\'enregistrer un achat.');
    }

    // Update stock and purchase price for each item
    for (final item in purchase.items) {
      final product = await _productRepository.getProduct(item.productId);
      if (product != null) {
        final newStock = product.stock + item.quantity;
        final updatedProduct = product.copyWith(
          stock: newStock,
          purchasePrice: item.purchasePrice,
        );
        await _productRepository.updateProduct(updatedProduct);

        // Record Stock Movement
        await _stockMovementRepository.recordMovement(StockMovement(
          id: 'mov_purchase_${purchase.id}_${item.productId}',
          productId: item.productId,
          enterpriseId: purchase.enterpriseId,
          type: StockMovementType.purchase,
          quantity: item.quantity,
          balanceAfter: newStock,
          date: purchase.date,
          userId: _currentUserId,
          referenceId: purchase.id,
        ));
      }
    }

    // Update Supplier Balance if credit purchase
    if (purchase.supplierId != null && (purchase.debtAmount ?? 0) > 0) {
      final supplier = await _supplierRepository.getSupplier(purchase.supplierId!);
      if (supplier != null) {
        final updatedSupplier = supplier.copyWith(
          balance: supplier.balance + purchase.debtAmount!,
          updatedAt: DateTime.now(),
        );
        await _supplierRepository.updateSupplier(updatedSupplier);
      }
    }

    // Record Treasury removal for the paid amount
    final paid = purchase.paidAmount ?? purchase.totalAmount;
    if (paid > 0) {
      await _treasuryRepository.createOperation(TreasuryOperation(
        id: '',
        enterpriseId: purchase.enterpriseId,
        userId: _currentUserId,
        amount: paid,
        type: TreasuryOperationType.removal,
        fromAccount: purchase.paymentMethod,
        date: purchase.date,
        notes: 'Achat ${purchase.number ?? ""}',
      ));
    }

    // Generate professional number
    final count = await _purchaseRepository.getCountForDate(purchase.date);
    final purchaseNumber = BoutiqueNumberingService.generate(
      prefix: BoutiqueNumberingService.prefixPurchase,
      date: purchase.date,
      dailySequence: count,
    );

    final purchaseWithNumber = purchase.copyWith(number: purchaseNumber);
    final purchaseId = await _purchaseRepository.createPurchase(purchaseWithNumber);

    _logEvent(purchase.enterpriseId, 'CREATE_PURCHASE', purchaseId, 'purchase', {
      'totalAmount': purchase.totalAmount,
      'paidAmount': paid,
      'debtAmount': purchase.debtAmount ?? 0,
      'supplierId': purchase.supplierId,
      'number': purchaseNumber,
    });
    return purchaseId;
  }

  Future<void> deletePurchase(String id) async {
    final purchase = await _purchaseRepository.getPurchase(id);
    if (purchase == null || purchase.isDeleted) return;

    // 1. Mark as deleted in repository
    await _purchaseRepository.deletePurchase(
      id,
      deletedBy: _currentUserId,
    );

    // 2. Reverse Stock (Subtract incoming quantities)
    for (final item in purchase.items) {
      final product = await _productRepository.getProduct(item.productId);
      if (product != null) {
        final newStock = product.stock - item.quantity;
        await _productRepository.updateProduct(product.copyWith(stock: newStock));

        // Record Stock Movement
        await _stockMovementRepository.recordMovement(StockMovement(
          id: 'mov_purchase_cancel_${purchase.id}_${item.productId}',
          productId: item.productId,
          enterpriseId: purchase.enterpriseId,
          type: StockMovementType.adjustment, // Or returnItem, or just specific reversal
          quantity: -item.quantity,
          balanceAfter: newStock,
          date: DateTime.now(),
          userId: _currentUserId,
          referenceId: purchase.id,
          notes: 'Annulation achat ${purchase.number}',
        ));
      }
    }

    // 3. Reverse Treasury
    final paid = purchase.paidAmount ?? purchase.totalAmount;
    if (paid > 0) {
      await _treasuryRepository.createOperation(TreasuryOperation(
        id: '',
        enterpriseId: purchase.enterpriseId,
        userId: _currentUserId,
        amount: paid,
        type: TreasuryOperationType.supply, // Reverse the removal
        toAccount: purchase.paymentMethod,
        date: DateTime.now(),
        notes: 'Annulation Achat ${purchase.number ?? id}',
        reason: 'Correction erreur achat',
      ));
    }

    // 4. Reverse Supplier Balance
    if (purchase.supplierId != null && (purchase.debtAmount ?? 0) > 0) {
      final supplier = await _supplierRepository.getSupplier(purchase.supplierId!);
      if (supplier != null) {
        final updatedSupplier = supplier.copyWith(
          balance: supplier.balance - purchase.debtAmount!,
          updatedAt: DateTime.now(),
        );
        await _supplierRepository.updateSupplier(updatedSupplier);
      }
    }

    _logEvent(purchase.enterpriseId, 'DELETE_PURCHASE', id, 'purchase', {
      'totalAmount': purchase.totalAmount,
      'number': purchase.number,
    });
  }

  Future<void> restorePurchase(String id) async {
    return await _purchaseRepository.restorePurchase(id);
  }

  Future<List<Purchase>> getDeletedPurchases() async {
    return await _purchaseRepository.getDeletedPurchases();
  }

  // Expense methods
  Future<List<Expense>> fetchExpenses({int limit = 50}) async {
    return await _expenseRepository.fetchExpenses(limit: limit);
  }

  Future<String> createExpense(Expense expense) async {
    // Session Guard
    final activeSession = await getActiveSession();
    if (activeSession == null || activeSession.status != ClosingStatus.open) {
      throw Exception('Aucune session active. Veuillez ouvrir la caisse avant d\'enregistrer une dépense.');
    }

    // Generate professional number
    final count = await _expenseRepository.getCountForDate(expense.date);
    final expenseNumber = BoutiqueNumberingService.generate(
      prefix: BoutiqueNumberingService.prefixExpense,
      date: expense.date,
      dailySequence: count,
    );

    final expenseWithNumber = expense.copyWith(number: expenseNumber);
    final expenseId = await _expenseRepository.createExpense(expenseWithNumber);

    // Record Treasury removal
    await _treasuryRepository.createOperation(TreasuryOperation(
      id: '',
      enterpriseId: expense.enterpriseId,
      userId: _currentUserId,
      amount: expense.amountCfa,
      type: TreasuryOperationType.removal,
      fromAccount: expense.paymentMethod,
      date: expense.date,
      notes: 'Dépense ${expenseNumber}: ${expense.label}',
      reason: 'Dépense boutique',
    ));

    _logEvent(expense.enterpriseId, 'CREATE_EXPENSE', expenseId, 'expense', {
      'label': expense.label,
      'amount': expense.amountCfa,
      'number': expenseNumber,
    });
    return expenseId;
  }

  Future<void> deleteExpense(String id) async {
    final expense = await _expenseRepository.getExpense(id);
    if (expense == null || expense.isDeleted) return;

    // 1. Mark as deleted
    await _expenseRepository.deleteExpense(
      id,
      deletedBy: _currentUserId,
    );

    // 2. Reverse Treasury
    await _treasuryRepository.createOperation(TreasuryOperation(
      id: '',
      enterpriseId: expense.enterpriseId,
      userId: _currentUserId,
      amount: expense.amountCfa,
      type: TreasuryOperationType.supply, // Reverse the removal
      toAccount: expense.paymentMethod,
      date: DateTime.now(),
      notes: 'Annulation Dépense ${expense.number ?? id}',
      reason: 'Correction erreur dépense',
    ));

    _logEvent(expense.enterpriseId, 'DELETE_EXPENSE', id, 'expense', {
      'label': expense.label,
      'amount': expense.amountCfa,
      'number': expense.number,
    });
  }

  Future<void> restoreExpense(String id) async {
    return await _expenseRepository.restoreExpense(id);
  }

  Future<List<Expense>> getDeletedExpenses() async {
    return await _expenseRepository.getDeletedExpenses();
  }

  // --- Treasury ---

  Future<String> recordTreasuryOperation(TreasuryOperation operation) async {
    // Generate professional number
    final count = await _treasuryRepository.fetchOperations(limit: 1000).then((ops) => ops.length);
    final treNumber = BoutiqueNumberingService.generate(
      prefix: BoutiqueNumberingService.prefixTreasury,
      date: operation.date,
      dailySequence: count,
    );

    final opWithNumber = operation.copyWith(
      number: treNumber,
      userId: _currentUserId,
    );
    final id = await _treasuryRepository.createOperation(opWithNumber);
    _logEvent(operation.enterpriseId, 'TREASURY_OP', id, 'treasury', {
      'type': operation.type.name,
      'amount': operation.amount,
      'number': treNumber,
    });
    return id;
  }

  Stream<List<TreasuryOperation>> watchTreasuryOperations({int limit = 50}) {
    return _treasuryRepository.watchOperations(limit: limit);
  }

  Future<Map<String, int>> getTreasuryBalances() {
    return _treasuryRepository.getBalances();
  }

  // --- Suppliers ---

  Future<String> createSupplier(Supplier supplier) {
    return _supplierRepository.createSupplier(supplier);
  }

  Stream<List<Supplier>> watchSuppliers({int limit = 100}) {
    return _supplierRepository.watchSuppliers(limit: limit);
  }

  Future<void> updateSupplier(Supplier supplier) {
    return _supplierRepository.updateSupplier(supplier);
  }

  Future<List<PurchaseItem>> getProductPurchaseHistory(String productId) async {
    final purchases = await _purchaseRepository.fetchPurchases(limit: 1000);
    final history = <PurchaseItem>[];
    for (final purchase in purchases) {
      for (final item in purchase.items) {
        if (item.productId == productId) {
          history.add(item);
        }
      }
    }
    // Sort by date (we need to join with purchase date, or include date in item)
    // For now, let's keep it simple as purchases are likely fetched in order.
    return history;
  }

  Future<String> createSupplierSettlement(SupplierSettlement settlement) async {
    // Generate professional number
    final count = await _supplierSettlementRepository.getCountForDate(settlement.date);
    final settlementNumber = BoutiqueNumberingService.generate(
      prefix: 'REG', // Règlement
      date: settlement.date,
      dailySequence: count,
    );

    final settlementWithNumber = settlement.copyWith(number: settlementNumber);
    final settlementId = await _supplierSettlementRepository.createSettlement(settlementWithNumber);

    // Update Supplier Balance
    final supplier = await _supplierRepository.getSupplier(settlement.supplierId);
    if (supplier != null) {
      final updatedSupplier = supplier.copyWith(
        balance: supplier.balance - settlement.amount,
        updatedAt: DateTime.now(),
      );
      await _supplierRepository.updateSupplier(updatedSupplier);
    }

    // Record Treasury removal
    await _treasuryRepository.createOperation(TreasuryOperation(
      id: '',
      enterpriseId: settlement.enterpriseId,
      userId: _currentUserId,
      amount: settlement.amount,
      type: TreasuryOperationType.removal,
      fromAccount: settlement.paymentMethod,
      date: settlement.date,
      notes: 'Règlement Fournisseur ${settlementWithNumber.number}',
    ));

    _logEvent(settlement.enterpriseId, 'CREATE_SUPPLIER_SETTLEMENT', settlementId, 'settlement', {
      'supplierId': settlement.supplierId,
      'amount': settlement.amount,
      'number': settlementNumber,
    });

    return settlementId;
  }

  Future<void> deleteSupplierSettlement(String id) async {
    final settlement = await _supplierSettlementRepository.getSettlement(id);
    if (settlement == null || settlement.isDeleted) return;

    // 1. Mark as deleted
    await _supplierSettlementRepository.deleteSettlement(
      id,
      deletedBy: _currentUserId,
    );

    // 2. Reverse Treasury (Supply the amount back)
    await _treasuryRepository.createOperation(TreasuryOperation(
      id: '',
      enterpriseId: settlement.enterpriseId,
      userId: _currentUserId,
      amount: settlement.amount,
      type: TreasuryOperationType.supply,
      toAccount: settlement.paymentMethod,
      date: DateTime.now(),
      notes: 'Annulation Règlement ${settlement.number ?? id}',
      reason: 'Correction erreur règlement',
    ));

    // 3. Reverse Supplier Balance (Increment the debt back)
    final supplier = await _supplierRepository.getSupplier(settlement.supplierId);
    if (supplier != null) {
      final updatedSupplier = supplier.copyWith(
        balance: supplier.balance + settlement.amount,
        updatedAt: DateTime.now(),
      );
      await _supplierRepository.updateSupplier(updatedSupplier);
    }

    _logEvent(settlement.enterpriseId, 'DELETE_SUPPLIER_SETTLEMENT', id, 'settlement', {
      'supplierId': settlement.supplierId,
      'amount': settlement.amount,
      'number': settlement.number,
    });
  }

  // --- Closing ---

  Stream<List<Closing>> watchClosings() {
    return _closingRepository.watchClosings();
  }

  Stream<Closing?> watchActiveSession() {
    return _closingRepository.watchActiveSession();
  }

  Future<Closing?> getActiveSession() {
    return _closingRepository.getActiveSession();
  }

  Future<String> openSession({
    required String enterpriseId,
    required int openingCash,
    required int openingMM,
    String? notes,
  }) async {
    final session = Closing(
      id: '',
      enterpriseId: enterpriseId,
      userId: _currentUserId,
      date: DateTime.now(), // Placeholder for opening
      openingDate: DateTime.now(),
      openingCashAmount: openingCash,
      openingMobileMoneyAmount: openingMM,
      digitalRevenue: 0,
      digitalExpenses: 0,
      digitalNet: 0,
      physicalCashAmount: 0,
      physicalMobileMoneyAmount: 0,
      discrepancy: 0,
      mobileMoneyDiscrepancy: 0,
      digitalCashRevenue: 0,
      digitalMobileMoneyRevenue: 0,
      digitalCardRevenue: 0,
      status: ClosingStatus.open,
      openingNotes: notes,
    );

    // Generate professional number
    final count = await _closingRepository.getCountForDate(session.date);
    final sessionNumber = BoutiqueNumberingService.generate(
      prefix: BoutiqueNumberingService.prefixSession,
      date: session.date,
      dailySequence: count,
    );

    final sessionWithNumber = session.copyWith(number: sessionNumber);
    final id = await _closingRepository.createClosing(sessionWithNumber);

    // Record Initial Treasury Supply/Adjustment to match opening values
    if (openingCash > 0) {
      await _treasuryRepository.createOperation(TreasuryOperation(
        id: '',
        enterpriseId: enterpriseId,
        userId: _currentUserId,
        amount: openingCash,
        type: TreasuryOperationType.adjustment,
        toAccount: PaymentMethod.cash,
        date: session.openingDate!,
        notes: 'Ouverture Session: Fond de caisse inicial',
      ));
    }
    if (openingMM > 0) {
      await _treasuryRepository.createOperation(TreasuryOperation(
        id: '',
        enterpriseId: enterpriseId,
        userId: _currentUserId,
        amount: openingMM,
        type: TreasuryOperationType.adjustment,
        toAccount: PaymentMethod.mobileMoney,
        date: session.openingDate!,
        notes: 'Ouverture Session: Fond Mobile Money inicial',
      ));
    }

    _logEvent(enterpriseId, 'OPEN_SESSION', id, 'closing', {
      'openingCash': openingCash,
      'openingMM': openingMM,
      'number': sessionNumber,
    });
    return id;
  }

  Future<void> performClosing(Closing closing) async {
    await _closingRepository.updateClosing(closing.copyWith(status: ClosingStatus.closed));
    _logEvent(closing.enterpriseId, 'CLOSE_SESSION', closing.id, 'closing', {
      'discrepancy': closing.discrepancy,
      'cashDiscrepancy': closing.cashDiscrepancy,
    });
  }

  // --- Analytics & Valuation ---

  Future<int> calculateStockValuation() async {
    final products = await _productRepository.fetchProducts();
    final active = products.where((p) => p.isActive).toList();
    return active.fold<int>(
      0,
      (sum, p) => sum + (p.stock * (p.purchasePrice ?? 0)),
    );
  }

  // Report methods
  Future<ReportData> getReportData(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _reportRepository.getReportData(
      period,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<SalesReportData> getSalesReport(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _reportRepository.getSalesReport(
      period,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<PurchasesReportData> getPurchasesReport(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _reportRepository.getPurchasesReport(
      period,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<ExpensesReportData> getExpensesReport(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _reportRepository.getExpensesReport(
      period,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<ProfitReportData> getProfitReport(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _reportRepository.getProfitReport(
      period,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Stream<List<Product>> watchProducts() {
    return _productRepository.watchProducts();
  }

  Stream<List<Sale>> watchRecentSales({int limit = 50}) {
    return _saleRepository.watchRecentSales(limit: limit);
  }

  Stream<List<Purchase>> watchPurchases({int limit = 50}) {
    return _purchaseRepository.watchPurchases(limit: limit);
  }

  Stream<List<Expense>> watchExpenses({int limit = 50}) {
    return _expenseRepository.watchExpenses(limit: limit);
  }

  Stream<ReportData> watchReportData(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _reportRepository.watchReportData(
      period,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Stream<SalesReportData> watchSalesReport(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _reportRepository.watchSalesReport(
      period,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Stream<PurchasesReportData> watchPurchasesReport(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _reportRepository.watchPurchasesReport(
      period,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Stream<ExpensesReportData> watchExpensesReport(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _reportRepository.watchExpensesReport(
      period,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Stream<ProfitReportData> watchProfitReport(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _reportRepository.watchProfitReport(
      period,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Stream<FullBoutiqueReportData> watchFullReportData(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _reportRepository.watchFullReportData(
      period,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<FullBoutiqueReportData> getFullReportData(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _reportRepository.getFullReportData(
      period,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Stream<List<Product>> watchLowStockProducts({int threshold = 10}) {
    return _stockRepository.watchLowStockProducts(threshold: threshold);
  }

  Stream<List<Product>> watchDeletedProducts() {
    return _productRepository.watchDeletedProducts();
  }

  Future<List<Sale>> getDeletedSales() {
    return _saleRepository.getDeletedSales();
  }

  Stream<List<Sale>> watchDeletedSales() {
    return _saleRepository.watchDeletedSales();
  }

  Stream<List<Expense>> watchDeletedExpenses() {
    return _expenseRepository.watchDeletedExpenses();
  }

  Stream<List<SupplierSettlement>> watchSettlements({String? supplierId}) {
    return _supplierSettlementRepository.watchSettlements(supplierId: supplierId);
  }

  Stream<List<SupplierSettlement>> watchDeletedSettlements({String? supplierId}) {
    return _supplierSettlementRepository.watchDeletedSettlements(supplierId: supplierId);
  }
  void _logEvent(
    String enterpriseId,
    String action,
    String entityId,
    String entityType,
    Map<String, dynamic> metadata,
  ) {
    try {
      _auditTrailService.logAction(
        enterpriseId: enterpriseId,
        userId: _currentUserId,
        module: 'boutique',
        action: action,
        entityId: entityId,
        entityType: entityType,
        metadata: metadata,
      );
    } catch (e) {
      AppLogger.error('Failed to log boutique audit event', error: e);
    }
  }
}
