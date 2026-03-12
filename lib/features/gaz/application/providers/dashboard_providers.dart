import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/features/administration/application/providers.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';

import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';
import '../../domain/entities/cylinder.dart';
import '../../domain/entities/cylinder_stock.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/gas_sale.dart';
import '../../domain/entities/report_data.dart';
import '../../domain/entities/pos_remittance.dart';

import 'controller_providers.dart';
import 'data_providers.dart';


final gazDashboardDataProviderComplete = StreamProvider<({List<GasSale> sales, List<GazExpense> expenses, List<Cylinder> cylinders, List<CylinderStock> stocks, List<GazPOSRemittance> remittances, List<Enterprise> pointsOfSale})>((ref) {
  final salesAsync = ref.watch(gasSalesProvider);
  final expensesAsync = ref.watch(gazExpensesProvider);
  final cylindersAsync = ref.watch(cylindersProvider);
  final stocksAsync = ref.watch(gazStocksProvider);
  final remittancesAsync = ref.watch(gazPOSRemittancesProvider);
  
  final activeEnterprise = ref.watch(activeEnterpriseProvider).value;
  final pointsOfSaleAsync = activeEnterprise != null 
      ? ref.watch(enterprisesByParentAndTypeProvider((parentId: activeEnterprise.id, type: EnterpriseType.gasPointOfSale)))
      : const AsyncValue.data(<Enterprise>[]);

  if ((salesAsync.isLoading && !salesAsync.hasValue) || 
      (expensesAsync.isLoading && !expensesAsync.hasValue) || 
      (cylindersAsync.isLoading && !cylindersAsync.hasValue) || 
      (stocksAsync.isLoading && !stocksAsync.hasValue) ||
      (remittancesAsync.isLoading && !remittancesAsync.hasValue) ||
      (pointsOfSaleAsync.isLoading && !pointsOfSaleAsync.hasValue)) {
    return const Stream.empty();
  }

  return Stream.value((
    sales: salesAsync.value ?? [],
    expenses: expensesAsync.value ?? [],
    cylinders: cylindersAsync.value ?? [],
    stocks: stocksAsync.value ?? [],
    remittances: remittancesAsync.value ?? [],
    pointsOfSale: pointsOfSaleAsync.value ?? [],
  ));
});

final gazLocalDashboardDataProvider = Provider<AsyncValue<({List<GasSale> sales, List<GazExpense> expenses, List<Cylinder> cylinders, List<CylinderStock> stocks, List<GazPOSRemittance> remittances, List<Enterprise> pointsOfSale})>>((ref) {
  final salesAsync = ref.watch(gasLocalSalesProvider);
  final expensesAsync = ref.watch(gazLocalExpensesProvider);
  final cylindersAsync = ref.watch(cylindersProvider);
  final stocksAsync = ref.watch(gazLocalStocksProvider);
  final remittancesAsync = ref.watch(gazPOSRemittancesProvider);
  
  final activeEnterprise = ref.watch(activeEnterpriseProvider).value;
  final pointsOfSaleAsync = activeEnterprise != null 
      ? ref.watch(enterprisesByParentAndTypeProvider((parentId: activeEnterprise.id, type: EnterpriseType.gasPointOfSale)))
      : const AsyncValue.data(<Enterprise>[]);

  if ((salesAsync.isLoading && !salesAsync.hasValue) || 
      (expensesAsync.isLoading && !expensesAsync.hasValue) || 
      (cylindersAsync.isLoading && !cylindersAsync.hasValue) || 
      (stocksAsync.isLoading && !stocksAsync.hasValue) ||
      (remittancesAsync.isLoading && !remittancesAsync.hasValue) ||
      (pointsOfSaleAsync.isLoading && !pointsOfSaleAsync.hasValue)) {
    return const AsyncLoading();
  }

  return AsyncData((
    sales: salesAsync.value ?? [],
    expenses: expensesAsync.value ?? [],
    cylinders: cylindersAsync.value ?? [],
    stocks: stocksAsync.value ?? [],
    remittances: remittancesAsync.value ?? [],
    pointsOfSale: pointsOfSaleAsync.value ?? [],
  ));
});

final gasLocalSalesProvider = StreamProvider<List<GasSale>>((ref) {
  final controller = ref.watch(gasControllerProvider);
  final activeId = ref.watch(activeEnterpriseIdProvider).value ?? 'default';
  return controller.watchSales(enterpriseIds: [activeId]);
});

