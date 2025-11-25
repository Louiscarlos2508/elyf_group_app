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

class StoreController {
  StoreController(
    this._productRepository,
    this._saleRepository,
    this._stockRepository,
    this._purchaseRepository,
    this._expenseRepository,
    this._reportRepository,
  );

  final ProductRepository _productRepository;
  final SaleRepository _saleRepository;
  final StockRepository _stockRepository;
  final PurchaseRepository _purchaseRepository;
  final ExpenseRepository _expenseRepository;
  final ReportRepository _reportRepository;

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
    return await _productRepository.createProduct(product);
  }

  Future<void> updateProduct(Product product) async {
    return await _productRepository.updateProduct(product);
  }

  Future<void> deleteProduct(String id) async {
    return await _productRepository.deleteProduct(id);
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
    return await _saleRepository.createSale(sale);
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
        await _productRepository.updateProduct(updatedProduct);
        await _stockRepository.updateStock(item.productId, newStock);
      }
    }
    return await _purchaseRepository.createPurchase(purchase);
  }

  // Expense methods
  Future<List<Expense>> fetchExpenses({int limit = 50}) async {
    return await _expenseRepository.fetchExpenses(limit: limit);
  }

  Future<String> createExpense(Expense expense) async {
    return await _expenseRepository.createExpense(expense);
  }

  Future<void> deleteExpense(String id) async {
    return await _expenseRepository.deleteExpense(id);
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
}

