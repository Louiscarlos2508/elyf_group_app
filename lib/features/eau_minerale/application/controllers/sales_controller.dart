import '../../domain/entities/sale.dart';
import '../../domain/repositories/sales_repository.dart';

class SalesController {
  SalesController(this._repository);

  final SalesRepository _repository;

  Future<SalesState> fetchRecentSales() async {
    final sales = await _repository.fetchRecentSales(limit: 6);
    return SalesState(sales: sales);
  }

  Future<String> createSale(Sale sale) async {
    return await _repository.createSale(sale);
  }
}

class SalesState {
  const SalesState({required this.sales});

  final List<Sale> sales;

  int get todayRevenue =>
      sales.fold(0, (value, sale) => value + sale.amountPaid);
}
