import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/domain/entities/expense_balance_data.dart';
import '../../shared.dart';

/// Service pour générer le PDF du bilan des dépenses.
class ExpenseBalancePdfService {
  /// Génère un PDF de bilan des dépenses.
  Future<File> generateReport({
    required String moduleName,
    required List<ExpenseBalanceData> expenses,
    required DateTime startDate,
    required DateTime endDate,
    required String Function(String) getCategoryLabel,
    String? fileName,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    // Calculer les totaux par catégorie
    final categoryTotals = <String, int>{};
    for (final expense in expenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    final totalAmount = expenses.fold<int>(0, (sum, e) => sum + e.amount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            _buildHeader(moduleName),
            pw.SizedBox(height: 20),
            _buildTitle('Bilan Effectif des Dépenses'),
            pw.SizedBox(height: 10),
            _buildPeriodInfo(
              'Du ${dateFormat.format(startDate)} au ${dateFormat.format(endDate)}',
            ),
            pw.SizedBox(height: 30),
            _buildSummary(totalAmount, expenses.length),
            pw.SizedBox(height: 30),
            _buildCategoryTable(categoryTotals, getCategoryLabel, totalAmount),
            pw.SizedBox(height: 30),
            _buildExpensesTable(expenses, getCategoryLabel),
            pw.SizedBox(height: 30),
            _buildFooter(),
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final fileNameFinal = fileName ??
        'bilan_depenses_${moduleName.toLowerCase().replaceAll(' ', '_')}_'
        '${DateFormat('yyyyMMdd').format(startDate)}_'
        '${DateFormat('yyyyMMdd').format(endDate)}.pdf';
    final file = File('${output.path}/$fileNameFinal');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  pw.Widget _buildHeader(String moduleName) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'ELYF GROUPE',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              moduleName,
              style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
            ),
          ],
        ),
        pw.Text(
          DateFormat('dd/MM/yyyy').format(DateTime.now()),
          style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
        ),
      ],
    );
  }

  pw.Widget _buildTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 24,
        fontWeight: pw.FontWeight.bold,
      ),
    );
  }

  pw.Widget _buildPeriodInfo(String info) {
    return pw.Text(
      info,
      style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
    );
  }

  pw.Widget _buildSummary(int totalAmount, int expenseCount) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Total des dépenses',
                style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                CurrencyFormatter.formatFCFA(totalAmount),
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Nombre de dépenses',
                style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                expenseCount.toString(),
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCategoryTable(
    Map<String, int> categoryTotals,
    String Function(String) getCategoryLabel,
    int totalAmount,
  ) {
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Catégorie', isHeader: true),
            _buildTableCell('Montant', isHeader: true),
          ],
        ),
        ...sortedCategories.map((entry) {
          final percentage = (entry.value / totalAmount * 100);
          return pw.TableRow(
            children: [
              _buildTableCell(getCategoryLabel(entry.key)),
              _buildTableCell(
                '${CurrencyFormatter.formatFCFA(entry.value)} (${percentage.toStringAsFixed(1)}%)',
              ),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildExpensesTable(
    List<ExpenseBalanceData> expenses,
    String Function(String) getCategoryLabel,
  ) {
    final sortedExpenses = List<ExpenseBalanceData>.from(expenses)
      ..sort((a, b) => b.date.compareTo(a.date));
    final dateFormat = DateFormat('dd/MM/yyyy');

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Date', isHeader: true),
            _buildTableCell('Libellé', isHeader: true),
            _buildTableCell('Catégorie', isHeader: true),
            _buildTableCell('Montant', isHeader: true),
          ],
        ),
        ...sortedExpenses.map((expense) {
          return pw.TableRow(
            children: [
              _buildTableCell(dateFormat.format(expense.date)),
              _buildTableCell(expense.label),
              _buildTableCell(getCategoryLabel(expense.category)),
              _buildTableCell(CurrencyFormatter.formatFCFA(expense.amount)),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _buildFooter() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        pw.Text(
          'Document généré le ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
      ],
    );
  }

}

