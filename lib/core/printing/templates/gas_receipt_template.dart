import '../../../../features/gaz/domain/entities/gas_sale.dart';
import '../../../../shared.dart';

/// Template pour l'impression de factures de vente de gaz sur imprimante thermique.
class GasReceiptTemplate {
  GasReceiptTemplate(this.sale, {this.cylinderLabel});

  final GasSale sale;
  final String? cylinderLabel;

  /// Génère le contenu formaté de la facture pour l'impression thermique.
  String generate() {
    final buffer = StringBuffer();

    // En-tête
    buffer.writeln();
    buffer.writeln(_centerText('GAZ ELYF'));
    buffer.writeln(_centerText('GROUPE APP'));
    buffer.writeln();
    buffer.writeln(_centerText('--------------------------------'));
    buffer.writeln();

    // Informations de la vente
    buffer.writeln(_centerText('Facture N°: ${sale.id.split('-').last}'));
    buffer.writeln(_centerText('Date: ${_formatDate(sale.saleDate)}'));
    buffer.writeln(_centerText('Heure: ${_formatTime(sale.saleDate)}'));
    buffer.writeln();

    if (sale.customerName != null && sale.customerName!.isNotEmpty) {
      buffer.writeln(_centerText('Client: ${sale.customerName}'));
      if (sale.customerPhone != null) {
        buffer.writeln(_centerText('Tél: ${sale.customerPhone}'));
      }
      buffer.writeln();
    }

    buffer.writeln(_centerText('─' * 26));
    buffer.writeln();

    // Article
    buffer.writeln(_centerText('Article    Qté  Prix  Total'));
    buffer.writeln(_centerText('─' * 26));
    buffer.writeln();

    // Type de bouteille (ex: 6kg, 12kg)
    final label = cylinderLabel ?? 'Bouteille ${sale.cylinderId}';
    
    final name = label.length > 14
        ? '${label.substring(0, 11)}...'
        : label;
        
    buffer.writeln(_centerText(name));
    buffer.writeln(
      _centerText(
        _formatLine(
          '',
          '${sale.quantity}x',
          CurrencyFormatter.formatDouble(sale.unitPrice),
          CurrencyFormatter.formatDouble(sale.totalAmount),
        ),
      ),
    );
    buffer.writeln();

    buffer.writeln(_centerText('─' * 26));
    buffer.writeln();

    // Totaux
    buffer.writeln(
      _centerText(
        'TOTAL: ${CurrencyFormatter.formatDouble(sale.totalAmount)}',
      ),
    );
    buffer.writeln();

    if (sale.saleType == SaleType.retail || sale.saleType == SaleType.wholesale) {
      final method = sale.saleType == SaleType.retail ? 'Détail' : 'Gros';
      buffer.writeln(_centerText('Type de vente: $method'));
      buffer.writeln();
    }

    if (sale.wholesalerName != null) {
      buffer.writeln(_centerText('Grossiste: ${sale.wholesalerName}'));
      buffer.writeln();
    }

    buffer.writeln();
    buffer.writeln(_centerText('--------------------------------'));
    buffer.writeln();
    buffer.writeln(_centerText('SERVICE CLIENT: 70 00 00 00'));
    buffer.writeln(_centerText('MERCI DE VOTRE CONFIANCE !'));
    buffer.writeln();

    // Espace en bas pour la découpe
    buffer.writeln();
    buffer.writeln();
    buffer.writeln();
    buffer.writeln();

    return buffer.toString().trimRight();
  }

  String _centerText(String text) {
    const width = 30;
    final truncatedText = text.length > width ? text.substring(0, width) : text;
    final padding = (width - truncatedText.length) ~/ 2;
    return ' ' * padding + truncatedText;
  }

  String _formatLine(String col1, String col2, String col3, String col4) {
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
}
