import '../../../../features/boutique/domain/entities/closing.dart';
import '../../../../shared.dart';
import '../thermal_receipt_builder.dart';

/// Template pour l'impression du rapport de clôture (Z-Report) sur imprimante thermique.
class ZReportTemplate {
  ZReportTemplate(
    this.closing, {
    this.width = 32,
    this.headerText,
    this.footerText,
    this.showLogo = true,
  });

  final Closing closing;
  final int width;
  final String? headerText;
  final String? footerText;
  final bool showLogo;

  /// Génère le contenu formaté du Z-Report pour l'impression thermique.
  String generate() {
    final builder = ThermalReceiptBuilder(width: width);

    // Logo / Header
    if (showLogo) {
      builder.center('[ E L Y F ]');
      builder.space();
    }

    builder.header(headerText ?? 'BOUTIQUE ELYF', subtitle: 'RAPPORT DE CLOTURE (Z)');

    // Informations de la session
    builder.row('Session N°', closing.number ?? closing.id.substring(0, 8));
    builder.row('Date', _formatDate(closing.date));
    builder.row('Heure', _formatTime(closing.date));
    builder.space();

    builder.section('BILAN FINANCIER');
    
    // Chiffres théoriques
    builder.row('Ventes Totales', CurrencyFormatter.formatFCFA(closing.digitalRevenue));
    builder.row('Dépenses Totales', CurrencyFormatter.formatFCFA(-closing.digitalExpenses));
    builder.row('Attendu Net', CurrencyFormatter.formatFCFA(closing.digitalNet));
    builder.space();

    builder.center('Détail Modes de Paiement');
    builder.row('  Espèces (Ventes)', CurrencyFormatter.formatFCFA(closing.digitalCashRevenue));
    builder.row('  Mobile Money', CurrencyFormatter.formatFCFA(closing.digitalMobileMoneyRevenue));
    builder.space();

    builder.section('RECONCILIATION PHYSIQUE');

    // Espèces
    builder.center('-- ESPECES (CASH) --');
    builder.row('Attendu Cash', CurrencyFormatter.formatFCFA(closing.expectedCash));
    builder.row('Physique Cash', CurrencyFormatter.formatFCFA(closing.physicalCashAmount));
    builder.row('Ecart Cash', CurrencyFormatter.formatFCFA(closing.cashDiscrepancy));
    builder.space();

    // Mobile Money
    builder.center('-- MOBILE MONEY --');
    builder.row('Attendu MM', CurrencyFormatter.formatFCFA(closing.expectedMobileMoney));
    builder.row('Physique MM', CurrencyFormatter.formatFCFA(closing.physicalMobileMoneyAmount));
    builder.row('Ecart MM', CurrencyFormatter.formatFCFA(closing.mobileMoneyDiscrepancy));
    builder.space();

    builder.separator();
    builder.row('ECART GLOBAL', CurrencyFormatter.formatFCFA(closing.discrepancy));
    builder.separator();
    builder.space();

    if (closing.notes != null && closing.notes!.isNotEmpty) {
      builder.writeLine('Notes:');
      builder.writeLine(closing.notes);
      builder.space();
    }

    // Pied de page
    builder.footer(footerText ?? 'RAPPORT GENERE AVEC SUCCES');

    return builder.toString();
  }

  String _formatDate(DateTime date) {
    return DateFormatter.formatDate(date);
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}
