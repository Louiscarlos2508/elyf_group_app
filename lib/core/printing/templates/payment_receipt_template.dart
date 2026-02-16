import '../thermal_receipt_builder.dart';

/// Template pour l'impression de reçus de paiement sur imprimante thermique Sunmi.
class PaymentReceiptTemplate {
  PaymentReceiptTemplate._();

  /// Génère le contenu du reçu de paiement pour impression thermique.
  static String generateReceipt({
    required String receiptNumber,
    required String paymentDate,
    required String amount,
    required String paymentMethod,
    required String tenantName,
    required String propertyAddress,
    String? period,
    String? notes,
    String? header,
    String? footer,
    bool showLogo = true,
  }) {
    final builder = ThermalReceiptBuilder();

    // Logo / Header
    if (showLogo) {
      builder.center('[ E L Y F ]');
      builder.space();
    }

    builder.header(header ?? 'ELYF GROUPE', subtitle: 'REÇU DE PAIEMENT');

    // Informations du reçu
    builder.row('N°', receiptNumber);
    builder.row('Date', paymentDate);
    if (period != null) {
      builder.row('Période', period);
    }
    builder.separator();

    // Informations du locataire
    builder.row('Locataire', tenantName);
    builder.space();

    // Informations de la propriété
    builder.row('Propriété', propertyAddress);
    builder.separator();

    // Détails du paiement
    builder.row('Montant', '$amount F');
    builder.row('Méthode', paymentMethod);
    builder.doubleSeparator();

    // Notes si présentes
    if (notes != null && notes.isNotEmpty) {
      builder.row('Notes', notes);
      builder.separator();
    }

    // Espace pour signature
    builder.space();
    builder.writeLine('Signature locataire:');
    builder.space(2);
    builder.writeLine('Signature et cachet:');
    builder.space();

    // Pied de page
    builder.footer(footer ?? 'Merci de votre confiance !');

    return builder.toString();
  }
}
