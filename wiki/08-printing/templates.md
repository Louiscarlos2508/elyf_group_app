# Templates d'impression

Guide pour créer des templates d'impression pour l'imprimante Sunmi V3.

## Vue d'ensemble

Les templates d'impression sont des classes qui génèrent le contenu formaté pour l'impression thermique.

## Structure d'un template

### Template de base

```dart
class BaseReceiptTemplate {
  static const int lineWidth = 32; // Largeur en caractères (58mm)
  
  static String generateHeader(String title) {
    final buffer = StringBuffer();
    buffer.writeln('=' * lineWidth);
    buffer.writeln(centerText(title));
    buffer.writeln('=' * lineWidth);
    buffer.writeln();
    return buffer.toString();
  }
  
  static String centerText(String text) {
    final padding = (lineWidth - text.length) ~/ 2;
    return ' ' * padding + text;
  }
  
  static String generateFooter() {
    final buffer = StringBuffer();
    buffer.writeln('=' * lineWidth);
    buffer.writeln(centerText('Merci de votre visite !'));
    buffer.writeln('=' * lineWidth);
    return buffer.toString();
  }
}
```

## Templates disponibles

### Reçu de vente

```dart
// lib/core/printing/templates/sales_receipt_template.dart
class SalesReceiptTemplate {
  static String generate(Sale sale) {
    final buffer = StringBuffer();
    
    // En-tête
    buffer.write(BaseReceiptTemplate.generateHeader('ELYF GROUP BOUTIQUE'));
    
    // Informations
    buffer.writeln('Date: ${DateFormat('dd/MM/yyyy HH:mm').format(sale.date)}');
    buffer.writeln('Vente #${sale.id}');
    buffer.writeln();
    buffer.writeln('-' * 32);
    
    // Articles
    for (final item in sale.items) {
      buffer.writeln(item.productName);
      buffer.writeln('  ${item.quantity} x ${item.unitPrice} FCFA');
      buffer.writeln('  = ${item.total} FCFA');
      buffer.writeln();
    }
    
    buffer.writeln('-' * 32);
    buffer.writeln('TOTAL: ${sale.total} FCFA');
    buffer.writeln();
    buffer.writeln('Paiement: ${sale.paymentMethod}');
    buffer.writeln();
    
    // Pied de page
    buffer.write(BaseReceiptTemplate.generateFooter());
    
    return buffer.toString();
  }
}
```

### Reçu de paiement

```dart
class PaymentReceiptTemplate {
  static String generate(Payment payment) {
    final buffer = StringBuffer();
    
    buffer.write(BaseReceiptTemplate.generateHeader('REÇU DE PAIEMENT'));
    
    buffer.writeln('Date: ${DateFormat('dd/MM/yyyy HH:mm').format(payment.date)}');
    buffer.writeln('Client: ${payment.customerName}');
    buffer.writeln();
    buffer.writeln('-' * 32);
    buffer.writeln('Montant: ${payment.amount} FCFA');
    buffer.writeln('Mode: ${payment.method}');
    buffer.writeln();
    
    if (payment.reference != null) {
      buffer.writeln('Référence: ${payment.reference}');
      buffer.writeln();
    }
    
    buffer.write(BaseReceiptTemplate.generateFooter());
    
    return buffer.toString();
  }
}
```

## Formatage

### Alignement

```dart
static String alignLeft(String text, int width) {
  return text.padRight(width);
}

static String alignRight(String text, int width) {
  return text.padLeft(width);
}

static String alignCenter(String text, int width) {
  final padding = (width - text.length) ~/ 2;
  return ' ' * padding + text;
}
```

### Séparateurs

```dart
static String separator() {
  return '-' * 32;
}

static String doubleSeparator() {
  return '=' * 32;
}
```

### Formatage des montants

```dart
static String formatAmount(double amount) {
  return '${amount.toStringAsFixed(0)} FCFA';
}

static String formatCurrency(double amount) {
  final formatter = NumberFormat('#,###', 'fr_FR');
  return '${formatter.format(amount)} FCFA';
}
```

## Bonnes pratiques

1. **Largeur fixe** – Utiliser 32 caractères pour 58mm
2. **Formatage cohérent** – Format uniforme pour tous les templates
3. **Lisibilité** – Espacement et séparateurs clairs
4. **Informations essentielles** – Inclure uniquement les informations importantes
5. **Test** – Tester l'impression sur l'appareil réel

## Prochaines étapes

- [Intégration Sunmi](./sunmi-integration.md)
- [Dépannage](./troubleshooting.md)
