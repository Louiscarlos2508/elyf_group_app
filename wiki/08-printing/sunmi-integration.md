# Intégration Sunmi V3

Guide sur l'intégration de l'imprimante thermique Sunmi V3 Mix dans ELYF Group App.

## Vue d'ensemble

L'application supporte l'impression thermique via l'imprimante Sunmi V3 Mix intégrée dans certains appareils Android.

## Configuration

### Dépendance

Le package `sunmi_flutter_plugin_printer` est déjà inclus dans `pubspec.yaml`.

### Détection automatique

Le service détecte automatiquement si l'appareil est un Sunmi :

```dart
// lib/core/printing/sunmi_v3_service.dart
class SunmiV3Service {
  static bool _isSunmiDevice = false;
  
  static Future<bool> isSunmiDevice() async {
    if (_isSunmiDevice) return true;
    
    try {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      _isSunmiDevice = deviceInfo.manufacturer.toLowerCase() == 'sunmi';
      return _isSunmiDevice;
    } catch (e) {
      return false;
    }
  }
}
```

## Utilisation

### Service d'impression

```dart
// lib/core/printing/sunmi_v3_service.dart
class SunmiV3Service {
  static Future<bool> printReceipt(String content) async {
    if (!await isSunmiDevice()) {
      developer.log('Not a Sunmi device');
      return false;
    }
    
    try {
      // TODO: Implémenter avec le SDK réel
      // await SunmiPrinter.initPrinter();
      // await SunmiPrinter.printText(content);
      // await SunmiPrinter.cutPaper();
      // await SunmiPrinter.closePrinter();
      
      return true;
    } catch (e) {
      developer.log('Print error', error: e);
      return false;
    }
  }
}
```

### Widget d'impression

```dart
// lib/core/printing/widgets/print_receipt_button.dart
class PrintReceiptButton extends ConsumerWidget {
  final String receiptContent;
  
  const PrintReceiptButton({
    super.key,
    required this.receiptContent,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSunmi = ref.watch(isSunmiDeviceProvider);
    
    if (!isSunmi) {
      return const SizedBox.shrink();
    }
    
    return IconButton(
      icon: const Icon(Icons.print),
      onPressed: () async {
        final success = await SunmiV3Service.printReceipt(receiptContent);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impression réussie')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur d\'impression')),
          );
        }
      },
    );
  }
}
```

## Templates

### Template de reçu de vente

```dart
// lib/core/printing/templates/sales_receipt_template.dart
class SalesReceiptTemplate {
  static String generate(Sale sale) {
    final buffer = StringBuffer();
    
    // En-tête
    buffer.writeln('=' * 32);
    buffer.writeln('   ELYF GROUP BOUTIQUE');
    buffer.writeln('=' * 32);
    buffer.writeln();
    
    // Informations de la vente
    buffer.writeln('Date: ${DateFormat('dd/MM/yyyy HH:mm').format(sale.date)}');
    buffer.writeln('Vente #${sale.id}');
    buffer.writeln();
    buffer.writeln('-' * 32);
    
    // Articles
    for (final item in sale.items) {
      buffer.writeln('${item.productName}');
      buffer.writeln('  ${item.quantity} x ${item.unitPrice} FCFA');
      buffer.writeln('  = ${item.total} FCFA');
      buffer.writeln();
    }
    
    buffer.writeln('-' * 32);
    
    // Total
    buffer.writeln('TOTAL: ${sale.total} FCFA');
    buffer.writeln();
    
    // Mode de paiement
    buffer.writeln('Paiement: ${sale.paymentMethod}');
    buffer.writeln();
    
    // Pied de page
    buffer.writeln('=' * 32);
    buffer.writeln('Merci de votre visite !');
    buffer.writeln('=' * 32);
    
    return buffer.toString();
  }
}
```

## Implémentation complète

### Avec le SDK Sunmi

```dart
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';

Future<bool> printReceipt(String content) async {
  try {
    final printer = SunmiPrinter();
    
    // Initialiser l'imprimante
    await printer.initPrinter();
    
    // Configurer l'alignement
    await printer.setAlignment(SunmiPrintAlign.CENTER);
    
    // Imprimer le contenu
    await printer.printText(content);
    
    // Couper le papier
    await printer.cutPaper();
    
    // Fermer l'imprimante
    await printer.closePrinter();
    
    return true;
  } catch (e) {
    developer.log('Print error', error: e);
    return false;
  }
}
```

## Bonnes pratiques

1. **Détection automatique** – Vérifier si l'appareil est Sunmi
2. **Gestion des erreurs** – Gérer les erreurs d'impression
3. **Templates réutilisables** – Créer des templates pour différents types de reçus
4. **Feedback utilisateur** – Afficher le statut de l'impression
5. **Formatage** – Formater le contenu pour l'impression thermique (largeur 58mm)

## Dépannage

Voir [Dépannage](./troubleshooting.md) pour résoudre les problèmes courants.

## Prochaines étapes

- [Templates d'impression](./templates.md)
- [Dépannage](./troubleshooting.md)