final gazLocalExpensesProvider = StreamProvider<List<GazExpense>>((ref) {
  final controller = ref.watch(expenseControllerProvider);
  final activeId = ref.watch(activeEnterpriseIdProvider).value ?? 'default';
  return controller.watchExpenses(enterpriseIds: [activeId]);
});

final gazLocalStocksProvider = StreamProvider<List<CylinderStock>>((ref) {
  final controller = ref.watch(cylinderStockControllerProvider);
  final activeId = ref.watch(activeEnterpriseIdProvider).value ?? 'default';
  return controller.watchStocks(activeId, enterpriseIds: [activeId]);
});

final gazTotalSalesProvider = Provider<AsyncValue<double>>((ref) {
  final salesAsync = ref.watch(gasSalesProvider);
  return salesAsync.whenData(
    (sales) => sales.fold<double>(0.0, (sum, s) => sum + s.totalAmount),
  );
});

final gazTotalExpensesProvider = Provider<AsyncValue<double>>((ref) {
  final expensesAsync = ref.watch(gazExpensesProvider);
  return expensesAsync.whenData(
    (expenses) => expenses.fold<double>(0.0, (sum, e) => sum + e.amount),
  );
});

final gazProfitProvider = Provider<AsyncValue<double>>((ref) {
  final totalSalesAsync = ref.watch(gazTotalSalesProvider);
  final totalExpensesAsync = ref.watch(gazTotalExpensesProvider);

  if (totalSalesAsync.hasError) return AsyncError(totalSalesAsync.error!, totalSalesAsync.stackTrace!);
  if (totalExpensesAsync.hasError) return AsyncError(totalExpensesAsync.error!, totalExpensesAsync.stackTrace!);

  if (totalSalesAsync.isLoading || totalExpensesAsync.isLoading) {
    return const AsyncLoading();
  }

  return AsyncData((totalSalesAsync.value ?? 0.0) - (totalExpensesAsync.value ?? 0.0));
});

