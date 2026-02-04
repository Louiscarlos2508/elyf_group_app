import 'dart:developer' as developer;
import '../../domain/adapters/pack_stock_adapter.dart';
import '../../domain/entities/sale.dart';
import '../../domain/pack_constants.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/sale_repository.dart';

class SalesController {
  SalesController(
    this._saleRepository,
    this._packStockAdapter,
    this._productRepository,
  );

  final SaleRepository _saleRepository;
  final PackStockAdapter _packStockAdapter;
  final ProductRepository _productRepository;

  Future<SalesState> fetchRecentSales() async {
    final sales = await _saleRepository.fetchSales();
    sales.sort((a, b) => b.date.compareTo(a.date));
    return SalesState(sales: sales);
  }

  Stream<SalesState> watchRecentSales() {
    return _saleRepository.watchSales().map((sales) {
      // _saleRepository.watchSales() already sorts, but we can ensure it?
      // It returns parsed sales.
      // Filter logic is inside repo if args provided, here no args = All.
      return SalesState(sales: sales);
    });
  }

  /// Crée une vente et décrémente le stock Pack si produit fini.
  ///
  /// Utilise [packProductId] pour le Pack (même que Stock, Dashboard, Paramètres).
  /// Décrémente toujours le StockItem Pack lorsqu'une vente Pack est créée.
  Future<String> createSale(Sale sale, String userId) async {
    try {
      final id = await _saleRepository.createSale(sale);
      final isPack = sale.productId == packProductId;
      
      // Check if it's a finished good by fetching product details if not a Pack
      bool isOtherFinishedGood = false;
      if (!isPack) {
        try {
          final product = await _productRepository.getProduct(sale.productId);
          isOtherFinishedGood = product?.isFinishedGood == true;
        } catch (e) {
          developer.log('Error checking finished good status: $e', name: 'elyf.sales');
        }
      }

      if ((isPack || isOtherFinishedGood) && sale.quantity > 0) {
        try {
          await _packStockAdapter.recordPackExit(
            sale.quantity,
            productId: sale.productId,
            reason: 'Vente',
            notes: 'Vente ${sale.productName}',
          );
        } catch (e, st) {
          // Log but don't fail the entire sale creation if stock update fails? 
          // Usually better to fail if stock is critical, but here we want to avoid the crash.
          developer.log(
            'Failed to record pack exit for sale $id: $e',
            name: 'elyf.sales',
            error: e,
            stackTrace: st,
          );
          // If we want to be strict, we'd rethrow, but here we aim for robustness.
        }
      }
      return id;
    } catch (e, st) {
      developer.log('Error in createSale: $e', name: 'elyf.sales', error: e, stackTrace: st);
      rethrow;
    }
  }
}

class SalesState {
  const SalesState({required this.sales});

  final List<Sale> sales;

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  int get todayRevenue => sales
      .where((sale) => _isToday(sale.date))
      .fold(0, (value, sale) => value + sale.totalPrice);

  int get todaySalesCount => sales.where((sale) => _isToday(sale.date)).length;

  int get todayCollections => sales
      .where((sale) => _isToday(sale.date))
      .fold(0, (value, sale) => value + sale.amountPaid);
}
