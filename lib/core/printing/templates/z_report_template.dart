import '../../../../features/boutique/domain/entities/closing.dart';
import '../../../../shared.dart';

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
    final buffer = StringBuffer();

    // Logo
    if (showLogo) {
      buffer.writeln(_centerText(' [ E L Y F ] '));
      buffer.writeln();
    }

    // En-tête
    if (headerText != null && headerText!.isNotEmpty) {
      buffer.writeln(_centerText(headerText!));
    } else {
      buffer.writeln(_centerText('BOUTIQUE ELYF'));
    }
    buffer.writeln(_centerText('RAPPORT DE CLOTURE (Z)'));
    buffer.writeln(_centerText('=' * width));
    buffer.writeln();

    // Informations de la session
    buffer.writeln(_centerText('Session N°: ${closing.number ?? closing.id.substring(0, 8)}'));
    buffer.writeln(_centerText('Date: ${_formatDate(closing.date)}'));
    buffer.writeln(_centerText('Heure: ${_formatTime(closing.date)}'));
    buffer.writeln();

    buffer.writeln(_centerText('-' * width));
    buffer.writeln(_centerText('BILAN FINANCIER'));
    buffer.writeln(_centerText('-' * width));
    buffer.writeln();

    // Chiffres théoriques
    buffer.writeln(_formatLine('Ventes Totales:', CurrencyFormatter.formatFCFA(closing.digitalRevenue)));
    buffer.writeln(_formatLine('Dépenses Totales:', CurrencyFormatter.formatFCFA(-closing.digitalExpenses)));
    buffer.writeln(_formatLine('Attendu Net:', CurrencyFormatter.formatFCFA(closing.digitalNet)));
    buffer.writeln();

    buffer.writeln(_centerText('Détail Modes de Paiement'));
    buffer.writeln(_formatLine('  Espèces (Ventes):', CurrencyFormatter.formatFCFA(closing.digitalCashRevenue)));
    buffer.writeln(_formatLine('  Mobile Money:', CurrencyFormatter.formatFCFA(closing.digitalMobileMoneyRevenue)));
    buffer.writeln();

    buffer.writeln(_centerText('-' * width));
    buffer.writeln(_centerText('RECONCILIATION PHYSIQUE'));
    buffer.writeln(_centerText('-' * width));
    buffer.writeln();

    // Espèces
    buffer.writeln(_centerText('-- ESPECES (CASH) --'));
    buffer.writeln(_formatLine('Attendu Cash:', CurrencyFormatter.formatFCFA(closing.expectedCash)));
    buffer.writeln(_formatLine('Physique Cash:', CurrencyFormatter.formatFCFA(closing.physicalCashAmount)));
    buffer.writeln(_formatLine('Ecart Cash:', CurrencyFormatter.formatFCFA(closing.cashDiscrepancy)));
    buffer.writeln();

    // Mobile Money
    buffer.writeln(_centerText('-- MOBILE MONEY --'));
    buffer.writeln(_formatLine('Attendu MM:', CurrencyFormatter.formatFCFA(closing.expectedMobileMoney)));
    buffer.writeln(_formatLine('Physique MM:', CurrencyFormatter.formatFCFA(closing.physicalMobileMoneyAmount)));
    buffer.writeln(_formatLine('Ecart MM:', CurrencyFormatter.formatFCFA(closing.mobileMoneyDiscrepancy)));
    buffer.writeln();

    buffer.writeln(_centerText('-' * width));
    buffer.writeln(_formatLine('ECART GLOBAL:', CurrencyFormatter.formatFCFA(closing.discrepancy)));
    buffer.writeln(_centerText('-' * width));
    buffer.writeln();

    if (closing.notes != null && closing.notes!.isNotEmpty) {
      buffer.writeln('Notes:');
      buffer.writeln(closing.notes);
      buffer.writeln();
    }

    buffer.writeln();
    buffer.writeln(_centerText('=' * width));
    buffer.writeln();
    
    // Pied de page
    if (footerText != null && footerText!.isNotEmpty) {
      buffer.writeln(_centerText(footerText!));
    } else {
      buffer.writeln(_centerText('RAPPORT GENERE AVEC SUCCES'));
    }
    buffer.writeln();

    // Espace en bas
    buffer.writeln();
    buffer.writeln();
    buffer.writeln();
    buffer.writeln();

    return buffer.toString().trimRight();
  }

  String _centerText(String text) {
    final truncatedText = text.length > width ? text.substring(0, width) : text;
    final padding = (width - truncatedText.length) ~/ 2;
    return ' ' * padding + truncatedText;
  }

  String _formatLine(String label, String value) {
    final padding = width - label.length - value.length;
    if (padding < 1) return '$label $value';
    return label + ' ' * padding + value;
  }

  String _formatDate(DateTime date) {
    return DateFormatter.formatDate(date);
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}
