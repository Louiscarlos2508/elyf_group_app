import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers/controller_providers.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers/repository_providers.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers/service_providers.dart';
import 'package:elyf_groupe_app/core/errors/app_exceptions.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/production_session.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/sale.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/report_data.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/report_period.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/product.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/product_sales_summary.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/production_report_data.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/expense_report_data.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/salary_report_data.dart';

export 'package:elyf_groupe_app/features/eau_minerale/domain/entities/production_session.dart';
export 'package:elyf_groupe_app/features/eau_minerale/domain/entities/product.dart';
export 'package:elyf_groupe_app/features/eau_minerale/domain/entities/report_period.dart';
export 'package:elyf_groupe_app/features/eau_minerale/domain/entities/product_sales_summary.dart';
export 'package:elyf_groupe_app/features/eau_minerale/domain/entities/production_report_data.dart';
export 'package:elyf_groupe_app/features/eau_minerale/domain/entities/expense_report_data.dart';
export 'package:elyf_groupe_app/features/eau_minerale/domain/entities/salary_report_data.dart';

final productionSessionsStateProvider =
    StreamProvider.autoDispose<List<ProductionSession>>((ref) {
  return ref.watch(productionSessionControllerProvider).watchSessions();
});

final productionSessionsInPeriodProvider = FutureProvider.autoDispose
    .family<List<ProductionSession>, ({DateTime start, DateTime end})>(
  (ref, range) async {
    return ref.read(productionSessionControllerProvider).fetchSessions(
          startDate: range.start,
          endDate: range.end,
        );
  },
);

/// Provider pour récupérer une session par son ID.
final productionSessionDetailProvider = FutureProvider.autoDispose
    .family<ProductionSession, String>((ref, sessionId) async {
  final session = await ref
      .read(productionSessionControllerProvider)
      .fetchSessionById(sessionId);
  if (session == null) {
    throw NotFoundException(
      'Session non trouvée: $sessionId',
      'SESSION_NOT_FOUND',
    );
  }
  return session;
});

/// Provider pour récupérer les ventes liées à une session.
final ventesParSessionProvider = FutureProvider.autoDispose
    .family<List<Sale>, String>((ref, sessionId) async {
  final session =
      await ref.read(productionSessionDetailProvider(sessionId).future);

  final saleRepo = ref.read(saleRepositoryProvider);

  // 1. Fetch explicitly linked sales using SQL optimization (Chantier 5)
  // This is the primary and fastest way to get sales for this session.
  final linkedSales = await saleRepo.fetchSales(productionSessionId: sessionId);

  // 2. Fallback chronological for legacy sales without explicit linkage
  // Fetch only sales from that day to minimize memory footprint
  final sessionDate = session.date;
  final startOfDay =
      DateTime(sessionDate.year, sessionDate.month, sessionDate.day);
  final endOfDay = startOfDay
      .add(const Duration(days: 1))
      .subtract(const Duration(milliseconds: 1));

  final potentialLegacySales = await saleRepo.fetchSales(
    startDate: startOfDay,
    endDate: endOfDay,
  );

  // Filter legacy sales in memory
  final legacyFiltered = potentialLegacySales.where((sale) {
    // If it's already explicitly linked to THIS session, it's in linkedSales
    if (sale.productionSessionId == sessionId) return false;

    // If it's explicitly linked to ANOTHER session, it's not ours
    if (sale.productionSessionId != null && sale.productionSessionId != '') {
      return false;
    }

    // Chronological check
    final isAfterStart = sale.date.isAfter(session.heureDebut) ||
        sale.date.isAtSameMomentAs(session.heureDebut);

    final sessionEnd = session.heureFin;
    final isBeforeEnd = sessionEnd == null
        ? true
        : (sale.date.isBefore(sessionEnd) ||
            sale.date.isAtSameMomentAs(sessionEnd));

    return isAfterStart && isBeforeEnd;
  }).toList();

  // Combine both sources
  final allSessionSales = [...linkedSales, ...legacyFiltered];

  // Sort by date descending
  allSessionSales.sort((a, b) => b.date.compareTo(a.date));

  return allSessionSales;
});

final productionPeriodConfigProvider = FutureProvider.autoDispose(
  (ref) async => ref.watch(productionPeriodServiceProvider).getConfig(),
);

final productsProvider = FutureProvider.autoDispose<List<Product>>(
  (ref) async => ref.watch(productControllerProvider).fetchProducts(),
);

final rawMaterialsProvider =
    FutureProvider.autoDispose<List<Product>>((ref) async {
  final products = await ref.watch(productsProvider.future);
  return products.where((p) => p.type == ProductType.rawMaterial).toList();
});

final reportDataProvider = FutureProvider.autoDispose
    .family<ReportData, ReportPeriod>(
      (ref, period) async =>
          ref.watch(reportControllerProvider).fetchReportData(period),
    );

final reportSalesProvider = FutureProvider.autoDispose
    .family<List<Sale>, ReportPeriod>(
      (ref, period) async =>
          ref.watch(reportControllerProvider).fetchSalesForPeriod(period),
    );

final reportProductSummaryProvider = FutureProvider.autoDispose
    .family<List<ProductSalesSummary>, ReportPeriod>(
      (ref, period) async =>
          ref.watch(reportControllerProvider).fetchProductSalesSummary(period),
    );

final reportProductionProvider = FutureProvider.autoDispose
    .family<ProductionReportData, ReportPeriod>(
      (ref, period) async =>
          ref.watch(reportControllerProvider).fetchProductionReport(period),
    );

final reportExpenseProvider = FutureProvider.autoDispose
    .family<ExpenseReportData, ReportPeriod>(
      (ref, period) async =>
          ref.watch(reportControllerProvider).fetchExpenseReport(period),
    );

final reportSalaryProvider = FutureProvider.autoDispose
    .family<SalaryReportData, ReportPeriod>(
      (ref, period) async =>
          ref.watch(reportControllerProvider).fetchSalaryReport(period),
    );

/// Stream for Today's Sales (Real-time)
final todaySalesStreamProvider =
    StreamProvider.autoDispose<List<Sale>>((ref) {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay
      .add(const Duration(days: 1))
      .subtract(const Duration(milliseconds: 1));

  return ref.watch(saleRepositoryProvider).watchSales(
        startDate: startOfDay,
        endDate: endOfDay,
      );
});

/// Stream for Today's Production Sessions (Real-time)
final todaySessionsStreamProvider =
    StreamProvider.autoDispose<List<ProductionSession>>((ref) {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay
      .add(const Duration(days: 1))
      .subtract(const Duration(milliseconds: 1));

  return ref.watch(productionSessionRepositoryProvider).watchSessions(
        startDate: startOfDay,
        endDate: endOfDay,
      );
});

final suppliersProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(supplierControllerProvider).watchSuppliers(),
);

final purchasesProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(purchaseControllerProvider).watchPurchases(),
);

final currentClosingSessionProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(closingControllerProvider).watchCurrentSession(),
);

final closingHistoryProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(closingControllerProvider).fetchHistory(),
);
