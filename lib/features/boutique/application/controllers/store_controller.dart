import '../../domain/entities/cart_item.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/entities/report_data.dart';
import '../../domain/entities/sale.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../../domain/repositories/report_repository.dart';
import '../../domain/repositories/sale_repository.dart';
import '../../domain/repositories/stock_repository.dart';
import '../../../audit_trail/domain/services/audit_trail_service.dart';
import '../../../../core/logging/app_logger.dart';

class StoreController {
  StoreController(
    this._productRepository,
    this._saleRepository,
    this._stockRepository,
    this._purchaseRepository,
    this._expenseRepository,
    this._reportRepository,
    this._auditTrailService,
    this._currentUserId,
  );

  final ProductRepository _productRepository;
  final SaleRepository _saleRepository;
  final StockRepository _stockRepository;
  final PurchaseRepository _purchaseRepository;
  final ExpenseRepository _expenseRepository;
  final ReportRepository _reportRepository;
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

  Future<List<Product>> getDeletedProducts() async {
    return await _productRepository.getDeletedProducts();
  }

  Future<List<Sale>> fetchRecentSales({int limit = 50}) async {
    return await _saleRepository.fetchRecentSales(limit: limit);
  }

  Future<String> createSale(Sale sale) async {
    // Update stock for each item
    for (final item in sale.items) {
      final product = await _productRepository.getProduct(item.productId);
      if (product != null) {
        final newStock = product.stock - item.quantity;
        await _stockRepository.updateStock(item.productId, newStock);
      }
    }
    final saleId = await _saleRepository.createSale(sale);
    _logEvent(sale.enterpriseId, 'CREATE_SALE', saleId, 'sale', {
      'totalAmount': sale.totalAmount,
      'itemCount': sale.items.length,
    });
    return saleId;
  }

  Future<List<Product>> getLowStockProducts({int threshold = 10}) async {
    return await _stockRepository.getLowStockProducts(threshold: threshold);
  }

  int calculateCartTotal(List<CartItem> cartItems) {
    return cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  }

  // Purchase methods
  Future<List<Purchase>> fetchPurchases({int limit = 50}) async {
    return await _purchaseRepository.fetchPurchases(limit: limit);
  }

  Future<String> createPurchase(Purchase purchase) async {
    // Update stock and purchase price for each item
    for (final item in purchase.items) {
      final product = await _productRepository.getProduct(item.productId);
      if (product != null) {
        final newStock = product.stock + item.quantity;
        final updatedProduct = product.copyWith(
          stock: newStock,
          purchasePrice: item.purchasePrice,
        );
        // Mise à jour unique : utiliser updateProduct qui met déjà à jour le stock
        await _productRepository.updateProduct(updatedProduct);
        // Ne pas appeler updateStock car updateProduct le fait déjà
      }
    }
    final purchaseId = await _purchaseRepository.createPurchase(purchase);
    _logEvent(purchase.enterpriseId, 'CREATE_PURCHASE', purchaseId, 'purchase', {
      'totalAmount': purchase.totalAmount,
      'itemCount': purchase.items.length,
    });
    return purchaseId;
  }

  // Expense methods
  Future<List<Expense>> fetchExpenses({int limit = 50}) async {
    return await _expenseRepository.fetchExpenses(limit: limit);
  }

  Future<String> createExpense(Expense expense) async {
    final expenseId = await _expenseRepository.createExpense(expense);
    _logEvent(expense.enterpriseId, 'CREATE_EXPENSE', expenseId, 'expense', {
      'label': expense.label,
      'amount': expense.amountCfa,
    });
    return expenseId;
  }

  Future<void> deleteExpense(String id) async {
    final expense = await _expenseRepository.getExpense(id);
    if (expense != null) {
      await _expenseRepository.deleteExpense(
        id,
        deletedBy: _currentUserId,
      );
      _logEvent(expense.enterpriseId, 'DELETE_EXPENSE', id, 'expense', {
        'label': expense.label,
      });
    }
  }

  Future<void> restoreExpense(String id) async {
    return await _expenseRepository.restoreExpense(id);
  }

  Future<List<Expense>> getDeletedExpenses() async {
    return await _expenseRepository.getDeletedExpenses();
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

  Stream<List<Product>> watchLowStockProducts({int threshold = 10}) {
    return _stockRepository.watchLowStockProducts(threshold: threshold);
  }

  Stream<List<Product>> watchDeletedProducts() {
    return _productRepository.watchDeletedProducts();
  }

  Stream<List<Expense>> watchDeletedExpenses() {
    return _expenseRepository.watchDeletedExpenses();
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
