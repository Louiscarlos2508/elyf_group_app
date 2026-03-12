import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/cylinder.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/gas_sale.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';
import 'package:elyf_groupe_app/features/gaz/domain/services/gaz_financial_calculation_service.dart';
import 'price_stock_manager.dart';
import 'gas_sale_submit_handler.dart';

class GasSaleFormState {
  final Cylinder? selectedCylinder;
  final int availableStock;
  final double unitPrice;
  final bool isLoading;
  final String? wholesalerId;
  final String? wholesalerName;
  final GasSale? completedSale;
  final PaymentMethod paymentMethod;
  final bool isMixedPayment;
  final bool showAdvancedOptions;
  final int quantity;

  const GasSaleFormState({
    this.selectedCylinder,
    this.availableStock = 0,
    this.unitPrice = 0.0,
    this.isLoading = false,
    this.wholesalerId,
    this.wholesalerName,
    this.completedSale,
    this.paymentMethod = PaymentMethod.cash,
    this.isMixedPayment = false,
    this.showAdvancedOptions = false,
    this.quantity = 1,
  });

  double get totalAmount => GazFinancialCalculationService.calculateTotalAmount(
        cylinder: selectedCylinder,
        unitPrice: unitPrice,
        quantity: quantity,
      );

  GasSaleFormState copyWith({
    Cylinder? selectedCylinder,
    int? availableStock,
    double? unitPrice,
    bool? isLoading,
    String? wholesalerId,
    String? wholesalerName,
    GasSale? completedSale,
    PaymentMethod? paymentMethod,
    bool? isMixedPayment,
    bool? showAdvancedOptions,
    int? quantity,
  }) {
    return GasSaleFormState(
      selectedCylinder: selectedCylinder ?? this.selectedCylinder,
      availableStock: availableStock ?? this.availableStock,
      unitPrice: unitPrice ?? this.unitPrice,
      isLoading: isLoading ?? this.isLoading,
      wholesalerId: wholesalerId ?? this.wholesalerId,
      wholesalerName: wholesalerName ?? this.wholesalerName,
      completedSale: completedSale ?? this.completedSale,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isMixedPayment: isMixedPayment ?? this.isMixedPayment,
      showAdvancedOptions: showAdvancedOptions ?? this.showAdvancedOptions,
      quantity: quantity ?? this.quantity,
    );
  }
}

class GasSaleFormNotifier extends Notifier<GasSaleFormState> {
  final SaleType arg;
  GasSaleFormNotifier(this.arg);

  @override
  GasSaleFormState build() {
    return const GasSaleFormState();
  }

  void initialize(Cylinder? initialCylinder, String? enterpriseId) {
    if (initialCylinder != null) {
      state = state.copyWith(selectedCylinder: initialCylinder);
      if (enterpriseId != null) {
        fetchPriceAndStock(enterpriseId);
      }
    }
  }

  void updateCylinder(Cylinder? cylinder, String? enterpriseId) {
    state = state.copyWith(selectedCylinder: cylinder);
    if (enterpriseId != null) {
      fetchPriceAndStock(enterpriseId);
    }
  }

  void updateQuantity(int quantity) {
    state = state.copyWith(quantity: quantity);
  }

  void updateUnitPrice(double price) {
    state = state.copyWith(unitPrice: price);
  }

  void updateWholesaler(String? id, String? name, String? enterpriseId) {
    state = state.copyWith(wholesalerId: id, wholesalerName: name);
    if (enterpriseId != null) {
      fetchPriceAndStock(enterpriseId);
    }
  }

  void updatePaymentMethod(PaymentMethod method, bool isMixed) {
    state = state.copyWith(paymentMethod: method, isMixedPayment: isMixed);
  }

  void toggleAdvancedOptions() {
    state = state.copyWith(showAdvancedOptions: !state.showAdvancedOptions);
  }

  Future<void> fetchPriceAndStock(String enterpriseId) async {
    final price = await PriceStockManager.updateUnitPrice(
      ref: ref,
      cylinder: state.selectedCylinder,
      enterpriseId: enterpriseId,
      isWholesale: arg == SaleType.wholesale,
    );
    
    final stock = await PriceStockManager.updateAvailableStock(
      ref: ref,
      cylinder: state.selectedCylinder,
      enterpriseId: enterpriseId,
    );

    state = state.copyWith(unitPrice: price, availableStock: stock);
  }

  Future<void> submit({
    required BuildContext context,
    required String enterpriseId,
    required String? customerName,
    required String? customerPhone,
    required String? notes,
    required double? cashAmount,
    required double? mobileMoneyAmount,
  }) async {
    if (state.selectedCylinder == null) return;

    final sale = await GasSaleSubmitHandler.submit(
      context: context,
      ref: ref,
      selectedCylinder: state.selectedCylinder!,
      quantity: state.quantity,
      availableStock: state.availableStock,
      enterpriseId: enterpriseId,
      saleType: arg,
      customerName: customerName,
      customerPhone: customerPhone,
      notes: notes,
      totalAmount: state.totalAmount,
      unitPrice: state.unitPrice,
      wholesalerId: state.wholesalerId,
      wholesalerName: state.wholesalerName,
      paymentMethod: state.isMixedPayment ? PaymentMethod.both : state.paymentMethod,
      cashAmount: state.isMixedPayment ? cashAmount : null,
      mobileMoneyAmount: state.isMixedPayment ? mobileMoneyAmount : null,
      onLoadingChanged: () => state = state.copyWith(isLoading: !state.isLoading),
    );

    if (sale != null) {
      state = state.copyWith(completedSale: sale);
    }
  }
}

final gasSaleFormControllerProvider = NotifierProvider.family.autoDispose<
    GasSaleFormNotifier, GasSaleFormState, SaleType>((arg) {
  return GasSaleFormNotifier(arg);
});
