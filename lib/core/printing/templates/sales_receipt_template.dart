import '../../../../features/boutique/domain/entities/sale.dart';
import '../../../../shared.dart';

/// Template pour l'impression de factures de vente sur imprimante thermique.
class SalesReceiptTemplate {
  SalesReceiptTemplate(this.sale);

  final Sale sale;

  /// Génère le contenu formaté de la facture pour l'impression thermique.
  String generate() {
    final buffer = StringBuffer();
    
    // En-tête avec nom d'entreprise agrandi et centré
    buffer.writeln(_centerText('══════════════════════'));
    buffer.writeln();
    buffer.writeln();
    // Nom de l'entreprise en caractères plus visibles et centré
    buffer.writeln(_centerText('╔══════════════════════╗'));
    buffer.writeln(_centerText('║    BOUTIQUE ELYF     ║'));
    buffer.writeln(_centerText('║                      ║'));
    buffer.writeln(_centerText('╚══════════════════════╝'));
    buffer.writeln();
    buffer.writeln();
    buffer.writeln(_centerText('══════════════════════'));
    buffer.writeln();
    buffer.writeln();
    
    // Informations de la vente (centrées)
    buffer.writeln(_centerText('Facture N°: ${sale.id}'));
    buffer.writeln(_centerText('Date: ${_formatDate(sale.date)}'));
    buffer.writeln(_centerText('Heure: ${_formatTime(sale.date)}'));
    buffer.writeln();
    
    if (sale.customerName != null && sale.customerName!.isNotEmpty) {
      buffer.writeln(_centerText('Client: ${sale.customerName}'));
      buffer.writeln();
    }
    
    buffer.writeln(_centerText('─' * 26));
    buffer.writeln();
    
    // Articles (centrés)
    buffer.writeln(_centerText('Article    Qté  Prix  Total'));
    buffer.writeln(_centerText('─' * 26));
    buffer.writeln();
    
    for (final item in sale.items) {
      // Tronquer le nom du produit pour tenir dans la largeur (14 caractères max)
      final name = item.productName.length > 14
          ? '${item.productName.substring(0, 11)}...'
          : item.productName;
      buffer.writeln(_centerText(name));
      buffer.writeln(
        _centerText(
          _formatLine(
            '',
            '${item.quantity}x',
            _formatCurrency(item.unitPrice),
            _formatCurrency(item.totalPrice),
          ),
        ),
      );
      buffer.writeln();
    }
    
    buffer.writeln(_centerText('─' * 26));
    buffer.writeln();
    
    // Totaux (centrés)
    buffer.writeln(_centerText('Sous-total: ${_formatCurrency(sale.totalAmount)}'));
    buffer.writeln();
    
    if (sale.paymentMethod != null) {
      final method = _getPaymentMethodLabel(sale.paymentMethod!);
      buffer.writeln(_centerText('Paiement: $method'));
      buffer.writeln();
    }
    
    buffer.writeln(_centerText('Montant payé: ${_formatCurrency(sale.amountPaid)}'));
    buffer.writeln();
    
    if (sale.change > 0) {
      buffer.writeln(_centerText('Monnaie: ${_formatCurrency(sale.change)}'));
      buffer.writeln();
    }
    
    buffer.writeln();
    buffer.writeln(_centerText('═' * 26));
    buffer.writeln();
    buffer.writeln(_centerText('MERCI DE VOTRE VISITE !'));
    buffer.writeln();
    
    // Espace en bas pour éviter que le texte soit coupé
    buffer.writeln();
    buffer.writeln();
    buffer.writeln();
    buffer.writeln();
    buffer.writeln();
    buffer.writeln();
    
    return buffer.toString().trimRight();
  }

  String _centerText(String text) {
    // Largeur pour imprimante thermique 58mm (environ 30 caractères max)
    const width = 30;
    // Tronquer le texte s'il est trop long
    final truncatedText = text.length > width ? text.substring(0, width) : text;
    final padding = (width - truncatedText.length) ~/ 2;
    return ' ' * padding + truncatedText;
  }

  String _alignRight(String text) {
    const width = 32;
    if (text.length >= width) return text.substring(0, width);
    return ' ' * (width - text.length) + text;
  }

  String _formatLine(String col1, String col2, String col3, String col4) {
    // Ajuster les largeurs pour tenir dans 30 caractères max
    const col1Width = 12;
    const col2Width = 3;
    const col3Width = 6;
    const col4Width = 7;
    
    final col1Formatted = col1.length > col1Width 
        ? col1.substring(0, col1Width)
        : col1.padRight(col1Width);
    final col2Formatted = col2.padLeft(col2Width);
    final col3Formatted = col3.padLeft(col3Width);
    final col4Formatted = col4.padLeft(col4Width);
    
    return '$col1Formatted $col2Formatted $col3Formatted $col4Formatted';
  }

  String _formatDate(DateTime date) {
    return DateFormatter.formatDate(date);
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatCurrency(int amount) {
    // Utiliser CurrencyFormatter mais avec " F" au lieu de " FCFA" pour l'impression
    return CurrencyFormatter.formatFCFA(amount).replaceAll(' FCFA', ' F');
  }

  String _getPaymentMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Espèces';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
    }
  }
}

