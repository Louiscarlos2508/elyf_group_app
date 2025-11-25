import '../../../../features/boutique/domain/entities/sale.dart';

/// Template pour l'impression de factures de vente sur imprimante thermique.
class SalesReceiptTemplate {
  SalesReceiptTemplate(this.sale);

  final Sale sale;

  /// Génère le contenu formaté de la facture pour l'impression thermique.
  String generate() {
    final buffer = StringBuffer();
    
    // Espace en haut
    buffer.writeln();
    buffer.writeln();
    
    // En-tête avec nom d'entreprise agrandi et centré
    buffer.writeln(_centerText('═══════════════════════'));
    buffer.writeln();
    buffer.writeln();
    // Nom de l'entreprise en caractères plus visibles et centré
    buffer.writeln(_centerText('╔═══════════════════════╗'));
    buffer.writeln(_centerText('║   BOUTIQUE ELYF       ║'));
    buffer.writeln(_centerText('║      GROUPE           ║'));
    buffer.writeln(_centerText('╚═══════════════════════╝'));
    buffer.writeln();
    buffer.writeln();
    buffer.writeln(_centerText('═══════════════════════'));
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
    
    buffer.writeln(_centerText('─' * 24));
    buffer.writeln();
    
    // Articles (centrés)
    buffer.writeln(_centerText('Article          Qté   Prix   Total'));
    buffer.writeln(_centerText('─' * 24));
    buffer.writeln();
    
    for (final item in sale.items) {
      final name = item.productName.length > 16
          ? '${item.productName.substring(0, 13)}...'
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
    
    buffer.writeln(_centerText('─' * 24));
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
    buffer.writeln(_centerText('═' * 24));
    buffer.writeln();
    buffer.writeln(_centerText('MERCI DE VOTRE VISITE !'));
    buffer.writeln();
    buffer.writeln(_centerText('www.elyfgroupe.com'));
    buffer.writeln();
    
    // Espace en bas pour éviter que le texte soit coupé
    buffer.writeln();
    buffer.writeln();
    buffer.writeln();
    buffer.writeln();
    buffer.writeln();
    buffer.writeln();
    buffer.writeln();
    buffer.writeln();
    
    return buffer.toString();
  }

  String _centerText(String text) {
    // Largeur pour imprimante thermique 58mm (environ 32 caractères)
    const width = 32;
    if (text.length >= width) return text.substring(0, width);
    final padding = (width - text.length) ~/ 2;
    return ' ' * padding + text;
  }

  String _alignRight(String text) {
    const width = 32;
    if (text.length >= width) return text.substring(0, width);
    return ' ' * (width - text.length) + text;
  }

  String _formatLine(String col1, String col2, String col3, String col4) {
    const col1Width = 18;
    const col2Width = 4;
    const col3Width = 5;
    const col4Width = 5;
    
    final col1Formatted = col1.padRight(col1Width).substring(0, col1Width);
    final col2Formatted = col2.padLeft(col2Width);
    final col3Formatted = col3.padLeft(col3Width);
    final col4Formatted = col4.padLeft(col4Width);
    
    return '$col1Formatted $col2Formatted $col3Formatted $col4Formatted';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        ) + ' F';
  }

  String _getPaymentMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Espèces';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.card:
        return 'Carte';
      case PaymentMethod.credit:
        return 'Crédit';
    }
  }
}

