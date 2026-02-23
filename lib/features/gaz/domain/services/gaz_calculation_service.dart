import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';
import '../entities/collection.dart';
import '../entities/cylinder.dart';
import '../entities/cylinder_stock.dart';
import '../entities/gaz_session.dart';
import '../entities/gaz_settings.dart';
import '../entities/expense.dart';
import '../entities/gas_sale.dart';
import '../../../../features/administration/domain/entities/enterprise.dart';

/// Service de calculs métier pour le module gaz.
class GazCalculationService {
  GazCalculationService._();

  // ============================================================
  // MÉTHODES DE CALCUL DE BASE
  // ============================================================

  /// Calculates total amount for a gas sale.
  ///
  /// Returns 0.0 if cylinder is null or unitPrice is 0.0.
  static double calculateTotalAmount({
    required Cylinder? cylinder,
    required double unitPrice,
    required int quantity,
    int emptyReturnedQuantity = 0,
  }) {
    if (cylinder == null || (unitPrice == 0.0 && cylinder.depositPrice == 0.0) || quantity < 0) {
      return 0.0;
    }
    
    final gasTotal = unitPrice * quantity;
    final depositDifference = quantity - emptyReturnedQuantity;
    final depositTotal = depositDifference * cylinder.depositPrice;
    
    return gasTotal + depositTotal;
  }

  /// Calculates total amount from quantity text input.
  ///
  /// Returns 0.0 if cylinder is null, unitPrice is 0.0, or quantityText is invalid.
  static double calculateTotalAmountFromText({
    required Cylinder? cylinder,
    required double unitPrice,
    required String? quantityText,
    int emptyReturnedQuantity = 0,
  }) {
    if (cylinder == null ||
        (unitPrice == 0.0 && cylinder.depositPrice == 0.0) ||
        quantityText == null ||
        quantityText.isEmpty) {
      return 0.0;
    }
    final quantity = int.tryParse(quantityText) ?? 0;
    return calculateTotalAmount(
      cylinder: cylinder,
      unitPrice: unitPrice,
      quantity: quantity,
      emptyReturnedQuantity: emptyReturnedQuantity,
    );
  }

  /// Calculates profit for a gas sale.
  ///
  /// Returns 0.0 if purchase price is not available.
  static double calculateProfit({
    required double sellPrice,
    required double? purchasePrice,
    required int quantity,
  }) {
    if (purchasePrice == null || purchasePrice <= 0) {
      return 0.0;
    }
    final profitPerUnit = sellPrice - purchasePrice;
    return profitPerUnit * quantity;
  }

  /// Calculates profit margin percentage.
  ///
  /// Returns 0.0 if sellPrice is 0 or purchasePrice is null/invalid.
  static double calculateProfitMargin({
    required double sellPrice,
    required double? purchasePrice,
  }) {
    if (sellPrice == 0 || purchasePrice == null || purchasePrice <= 0) {
      return 0.0;
    }
    final profit = sellPrice - purchasePrice;
    return (profit / purchasePrice) * 100;
  }

  /// Validates that quantity is within available stock.
  ///
  /// Returns null if valid, error message otherwise.
  static String? validateQuantity({
    required int? quantity,
    required int availableStock,
  }) {
    if (quantity == null) {
      return 'Veuillez entrer une quantité';
    }
    if (quantity <= 0) {
      return 'Quantité invalide';
    }
    if (quantity > availableStock) {
      return 'Stock insuffisant ($availableStock disponible)';
    }
    return null;
  }

  /// Validates that quantity text is valid.
  ///
  /// Returns null if valid, error message otherwise.
  static String? validateQuantityText({
    required String? quantityText,
    required int availableStock,
  }) {
    if (quantityText == null || quantityText.isEmpty) {
      return 'Veuillez entrer une quantité';
    }
    final quantity = int.tryParse(quantityText);
    return validateQuantity(quantity: quantity, availableStock: availableStock);
  }

