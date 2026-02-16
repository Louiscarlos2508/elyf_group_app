import '../../../../features/gaz/domain/entities/gas_sale.dart';
import '../../../../shared.dart';
import '../thermal_receipt_builder.dart';

/// Template pour l'impression de factures de vente de gaz sur imprimante thermique.
class GasReceiptTemplate {
  GasReceiptTemplate(this.sale, {this.cylinderLabel});

  final GasSale sale;
  final String? cylinderLabel;

  /// Génère le contenu formaté de la facture pour l'impression thermique.
  String generate() {
    final builder = ThermalReceiptBuilder(width: 48); // Format 80mm

    // En-tête
    builder.header('GAZ ELYF', subtitle: 'GROUPE APP');

    // Informations de la vente
    builder.row('Facture N°', sale.id.split('-').last);
    builder.row('Date', _formatDate(sale.saleDate));
    builder.row('Heure', _formatTime(sale.saleDate));
    builder.space();

    if (sale.customerName != null && sale.customerName!.isNotEmpty) {
      builder.row('Client', sale.customerName!);
      if (sale.customerPhone != null) {
        builder.row('Tél', sale.customerPhone!);
      }
      builder.space();
    }

    // Article
    builder.section('Détail Vente');
    
    // Type de bouteille (ex: 6kg, 12kg)
    final label = cylinderLabel ?? 'Bouteille ${sale.cylinderId}';
    final priceDetail = '${sale.quantity}x ${CurrencyFormatter.formatDouble(sale.unitPrice)}';
    final totalDetail = CurrencyFormatter.formatDouble(sale.totalAmount);
    
    builder.itemRow(label, priceDetail, totalDetail);
    builder.separator();

    // Totaux
    builder.total('TOTAL', CurrencyFormatter.formatDouble(sale.totalAmount));

    if (sale.saleType == SaleType.retail || sale.saleType == SaleType.wholesale) {
      final method = sale.saleType == SaleType.retail ? 'Détail' : 'Gros';
      builder.row('Type de vente', method);
    }

    if (sale.wholesalerName != null) {
      builder.row('Grossiste', sale.wholesalerName!);
    }

    builder.space();
    builder.row('SERVICE CLIENT', '70 00 00 00');
    
    // Pied de page
    builder.footer('MERCI DE VOTRE CONFIANCE !');

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
