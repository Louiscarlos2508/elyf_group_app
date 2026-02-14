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
    final width = 30; // Largeur pour imprimante 58mm
    final lines = <String>[];

    // Fonction pour centrer le texte
    String centerText(String text) {
      if (text.length >= width) return text.substring(0, width);
      final padding = (width - text.length) ~/ 2;
      return ' ' * padding + text;
    }

    // Fonction pour créer une ligne de séparation
    String separator(String char) => char * 26;

    // Logo
    if (showLogo) {
      lines.add(centerText(' [ E L Y F ] '));
      lines.add('');
    }

    // En-tête simplifié
    lines.add(centerText(header ?? 'ELYF GROUPE'));
    lines.add('');
    lines.add(centerText(separator('-')));
    lines.add('');
    lines.add(centerText('REÇU DE PAIEMENT'));
    lines.add(centerText(separator('=')));
    lines.add('');

    // Informations du reçu
    lines.add('N°: $receiptNumber');
    lines.add('Date: $paymentDate');
    if (period != null) {
      lines.add('Période: $period');
    }
    lines.add(separator('─'));

    // Informations du locataire
    lines.add('Locataire:');
    lines.add(tenantName);
    lines.add('');

    // Informations de la propriété
    lines.add('Propriété:');
    if (propertyAddress.length > width - 2) {
      lines.add(propertyAddress.substring(0, width - 2));
    } else {
      lines.add(propertyAddress);
    }
    lines.add(separator('─'));

    // Détails du paiement
    lines.add('Montant: $amount F');
    lines.add('Méthode: $paymentMethod');
    lines.add(separator('═'));

    // Notes si présentes
    if (notes != null && notes.isNotEmpty) {
      lines.add('Notes:');
      if (notes.length > width - 2) {
        final words = notes.split(' ');
        String currentLine = '';
        for (final word in words) {
          if ((currentLine + word).length < width - 2) {
            currentLine += (currentLine.isEmpty ? '' : ' ') + word;
          } else {
            if (currentLine.isNotEmpty) lines.add(currentLine);
            currentLine = word;
          }
        }
        if (currentLine.isNotEmpty) lines.add(currentLine);
      } else {
        lines.add(notes);
      }
      lines.add(separator('─'));
    }

    // Espace pour signature
    lines.add('');
    lines.add('Signature locataire:');
    lines.add('');
    lines.add('');
    lines.add('Signature et cachet:');
    lines.add('');

    // Pied de page
    if (footer != null && footer.isNotEmpty) {
      final footerLines = footer.split('\n');
      for (final fl in footerLines) {
        lines.add(centerText(fl));
      }
    } else {
      lines.add(centerText('Merci de votre'));
      lines.add(centerText('confiance !'));
    }
    lines.add('');

    // Ajouter des lignes vides à la fin pour la découpe
    for (int i = 0; i < 4; i++) {
      lines.add('');
    }

    return lines.join('\n');
  }
}