final gazReportDataProvider = FutureProvider.family
    .autoDispose<
      GazReportData,
      ({GazReportPeriod period, DateTime? startDate, DateTime? endDate})
    >((ref, params) async {
      final salesAsync = ref.watch(gasSalesProvider);
      final expensesAsync = ref.watch(gazExpensesProvider);
      final activeEnterprise = ref.watch(activeEnterpriseProvider).value;
      
      final posListAsync = activeEnterprise != null 
          ? ref.watch(enterprisesByParentAndTypeProvider((
              parentId: activeEnterprise.id,
              type: EnterpriseType.gasPointOfSale,
            )))
          : null;
      
      final treasuryBalanceAsync = activeEnterprise != null 
          ? ref.watch(gazTreasuryBalanceProvider(activeEnterprise.id))
          : null;

      final sales = await salesAsync.when(
        data: (data) async => data,
        loading: () async => <GasSale>[],
        error: (_, __) async => <GasSale>[],
      );

      final expenses = await expensesAsync.when(
        data: (data) async => data,
        loading: () async => <GazExpense>[],
        error: (_, __) async => <GazExpense>[],
      );

      final posList = posListAsync?.value ?? [];
      final posIds = posList.map((e) => e.id).toSet();
      
      final balances = treasuryBalanceAsync?.value ?? {};
      final double cashBalance = (balances['cash'] ?? 0).toDouble();
      final double omBalance = (balances['mobileMoney'] ?? 0).toDouble();

      DateTime rangeStart;
      DateTime rangeEnd;
      final now = DateTime.now();

      switch (params.period) {
        case GazReportPeriod.today:
          rangeStart = DateTime(now.year, now.month, now.day);
          rangeEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case GazReportPeriod.week:
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          rangeStart = DateTime(weekStart.year, weekStart.month, weekStart.day);
          rangeEnd = now;
          break;
        case GazReportPeriod.month:
          rangeStart = DateTime(now.year, now.month, 1);
          rangeEnd = now;
          break;
        case GazReportPeriod.year:
          rangeStart = DateTime(now.year, 1, 1);
          rangeEnd = now;
          break;
        case GazReportPeriod.custom:
          rangeStart = params.startDate ?? DateTime(now.year, now.month, 1);
          rangeEnd = params.endDate ?? now;
          break;
      }

      final filteredSales = sales.where((s) {
        return s.saleDate.isAfter(rangeStart.subtract(const Duration(days: 1))) &&
            s.saleDate.isBefore(rangeEnd.add(const Duration(days: 1)));
      }).toList();

      final filteredExpenses = expenses.where((e) {
        return e.date.isAfter(rangeStart.subtract(const Duration(days: 1))) &&
            e.date.isBefore(rangeEnd.add(const Duration(days: 1)));
      }).toList();

      double internalWholesaleRevenue = 0;
      double externalWholesaleRevenue = 0;
      double retailRevenue = 0;
      double cashTotal = 0;
      double omTotal = 0;

      for (final s in filteredSales) {
        if (s.saleType == SaleType.wholesale) {
          if (posIds.contains(s.wholesalerId)) {
            internalWholesaleRevenue += s.totalAmount;
          } else {
            externalWholesaleRevenue += s.totalAmount;
          }
        } else {
          retailRevenue += s.totalAmount;
        }

        if (s.paymentMethod == PaymentMethod.mobileMoney) {
          omTotal += s.totalAmount;
        } else if (s.paymentMethod == PaymentMethod.cash) {
          cashTotal += s.totalAmount;
        } else {
          cashTotal += s.cashAmount ?? 0;
          omTotal += s.mobileMoneyAmount ?? 0;
        }
      }

      final salesRevenue = filteredSales.fold<double>(0, (sum, s) => sum + s.totalAmount);
      final expensesAmount = filteredExpenses.fold<double>(0, (sum, e) => sum + e.amount);
      final profit = salesRevenue - expensesAmount;

      final retailCount = filteredSales.where((s) => s.saleType == SaleType.retail).length;
      final wholesaleCount = filteredSales.length - retailCount;

      final cylinders = ref.watch(cylindersProvider).value ?? [];
      final Map<String, int> productBreakdown = {};
      for (final sale in filteredSales) {
        final cylinder = cylinders.firstWhere((c) => c.id == sale.cylinderId, 
          orElse: () => const Cylinder(id: '', weight: 0, buyPrice: 0, sellPrice: 0, enterpriseId: '', moduleId: 'gaz'));
        if (cylinder.id.isNotEmpty) {
          final label = cylinder.label;
          productBreakdown[label] = (productBreakdown[label] ?? 0) + sale.quantity;
        }
      }

      final List<GazPosPerformance> posPerf = [];
      if (activeEnterprise != null && !activeEnterprise.isPointOfSale) {
        if (posList.isNotEmpty) {
          for (final pos in posList) {
            final posSales = filteredSales.where((s) => s.enterpriseId == pos.id).toList();
            if (posSales.isEmpty) continue;

            final posRevenue = posSales.fold<double>(0, (sum, s) => sum + s.totalAmount);
            final posQty = posSales.fold<int>(0, (sum, s) => sum + s.quantity);
            
            final Map<String, int> posProdBreakdown = {};
            for (final s in posSales) {
              final cyl = cylinders.firstWhere((c) => c.id == s.cylinderId, 
                orElse: () => const Cylinder(id: '', weight: 0, buyPrice: 0, sellPrice: 0, enterpriseId: '', moduleId: 'gaz'));
              if (cyl.id.isNotEmpty) {
                posProdBreakdown[cyl.label] = (posProdBreakdown[cyl.label] ?? 0) + s.quantity;
              }
            }
            
            String? topProd;
            if (posProdBreakdown.isNotEmpty) {
              topProd = posProdBreakdown.entries.reduce((a, b) => a.value > b.value ? a : b).key;
            }

            posPerf.add(GazPosPerformance(
              enterpriseName: pos.name,
              revenue: posRevenue,
              salesCount: posSales.length,
              quantitySold: posQty,
              revenuePercentage: salesRevenue > 0 ? (posRevenue / salesRevenue) * 100 : 0,
              topProduct: topProd,
            ));
          }
          posPerf.sort((a, b) => b.revenue.compareTo(a.revenue));
        }
      }

      return GazReportData(
        period: params.period,
        salesRevenue: salesRevenue,
        expensesAmount: expensesAmount,
        profit: profit,
        salesCount: filteredSales.length,
        expensesCount: filteredExpenses.length,
        retailSalesCount: retailCount,
        wholesaleSalesCount: wholesaleCount,
        productBreakdown: productBreakdown,
        posPerformance: posPerf,
        internalWholesaleRevenue: internalWholesaleRevenue,
        externalWholesaleRevenue: externalWholesaleRevenue,
        retailRevenue: retailRevenue,
        cashTotal: cashTotal,
        omTotal: omTotal,
        cashBalance: cashBalance,
        omBalance: omBalance,
      );
    });
