import 'dart:async';

import '../../domain/entities/sale.dart';
import '../../domain/repositories/sales_repository.dart';

class MockSalesRepository implements SalesRepository {
  final _sales = <String, Sale>{};

  MockSalesRepository() {
    // Initialize with sample data
    for (var i = 0; i < 6; i++) {
      final date = DateTime.now().subtract(Duration(hours: i * 2));
      _sales['sale-$i'] = Sale(
        id: 'sale-$i',
        productId: 'product-1',
        productName: 'Sachets 50cl',
        quantity: 50 + (i * 5),
        unitPrice: 500,
        totalPrice: (50 + (i * 5)) * 500,
        amountPaid: i.isEven ? (50 + (i * 5)) * 500 : (50 + (i * 5)) * 500 - 10000,
        customerName: 'Client dépôt #$i',
        customerPhone: '+22177000${400 + i}',
        customerId: 'customer-$i',
        date: date,
        status: i.isEven ? SaleStatus.fullyPaid : SaleStatus.validated,
        createdBy: 'user-1',
      );
    }
  }

  @override
  Future<List<Sale>> fetchRecentSales({int limit = 20}) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final sales = _sales.values.toList();
    sales.sort((a, b) => b.date.compareTo(a.date));
    return sales.take(limit).toList();
  }

  @override
  Future<String> createSale(Sale sale) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final id = 'sale-${_sales.length}';
    _sales[id] = Sale(
      id: id,
      productId: sale.productId,
      productName: sale.productName,
      quantity: sale.quantity,
      unitPrice: sale.unitPrice,
      totalPrice: sale.totalPrice,
      amountPaid: sale.amountPaid,
      customerName: sale.customerName,
      customerPhone: sale.customerPhone,
      customerId: sale.customerId,
      date: sale.date,
      status: sale.status,
      createdBy: sale.createdBy,
      customerCnib: sale.customerCnib,
      notes: sale.notes,
    );
    return id;
  }
}
