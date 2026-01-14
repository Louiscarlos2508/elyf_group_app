import '../../domain/entities/sale.dart';
import '../../domain/repositories/sale_repository.dart';
import '../../domain/services/sale_service.dart';

class SalesController {
  SalesController(this._saleRepository, this._saleService);

  final SaleRepository _saleRepository;
  final SaleService _saleService;

  Future<SalesState> fetchRecentSales() async {
    // Récupérer les ventes récentes (dernières 6 ventes)
    final sales = await _saleRepository.fetchSales();
    sales.sort((a, b) => b.date.compareTo(a.date));
    return SalesState(sales: sales.take(6).toList());
  }

  /// Creates a sale using the repository.
  /// Note: Stock validation should be done before calling this method.
  Future<String> createSale(Sale sale, String userId) async {
    return await _saleRepository.createSale(sale);
  }
}

class SalesState {
  const SalesState({required this.sales});

  final List<Sale> sales;

  int get todayRevenue =>
      sales.fold(0, (value, sale) => value + sale.amountPaid);
}
