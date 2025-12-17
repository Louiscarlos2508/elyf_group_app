import 'dart:async';

import '../../domain/entities/sale.dart';
import '../../domain/repositories/sale_repository.dart';

/// Mock implementation of SaleRepository for development.
class MockSaleRepository implements SaleRepository {
  final Map<String, Sale> _sales = {};

  @override
  Future<List<Sale>> fetchSales({
    DateTime? startDate,
    DateTime? endDate,
    SaleStatus? status,
    String? customerId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    var sales = _sales.values.toList();

    if (startDate != null) {
      sales = sales
          .where((s) => s.date.isAfter(startDate) || s.date.isAtSameMomentAs(startDate))
          .toList();
    }

    if (endDate != null) {
      sales = sales
          .where((s) => s.date.isBefore(endDate) || s.date.isAtSameMomentAs(endDate))
          .toList();
    }

    if (status != null) {
      sales = sales.where((s) => s.status == status).toList();
    }

    if (customerId != null) {
      sales = sales.where((s) => s.customerId == customerId).toList();
    }

    sales.sort((a, b) => b.date.compareTo(a.date));
    return sales;
  }

  @override
  Future<Sale?> getSale(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _sales[id];
  }

  @override
  Future<String> createSale(Sale sale) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final id = sale.id.isEmpty ? 'sale-${_sales.length + 1}' : sale.id;
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
      cashAmount: sale.cashAmount,
      orangeMoneyAmount: sale.orangeMoneyAmount,
      productionSessionId: sale.productionSessionId,
    );
    return id;
  }

  @override
  Future<void> deleteSale(String saleId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    _sales.remove(saleId);
  }

  @override
  Future<void> updateSaleAmountPaid(String saleId, int newAmountPaid) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final sale = _sales[saleId];
    if (sale == null) {
      throw Exception('Vente introuvable');
    }
    _sales[saleId] = Sale(
      id: sale.id,
      productId: sale.productId,
      productName: sale.productName,
      quantity: sale.quantity,
      unitPrice: sale.unitPrice,
      totalPrice: sale.totalPrice,
      amountPaid: newAmountPaid,
      customerName: sale.customerName,
      customerPhone: sale.customerPhone,
      customerId: sale.customerId,
      date: sale.date,
      status: newAmountPaid >= sale.totalPrice ? SaleStatus.fullyPaid : sale.status,
      createdBy: sale.createdBy,
      customerCnib: sale.customerCnib,
      notes: sale.notes,
      cashAmount: sale.cashAmount,
      orangeMoneyAmount: sale.orangeMoneyAmount,
      productionSessionId: sale.productionSessionId,
    );
  }
}

