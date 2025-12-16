import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';

import '../../../core/pdf/eau_minerale_stock_report_pdf_service.dart';
import '../../../features/eau_minerale/domain/entities/packaging_stock.dart';
import '../../../features/eau_minerale/domain/entities/stock_item.dart';
import '../widgets/stock_report_summary.dart';
import '../widgets/stock_report_table.dart';

/// Écran pour le rapport de stock.
class StockReportScreen extends ConsumerStatefulWidget {
  const StockReportScreen({
    super.key,
    required this.moduleName,
    required this.stockItems,
    required this.packagingStocks,
    required this.availableBobines,
  });

  final String moduleName;
  final List<StockItem> stockItems;
  final List<PackagingStock> packagingStocks;
  final int availableBobines;

  @override
  ConsumerState<StockReportScreen> createState() =>
      _StockReportScreenState();
}

class _StockReportScreenState extends ConsumerState<StockReportScreen> {
  final DateTime _reportDate = DateTime.now();

  List<StockItem> _getFilteredStockItems() {
    // Filtrer les items "sachet" et "bidon" qui ne doivent pas apparaître dans le rapport
    return widget.stockItems
        .where((item) =>
            !item.name.toLowerCase().contains('sachet') &&
            !item.name.toLowerCase().contains('bidon'))
        .toList();
  }

  List<StockItemData> _getAllStockData() {
    final filteredItems = _getFilteredStockItems();
    final stockData = filteredItems.map((item) {
      return StockItemData(
        name: item.name,
        quantity: item.quantity,
        unit: item.unit,
        updatedAt: item.updatedAt,
      );
    }).toList();

    // Ajouter les emballages
    final packagingData = widget.packagingStocks.map((stock) {
      return StockItemData(
        name: stock.type,
        quantity: stock.quantity.toDouble(),
        unit: stock.unit,
        updatedAt: stock.updatedAt ?? DateTime.now(),
      );
    }).toList();

    // Ajouter les bobines disponibles
    if (widget.availableBobines > 0) {
      stockData.add(StockItemData(
        name: 'Bobines disponibles',
        quantity: widget.availableBobines.toDouble(),
        unit: 'unité',
        updatedAt: DateTime.now(),
      ));
    }

    return [...stockData, ...packagingData];
  }

  Future<void> _downloadPdf(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final pdfService = EauMineraleStockReportPdfService();
      final file = await pdfService.generateReport(
        stockItems: _getFilteredStockItems(),
        packagingStocks: widget.packagingStocks,
        availableBobines: widget.availableBobines,
        reportDate: _reportDate,
      );

      if (!mounted) return;
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      final filePath = file.path;
      navigator.pop();
      final result = await OpenFile.open(filePath);
      if (!mounted) return;
      if (result.type != ResultType.done) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('PDF généré: $filePath'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la génération PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allStockData = _getAllStockData();
    final totalItems = allStockData.length;
    final totalQuantity = allStockData.fold<double>(
      0,
      (sum, item) => sum + item.quantity,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Rapport de Stock - ${widget.moduleName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadPdf(context),
            tooltip: 'Télécharger PDF',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StockReportSummary(
              totalItems: totalItems,
              totalQuantity: totalQuantity,
              reportDate: _reportDate,
            ),
            const SizedBox(height: 24),
            StockReportTable(stockData: allStockData),
          ],
        ),
      ),
    );
  }
}