  /// Determines the wholesale price based on settings and tier.
  /// 
  /// Falls back to cylinder's sell price if no wholesale price is defined.
  static double determineWholesalePrice({
    required Cylinder cylinder,
    required GazSettings? settings,
  }) {
    if (settings == null) {
      return cylinder.sellPrice;
    }
    
    return settings.getWholesalePrice(cylinder.weight) ?? cylinder.sellPrice;
  }

  // ============================================================
  // MÉTHODES DE FILTRAGE
  // ============================================================

  /// Filtre les ventes par plage de dates.
  static List<GasSale> filterSalesByDateRange(
    List<GasSale> sales, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    if (startDate == null && endDate == null) {
      return sales;
    }

    final start = startDate ?? DateTime(2020);
    final end = endDate ?? DateTime.now();

    return sales.where((s) {
      final saleDate = DateTime(
        s.saleDate.year,
        s.saleDate.month,
        s.saleDate.day,
      );
      return saleDate.isAfter(start.subtract(const Duration(days: 1))) &&
          saleDate.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  /// Filtre les ventes par type.
  static List<GasSale> filterSalesByType(
    List<GasSale> sales,
    SaleType saleType,
  ) {
    return sales.where((s) => s.saleType == saleType).toList();
  }

  /// Filtre les ventes en gros.
  static List<GasSale> filterWholesaleSales(List<GasSale> sales) {
    return filterSalesByType(sales, SaleType.wholesale);
  }

  /// Filtre les ventes au détail.
  static List<GasSale> filterRetailSales(List<GasSale> sales) {
    return filterSalesByType(sales, SaleType.retail);
  }

  // ============================================================
  // MÉTHODES DE CALCUL DES VENTES EN GROS
  // ============================================================

  /// Calcule les métriques des ventes pour une période.
  static WholesaleMetrics calculateWholesaleMetrics(
    List<GasSale> allSales, {
    DateTime? startDate,
    DateTime? endDate,
    bool isWholesaleOnly = true,
  }) {
    final baseSales = isWholesaleOnly ? filterWholesaleSales(allSales) : allSales;
    final filteredSales = filterSalesByDateRange(
      baseSales,
      startDate: startDate,
      endDate: endDate,
    );

    final salesCount = filteredSales.length;
    final totalSold = filteredSales.fold<double>(
      0,
      (sum, s) => sum + s.totalAmount,
    );
    // TODO: Ajouter le statut de paiement à GasSale
    final collected = totalSold;
    const credit = 0.0;

    return WholesaleMetrics(
      salesCount: salesCount,
      totalSold: totalSold,
      collected: collected,
      credit: credit,
      sales: filteredSales,
    );
  }

  /// Calcule les ventes du jour par type.
  static List<GasSale> calculateTodaySalesByType(
    List<GasSale> sales,
    SaleType saleType,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return sales.where((s) {
      final saleDate = DateTime(s.saleDate.year, s.saleDate.month, s.saleDate.day);
      return s.saleType == saleType && saleDate.isAtSameMomentAs(today);
    }).toList();
  }

  /// Calcule le revenu du jour par type.
  static double calculateTodayRevenueByType(
    List<GasSale> sales,
    SaleType saleType,
  ) {
    final todaySales = calculateTodaySalesByType(sales, saleType);
    return todaySales.fold<double>(0, (sum, s) => sum + s.totalAmount);
  }

  // ============================================================
  // MÉTHODES DE CALCUL DU STOCK
  // ============================================================

  /// Filtre les stocks par statut plein.
  static List<CylinderStock> filterFullStocks(List<CylinderStock> stocks) {
    return stocks.where((s) => s.status == CylinderStatus.full).toList();
  }

  /// Filtre les stocks par statut vide (uniquement les vides saines).
  static List<CylinderStock> filterEmptyStocks(List<CylinderStock> stocks) {
    return stocks
        .where(
          (s) =>
              s.status == CylinderStatus.emptyAtStore ||
              s.status == CylinderStatus.emptyInTransit,
        )
        .toList();
  }

  /// Filtre les stocks par statut à problème (fuites ou défectueux).
  static List<CylinderStock> filterIssueStocks(List<CylinderStock> stocks) {
    return stocks
        .where(
          (s) =>
              s.status == CylinderStatus.defective ||
              s.status == CylinderStatus.leak,
        )
        .toList();
  }

  /// Calcule le total des bouteilles pleines.
  static int calculateTotalFullCylinders(List<CylinderStock> stocks) {
    return filterFullStocks(stocks).fold<int>(0, (sum, s) => sum + s.quantity);
  }

  /// Calcule le total des bouteilles vides.
  static int calculateTotalEmptyCylinders(List<CylinderStock> stocks) {
    return filterEmptyStocks(stocks).fold<int>(0, (sum, s) => sum + s.quantity);
  }

  /// Groupe les stocks par poids.
  static Map<int, int> groupStocksByWeight(List<CylinderStock> stocks) {
    final byWeight = <int, int>{};
    for (final stock in stocks) {
      byWeight[stock.weight] = (byWeight[stock.weight] ?? 0) + stock.quantity;
    }
    return byWeight;
  }

  /// Calcule les métriques de stock complètes.
  static StockMetrics calculateStockMetrics({
    required List<CylinderStock> stocks,
    required List<Enterprise> pointsOfSale,
    required List<Cylinder> cylinders,
    GazSettings? settings,
    String? targetEnterpriseId,
  }) {
    final fullStocks = filterFullStocks(stocks);
    final emptyStocks = filterEmptyStocks(stocks);
    final issueStocks = filterIssueStocks(stocks);

    final fullByWeight = groupStocksByWeight(fullStocks);
    final emptyByWeight = groupStocksByWeight(emptyStocks);
    final issueByWeight = groupStocksByWeight(issueStocks);

    if (settings != null && settings.nominalStocks.isNotEmpty) {
      for (final cylinder in cylinders) {
        final nominal = settings.getNominalStock(cylinder.weight);
        if (nominal > 0) {
          int full;
          int issues;
          int physicalEmpty;

          if (targetEnterpriseId != null) {
            // If targetEnterpriseId is provided, we calculate the adjustment ONLY for that site
            // and replace its contribution in the global empty count.
            final siteStocks = stocks.where((s) => s.enterpriseId == targetEnterpriseId).toList();
            full = groupStocksByWeight(filterFullStocks(siteStocks))[cylinder.weight] ?? 0;
            issues = groupStocksByWeight(filterIssueStocks(siteStocks))[cylinder.weight] ?? 0;
            physicalEmpty = groupStocksByWeight(filterEmptyStocks(siteStocks))[cylinder.weight] ?? 0;

            // GlobalAdjustedEmpty = GlobalPhysicalEmpty - SitePhysicalEmpty + SiteTheoreticalEmpty
            final siteTheoreticalEmpty = (nominal - full - issues).clamp(0, nominal);
            emptyByWeight[cylinder.weight] = (emptyByWeight[cylinder.weight] ?? 0) - physicalEmpty + siteTheoreticalEmpty;
          } else {
            // Legacy behavior: apply settings to the global sum (only correct if stocks list is for one site)
            full = fullByWeight[cylinder.weight] ?? 0;
            issues = issueByWeight[cylinder.weight] ?? 0;
            emptyByWeight[cylinder.weight] = (nominal - full - issues).clamp(0, nominal);
          }
        }
      }
    }

    final totalFull = fullByWeight.values.fold<int>(0, (sum, val) => sum + val);
    final totalEmpty = emptyByWeight.values.fold<int>(0, (sum, val) => sum + val);
    final totalIssues = issueByWeight.values.fold<int>(0, (sum, val) => sum + val);

    final activePointsOfSale = pointsOfSale.where((p) => p.isActive).toList();

    // Extraire les poids uniques des bouteilles existantes
    final weightsToShow = cylinders.map((c) => c.weight).toSet().toList()
      ..sort();

    return StockMetrics(
      totalFull: totalFull,
      totalEmpty: totalEmpty,
      totalIssues: totalIssues,
      fullByWeight: fullByWeight,
      emptyByWeight: emptyByWeight,
      issueByWeight: issueByWeight,
      activePointsOfSaleCount: activePointsOfSale.length,
      totalPointsOfSaleCount: pointsOfSale.length,
      availableWeights: weightsToShow,
    );
  }

  /// Formate le résumé des stocks par poids.
  static String formatStockByWeightSummary(
    Map<int, int> stockByWeight,
    List<int> weights,
  ) {
    if (weights.isEmpty) {
      return 'Aucune bouteille';
    }
    return weights.map((w) => '${w}kg: ${stockByWeight[w] ?? 0}').join(' • ');
  }

  // ============================================================
  // MÉTHODES DE CALCUL DES VENTES AU DÉTAIL
  // ============================================================

  /// Calcule les métriques des ventes au détail.
  static RetailMetrics calculateRetailMetrics(
    List<GasSale> allSales,
    List<Cylinder> cylinders, {
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final retailSales = filterRetailSales(allSales);
    final todaySales = retailSales.where((s) {
      final saleDate = DateTime(
        s.saleDate.year,
        s.saleDate.month,
        s.saleDate.day,
      );
      return saleDate.isAtSameMomentAs(today);
    }).toList();

    final todayRevenue = todaySales.fold<double>(
      0,
      (sum, s) => sum + s.totalAmount,
    );

    // Calcul par poids de bouteille
    final salesByWeight = <int, int>{};
    // Initialize map with all cylinder weights
    for (final cylinder in cylinders) {
      salesByWeight[cylinder.weight] = 0;
    }
    // Calculate sales by weight
    for (final sale in todaySales) {
      // Find the cylinder for this sale
      final cylinder = cylinders.firstWhere(
        (c) => c.id == sale.cylinderId,
        orElse: () => cylinders.first, // Fallback, shouldn't happen
      );
      final weight = cylinder.weight;
      salesByWeight[weight] = (salesByWeight[weight] ?? 0) + sale.quantity;
    }

    return RetailMetrics(
      todaySalesCount: todaySales.length,
      todayRevenue: todayRevenue,
      salesByWeight: salesByWeight,
    );
  }

  /// Calcule les ventes du jour.
  static List<GasSale> calculateTodaySales(List<GasSale> sales) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return sales.where((s) {
      final saleDate = DateTime(
        s.saleDate.year,
        s.saleDate.month,
        s.saleDate.day,
      );
      return saleDate.isAtSameMomentAs(today);
    }).toList();
  }

  /// Calcule le revenu du jour.
  static double calculateTodayRevenue(List<GasSale> sales) {
    final todaySales = calculateTodaySales(sales);
    return todaySales.fold<double>(0, (sum, s) => sum + s.totalAmount);
  }


  /// Calcule les dépenses du jour.
  static List<GazExpense> calculateTodayExpenses(List<GazExpense> expenses) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return expenses.where((e) {
      final expenseDate = DateTime(e.date.year, e.date.month, e.date.day);
      return expenseDate.isAtSameMomentAs(today);
    }).toList();
  }

  /// Calcule le total des dépenses du jour.
  static double calculateTodayExpensesTotal(List<GazExpense> expenses) {
    final todayExpenses = calculateTodayExpenses(expenses);
    return todayExpenses.fold<double>(0, (sum, e) => sum + e.amount);
  }

  /// Calcule le profit du jour (Revenu - COGS - Dépenses).
  static double calculateTodayProfit(
    List<GasSale> sales,
    List<GazExpense> expenses,
    List<Cylinder> cylinders,
  ) {
    final todaySales = calculateTodaySales(sales);
    final todayRevenue = calculateTodayRevenue(sales);
    final todayExpenses = calculateTodayExpensesTotal(expenses);
    
    double todayCOGS = 0.0;
    for (final sale in todaySales) {
      final cylinder = cylinders.firstWhere(
        (c) => c.id == sale.cylinderId,
        orElse: () => cylinders.firstWhere((c) => c.weight == 0, orElse: () => cylinders.first),
      );
      todayCOGS += cylinder.buyPrice * sale.quantity;
    }

    return todayRevenue - todayCOGS - todayExpenses;
  }

  /// Calcule les données de performance pour les 7 derniers jours.
  static ({
    List<double> profitData,
    List<double> expensesData,
    List<double> salesData,
  })
  calculateLast7DaysPerformance(
    List<GasSale> sales,
    List<GazExpense> expenses,
  ) {
    final now = DateTime.now();
    final profitData = <double>[];
    final expensesData = <double>[];
    final salesData = <double>[];

    // Calculate data for last 7 days
    for (var i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      // Sales for this day
      final daySales = sales.where((s) {
        return s.saleDate.isAfter(
              dayStart.subtract(const Duration(seconds: 1)),
            ) &&
            s.saleDate.isBefore(dayEnd);
      }).toList();
      final dayRevenue = daySales.fold<double>(
        0,
        (sum, s) => sum + s.totalAmount,
      );
      salesData.add(dayRevenue);

      // Expenses for this day
      final dayExpenses = expenses.where((e) {
        return e.date.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
            e.date.isBefore(dayEnd);
      }).toList();
      final dayExpensesAmount = dayExpenses.fold<double>(
        0,
        (sum, e) => sum + e.amount,
      );
      expensesData.add(dayExpensesAmount);

      // Profit for this day
      final dayProfit = dayRevenue - dayExpensesAmount;
      profitData.add(dayProfit);
    }

    return (
      profitData: profitData,
      expensesData: expensesData,
      salesData: salesData,
    );
  }

  /// Calcule le total des bouteilles par poids à partir des collections.
  static Map<int, int> calculateTotalBottlesByWeight(
    List<Collection> collections,
  ) {
    final totalBottlesByWeight = <int, int>{};
    for (final collection in collections) {
      for (final entry in collection.emptyBottles.entries) {
        totalBottlesByWeight[entry.key] =
            (totalBottlesByWeight[entry.key] ?? 0) + entry.value;
      }
    }
    return totalBottlesByWeight;
  }

  /// Calcule le total général des bouteilles à partir des collections.
  static int calculateTotalBottles(List<Collection> collections) {
    final totalBottlesByWeight = calculateTotalBottlesByWeight(collections);
    return totalBottlesByWeight.values.fold<int>(0, (sum, qty) => sum + qty);
  }

  /// Calcule le total général des dépenses.
  static double calculateTotalExpenses(List<GazExpense> expenses) {
    return expenses.fold<double>(0, (sum, e) => sum + e.amount);
  }

  /// Calcule le revenu total.
  static double calculateTotalRevenue(List<GasSale> sales) {
    return sales.fold<double>(0, (sum, s) => sum + s.totalAmount);
  }

  /// Calcule le profit total.
  static double calculateTotalProfit(
    List<GasSale> sales,
    List<GazExpense> expenses,
  ) {
    final totalRevenue = calculateTotalRevenue(sales);
    final totalExpenses = calculateTotalExpenses(expenses);
    return totalRevenue - totalExpenses;
  }

  // ============================================================
  // MÉTHODES DE CALCUL DU MOIS
  // ============================================================

  /// Calcule les ventes du mois.
  static List<GasSale> calculateMonthSales(
    List<GasSale> sales, {
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    return sales.where((s) {
      return s.saleDate.isAfter(monthStart.subtract(const Duration(days: 1)));
    }).toList();
  }

  /// Calcule le revenu du mois.
  static double calculateMonthRevenue(
    List<GasSale> sales, {
    DateTime? referenceDate,
  }) {
    final monthSales = calculateMonthSales(sales, referenceDate: referenceDate);
    return monthSales.fold<double>(0, (sum, s) => sum + s.totalAmount);
  }

  /// Calcule les dépenses du mois.
  static double calculateMonthExpenses(
    List<GazExpense> expenses, {
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthExpenses = expenses.where((e) {
      return e.date.isAfter(monthStart.subtract(const Duration(days: 1)));
    }).toList();
    return monthExpenses.fold<double>(0, (sum, e) => sum + e.amount);
  }

  /// Calcule le profit du mois (Revenu - COGS - Dépenses).
  static double calculateMonthProfit(
    List<GasSale> sales,
    List<GazExpense> expenses,
    List<Cylinder> cylinders, {
    DateTime? referenceDate,
  }) {
    final monthSales = calculateMonthSales(sales, referenceDate: referenceDate);
    final monthRevenue = calculateMonthRevenue(
      sales,
      referenceDate: referenceDate,
    );
    final monthExpenses = calculateMonthExpenses(
      expenses,
      referenceDate: referenceDate,
    );
    
    // Calculate COGS (Cost of Goods Sold)
    double monthCOGS = 0.0;
    for (final sale in monthSales) {
      final cylinder = cylinders.firstWhere(
        (c) => c.id == sale.cylinderId,
        orElse: () => cylinders.firstWhere((c) => c.weight == 0, orElse: () => cylinders.first),
      );
      monthCOGS += cylinder.buyPrice * sale.quantity;
    }

    return monthRevenue - monthCOGS - monthExpenses;
  }

  // ============================================================
  // MÉTHODES DE CALCUL DE STOCK PAR POINT DE VENTE
  // ============================================================

  /// Calcule les métriques de stock pour un point de vente spécifique.
  static PointOfSaleStockMetrics calculatePosStockMetrics({
    required String posId,
    required List<CylinderStock> allStocks,
    List<Cylinder>? cylinders,
    GazSettings? settings,
  }) {
    // Filtrer les stocks pour ce point de vente (basé sur l'ID entreprise)
    final posStocks = allStocks.where((s) => s.enterpriseId == posId).toList();

    // Calculer les totaux
    final fullStocks = posStocks.where((s) => s.status == CylinderStatus.full).toList();
    final emptyStocks = posStocks
        .where(
          (s) =>
              s.status == CylinderStatus.emptyAtStore ||
              s.status == CylinderStatus.emptyInTransit,
        )
        .toList();

    final fullByWeight = groupStocksByWeight(fullStocks);
    final emptyByWeight = groupStocksByWeight(emptyStocks);
    
    final issueStocks = posStocks
        .where((s) => s.status == CylinderStatus.defective || s.status == CylinderStatus.leak)
        .toList();
    final issueByWeight = groupStocksByWeight(issueStocks);

    // Appliquer le stock nominal si disponible
    if (settings != null && settings.nominalStocks.isNotEmpty && cylinders != null) {
      for (final cylinder in cylinders) {
        final nominal = settings.getNominalStock(cylinder.weight);
        if (nominal > 0) {
          final full = fullByWeight[cylinder.weight] ?? 0;
          final issues = issueByWeight[cylinder.weight] ?? 0;
          // Le vide théorique est le nominal moins les pleines et les bouteilles à problème déjà identifiées
          emptyByWeight[cylinder.weight] = (nominal - full - issues).clamp(0, nominal);
        }
      }
    }

    final totalFull = fullByWeight.values.fold<int>(0, (sum, v) => sum + v);
    final totalEmpty = emptyByWeight.values.fold<int>(0, (sum, v) => sum + v);
    final totalIssues = issueByWeight.values.fold<int>(0, (sum, v) => sum + v);

    // Déterminer les types de bouteilles à afficher
    final Set<int> weightSet = cylinders != null
        ? cylinders.map((c) => c.weight).toSet()
        : posStocks.map((s) => s.weight).toSet();
    final weightsToShow = weightSet.toList()..sort();

    final stockByCapacity = <int, ({int full, int empty, int defective, int leak})>{};

    for (final weight in weightsToShow) {
      final full = fullByWeight[weight] ?? 0;
      final empty = emptyByWeight[weight] ?? 0;
      final defective = posStocks
          .where((s) => s.weight == weight && s.status == CylinderStatus.defective)
          .fold<int>(0, (sum, s) => sum + s.quantity);
      final leak = posStocks
          .where((s) => s.weight == weight && s.status == CylinderStatus.leak)
          .fold<int>(0, (sum, s) => sum + s.quantity);

      if (full > 0 || empty > 0 || defective > 0 || leak > 0) {
        stockByCapacity[weight] = (
          full: full,
          empty: empty,
          defective: defective,
          leak: leak,
        );
      }
    }

    return PointOfSaleStockMetrics(
      pointOfSaleId: posId,
      totalFull: totalFull,
      totalEmpty: totalEmpty,
      totalIssues: totalIssues,
      stockByCapacity: stockByCapacity,
    );
  }

  // ============================================================
  // MÉTHODES DE RÉCONCILIATION
  // ============================================================

  /// Calcule les métriques de réconciliation pour une journée donnée.
  static ReconciliationMetrics calculateDailyReconciliation({
    required DateTime date,
    required List<GasSale> allSales,
    required List<GazExpense> allExpenses,
    required List<Cylinder> cylinders,
    List<CylinderStock> stocks = const [],
    double openingCash = 0.0,
    double openingMobileMoney = 0.0,
  }) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    // Filtrer les ventes et dépenses du jour
    final todaySales = allSales.where((s) {
      return s.saleDate.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
          s.saleDate.isBefore(dayEnd);
    }).toList();

    final todayExpenses = allExpenses.where((e) {
      return e.date.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
          e.date.isBefore(dayEnd);
    }).toList();

    // Calculer les totaux
    final totalSales = todaySales.fold<double>(
      0,
      (sum, s) => sum + s.totalAmount,
    );
    final totalExpenses = todayExpenses.fold<double>(
      0,
      (sum, e) => sum + e.amount,
    );

    // Ventes partagées par méthode de paiement
    final salesByPaymentMethod = <PaymentMethod, double>{};
    for (final method in PaymentMethod.values) {
      salesByPaymentMethod[method] = todaySales
          .where((s) => s.paymentMethod == method)
          .fold<double>(0, (sum, s) => sum + s.totalAmount);
    }

    // Le cash théorique est: Cash Initial + Total Espèces - Dépenses
    final cashSales = salesByPaymentMethod[PaymentMethod.cash] ?? 0.0;
    final theoreticalCash = openingCash + cashSales - totalExpenses;

    // L'Orange Money théorique est: OM Initial + Total OM
    final omSales = salesByPaymentMethod[PaymentMethod.mobileMoney] ?? 0.0;
    final theoreticalMobileMoney = openingMobileMoney + omSales;

    // Ventes partagées par poids (quantité totale de bouteilles)
    final salesByCylinderWeight = <int, int>{};
    for (final cylinder in cylinders) {
      final weight = cylinder.weight;
      final count = todaySales
          .where((s) => s.cylinderId == cylinder.id)
          .fold<int>(0, (sum, s) => sum + s.quantity);
      salesByCylinderWeight[weight] =
          (salesByCylinderWeight[weight] ?? 0) + count;
    }

    // Stock théorique (Bouteilles pleines actuelles)
    final theoreticalStock = <int, int>{};
    for (final cylinder in cylinders) {
      final weight = cylinder.weight;
      final fullStock = stocks
          .where((s) => s.cylinderId == cylinder.id && s.status == CylinderStatus.full)
          .fold<int>(0, (sum, s) => sum + s.quantity);
      theoreticalStock[weight] = (theoreticalStock[weight] ?? 0) + fullStock;
    }

    // Stock théorique (Bouteilles vides actuelles)
    final theoreticalEmptyStock = <int, int>{};
    for (final cylinder in cylinders) {
      final weight = cylinder.weight;
      final emptyStock = stocks
          .where((s) => s.cylinderId == cylinder.id && s.status == CylinderStatus.emptyAtStore)
          .fold<int>(0, (sum, s) => sum + s.quantity);
      theoreticalEmptyStock[weight] = (theoreticalEmptyStock[weight] ?? 0) + emptyStock;
    }

    return ReconciliationMetrics(
      date: dayStart,
      totalSales: totalSales,
      totalExpenses: totalExpenses,
      theoreticalCash: theoreticalCash,
      theoreticalMobileMoney: theoreticalMobileMoney,
      salesByPaymentMethod: salesByPaymentMethod,
      salesByCylinderWeight: salesByCylinderWeight,
      theoreticalStock: theoreticalStock,
      theoreticalEmptyStock: theoreticalEmptyStock,
    );
  }

  /// Crée un enregistrement de clôture de session.
  static GazSession createSessionClosure({
    required String id,
    required String enterpriseId,
    required ReconciliationMetrics metrics,
    required double physicalCash,
    required String closedBy,
    Map<int, int> physicalStock = const {},
    Map<int, int> physicalEmptyStock = const {},
    Map<int, int> openingFullStock = const {},
    Map<int, int> openingEmptyStock = const {},
    double openingCash = 0.0,
    double openingMobileMoney = 0.0,
    String? notes,
  }) {
    return GazSession.fromMetrics(
      id: id,
      enterpriseId: enterpriseId,
      metrics: metrics,
      physicalCash: physicalCash,
      closedBy: closedBy,
      physicalStock: physicalStock,
      physicalEmptyStock: physicalEmptyStock,
      openingFullStock: openingFullStock,
      openingEmptyStock: openingEmptyStock,
      openingCash: openingCash,
      openingMobileMoney: openingMobileMoney,
      notes: notes,
    );
  }
}

// ============================================================
// CLASSES DE MÉTRIQUES
// ============================================================

/// Métriques des ventes en gros.
class WholesaleMetrics {
  const WholesaleMetrics({
    required this.salesCount,
    required this.totalSold,
    required this.collected,
    required this.credit,
    required this.sales,
  });

  final int salesCount;
  final double totalSold;
  final double collected;
  final double credit;
  final List<GasSale> sales;
}

/// Métriques du stock.
class StockMetrics {
  const StockMetrics({
    required this.totalFull,
    required this.totalEmpty,
    required this.totalIssues,
    required this.fullByWeight,
    required this.emptyByWeight,
    required this.issueByWeight,
    required this.activePointsOfSaleCount,
    required this.totalPointsOfSaleCount,
    required this.availableWeights,
  });

  final int totalFull;
  final int totalEmpty;
  final int totalIssues;
  final Map<int, int> fullByWeight;
  final Map<int, int> emptyByWeight;
  final Map<int, int> issueByWeight;
  final int activePointsOfSaleCount;
  final int totalPointsOfSaleCount;
  final List<int> availableWeights;

  String get fullSummary => GazCalculationService.formatStockByWeightSummary(fullByWeight, availableWeights);
  String get emptySummary => GazCalculationService.formatStockByWeightSummary(emptyByWeight, availableWeights);
  String get issueSummary => GazCalculationService.formatStockByWeightSummary(issueByWeight, availableWeights);
}

/// Métriques des ventes au détail.
class RetailMetrics {
  const RetailMetrics({
    required this.todaySalesCount,
    required this.todayRevenue,
    required this.salesByWeight,
  });

  final int todaySalesCount;
  final double todayRevenue;
  final Map<int, int> salesByWeight;
}

/// Métriques du stock par point de vente.
class PointOfSaleStockMetrics {
  const PointOfSaleStockMetrics({
    required this.pointOfSaleId,
    required this.totalFull,
    required this.totalEmpty,
    required this.totalIssues,
    required this.stockByCapacity,
  });

  final String pointOfSaleId;
  final int totalFull;
  final int totalEmpty;
  final int totalIssues;
  final Map<int, ({int full, int empty, int defective, int leak})> stockByCapacity;
}

/// Métriques de réconciliation journalière.
class ReconciliationMetrics {
  const ReconciliationMetrics({
    required this.date,
    required this.totalSales,
    required this.totalExpenses,
    required this.theoreticalCash,
    this.theoreticalMobileMoney = 0.0,
    required this.salesByPaymentMethod,
    required this.salesByCylinderWeight,
    this.theoreticalStock = const {},
    this.theoreticalEmptyStock = const {},
  });

  final DateTime date;
  final double totalSales;
  final double totalExpenses;
  final double theoreticalCash; // Uniquement le cash (espèces)
  final double theoreticalMobileMoney;
  final Map<PaymentMethod, double> salesByPaymentMethod;
  final Map<int, int> salesByCylinderWeight;
  final Map<int, int> theoreticalStock;
  final Map<int, int> theoreticalEmptyStock;
}
