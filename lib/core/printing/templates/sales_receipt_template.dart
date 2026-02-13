import '../../../../features/boutique/domain/entities/sale.dart';
import '../../../../shared.dart';

/// Template pour l'impression de factures de vente sur imprimante thermique.
class SalesReceiptTemplate {
  SalesReceiptTemplate(
    this.sale, {
    this.width = 32,
    this.headerText,
    this.footerText,
    this.showLogo = true,
  });

  final Sale sale;
  final int width;
  final String? headerText;
  final String? footerText;
  final bool showLogo;

  /// Génère le contenu formaté de la facture pour l'impression thermique.
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
    
    // Sous-titre standard (toujours présent)
    buffer.writeln(_centerText('ELYF GROUPE - POS'));
    buffer.writeln(_centerText('=' * width));
    buffer.writeln();

    // Informations de la vente (centrées)
    buffer.writeln(_centerText('Facture N°: ${sale.number ?? sale.id.substring(0, 8)}'));
    buffer.writeln(_centerText('Date: ${_formatDate(sale.date)}'));
    buffer.writeln(_centerText('Heure: ${_formatTime(sale.date)}'));
    buffer.writeln();

    if (sale.customerName != null && sale.customerName!.isNotEmpty) {
      buffer.writeln(_centerText('Client: ${sale.customerName}'));
      buffer.writeln();
    }

    buffer.writeln(_centerText('-' * width));
    buffer.writeln();

    // Articles
    final col1Width = (width * 0.6).floor(); // 18 for 30, 28 for 48
    final col2Width = (width * 0.15).floor(); // 4 for 30, 7 for 48
    final col3Width = width - col1Width - col2Width - 2; // Total

    final labelHeader = 'Article'.padRight(col1Width);
    final qtyHeader = 'Qté'.padLeft(col2Width);
    final totalHeader = 'Total'.padLeft(col3Width);

    buffer.writeln('$labelHeader $qtyHeader $totalHeader');
    buffer.writeln('-' * width);

    for (final item in sale.items) {
      final name = item.productName.length > col1Width
          ? item.productName.substring(0, col1Width)
          : item.productName.padRight(col1Width);
          
      final qty = item.quantity.toString().padLeft(col2Width);
      final total = CurrencyFormatter.formatFCFA(item.totalPrice).padLeft(col3Width);
      
      buffer.writeln('$name $qty $total');
    }

    buffer.writeln('-' * width);
    buffer.writeln();

    // Totaux (centrés)
    buffer.writeln(
      _centerText(
        'Sous-total: ${CurrencyFormatter.formatFCFA(sale.totalAmount)}',
      ),
    );
    buffer.writeln();

    if (sale.paymentMethod != null) {
      final method = _getPaymentMethodLabel(sale.paymentMethod!);
      buffer.writeln(_centerText('Paiement: $method'));
      buffer.writeln();
    }

    buffer.writeln(
      _centerText(
        'Montant payé: ${CurrencyFormatter.formatFCFA(sale.amountPaid)}',
      ),
    );
    buffer.writeln();

    if (sale.change > 0) {
      buffer.writeln(
        _centerText('Monnaie: ${CurrencyFormatter.formatFCFA(sale.change)}'),
      );
      buffer.writeln();
    }

    buffer.writeln();
    buffer.writeln(_centerText('=' * width));
    buffer.writeln();
    
    // Pied de page
    if (footerText != null && footerText!.isNotEmpty) {
      buffer.writeln(_centerText(footerText!));
    } else {
      buffer.writeln(_centerText('MERCI DE VOTRE VISITE !'));
    }
    buffer.writeln();


    // Espace en bas pour la découpe
    buffer.writeln();
    buffer.writeln();
    buffer.writeln();
    buffer.writeln();

    return buffer.toString().trimRight();
  }

  String _centerText(String text) {
    // Largeur dynamique
    // Tronquer le texte s'il est trop long
    final truncatedText = text.length > width ? text.substring(0, width) : text;
    final padding = (width - truncatedText.length) ~/ 2;
    return ' ' * padding + truncatedText;
  }

  String _formatDate(DateTime date) {
    return DateFormatter.formatDate(date);
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String _getPaymentMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Espèces';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.both:
        return 'Mixte (Espèces + Mobile Money)';
      case PaymentMethod.card:
        return 'Carte Bancaire';
    }
  }
}
