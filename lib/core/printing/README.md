# Core › Printing

Service d'impression pour l'imprimante thermique Sunmi V3 Mix.

## Structure

- `sunmi_v3_service.dart` – Service singleton pour la détection et l'impression.
- `templates/sales_receipt_template.dart` – Template de facture pour les ventes boutique.
- `widgets/print_receipt_button.dart` – Bouton d'impression avec détection automatique.

## Utilisation

Le service détecte automatiquement si l'app tourne sur un appareil Sunmi.
Le bouton d'impression n'apparaît que si un appareil Sunmi est détecté.

## Implémentation future

Pour une implémentation complète avec le SDK Sunmi réel, ajouter le package `sunmi_printer_plus` 
et remplacer les méthodes TODO dans `sunmi_v3_service.dart` par les appels SDK réels.

### Exemple d'intégration SDK (à faire) :

```dart
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';

Future<bool> printReceipt(String content) async {
  final printer = SunmiPrinter();
  await printer.initPrinter();
  await printer.printText(content);
  await printer.cutPaper();
  await printer.closePrinter();
  return true;
}
```

