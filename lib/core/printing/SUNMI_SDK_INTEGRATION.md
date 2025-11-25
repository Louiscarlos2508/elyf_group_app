# Intégration de l'imprimante Sunmi V3 Mix

## Package utilisé

Le projet utilise le package officiel **`sunmi_flutter_plugin_printer`** qui simplifie l'intégration avec les imprimantes Sunmi.

## Installation

Le package est déjà ajouté dans `pubspec.yaml` :

```yaml
dependencies:
  sunmi_flutter_plugin_printer: ^1.0.7+7
```

Exécutez :
```bash
flutter pub get
```

## Architecture du SDK

Le SDK Sunmi utilise une architecture basée sur des APIs spécialisées :

- **QueryApi** : Interface de requête pour vérifier l'état de l'imprimante
- **LineApi** : Interface pour l'impression de factures (小票打印接口)
- **CommandApi** : Interface d'impression par commandes
- **CanvasApi** : Interface pour l'impression de labels
- **CashDrawerApi** : Interface pour contrôler le tiroir-caisse

## Utilisation

Le service `SunmiV3Service` gère automatiquement :

### 1. Initialisation
- Utilise `getPrinter(PrinterListener)` pour obtenir le printer par défaut
- Active les logs de développement (désactiver en production)
- Stocke le printer dans une variable privée

### 2. Vérification de disponibilité
- Utilise `QueryApi.getPrinterStatus()` pour vérifier l'état
- Status 0 = OK, autres valeurs = erreur

### 3. Impression de factures
- Utilise `LineApi.printText()` pour imprimer ligne par ligne
- Utilise `LineApi.cutPaper()` pour couper le papier après impression

### 4. Tiroir-caisse
- Utilise `CashDrawerApi.openCashDrawer()` pour ouvrir le tiroir

### 5. Configuration
- Utilise `startSettings(SettingItem)` pour ouvrir les paramètres système
- Types disponibles : TYPE, DENSITY, PAPER, FONT, ALL

### 6. Libération des ressources
- Utilise `destroy()` pour libérer les ressources quand le service n'est plus utilisé

## Fonctionnalités

### Détection automatique
Le service détecte automatiquement si l'app tourne sur un appareil Sunmi via `device_info_plus`.

### Impression de factures
Le template `SalesReceiptTemplate` formate les factures pour l'impression thermique (58mm).

### Bouton d'impression
Le widget `PrintReceiptButton` apparaît automatiquement après une vente réussie, uniquement sur les appareils Sunmi.

## Exemple d'utilisation

```dart
// Vérifier si l'appareil est Sunmi
final isSunmi = await SunmiV3Service.instance.isSunmiDevice;

// Vérifier si l'imprimante est disponible
final available = await SunmiV3Service.instance.isPrinterAvailable();

// Imprimer une facture
final content = SalesReceiptTemplate.format(sale);
final success = await SunmiV3Service.instance.printReceipt(content);

// Ouvrir le tiroir-caisse
await SunmiV3Service.instance.openCashDrawer();

// Ouvrir les paramètres
await SunmiV3Service.instance.openPrinterSettings(SettingItem.DENSITY);

// Libérer les ressources (à la fermeture de l'app)
await SunmiV3Service.instance.destroy();
```

## Documentation

- Package pub.dev : https://pub.dev/packages/sunmi_flutter_plugin_printer
- Documentation Sunmi : https://developer.sunmi.com/docs/en-US/thermoprinter

## Notes importantes

- L'imprimante doit être initialisée avant la première utilisation (géré automatiquement)
- Le service vérifie automatiquement l'état de l'imprimante avant d'imprimer
- Les logs sont activés en développement (désactiver en production)
- Le SDK doit être libéré avec `destroy()` quand l'app se ferme
- Certaines fonctionnalités nécessitent le service d'impression Sunmi version 6.6.32+
- Le SDK est compatible avec tous les appareils Sunmi (vérifier la version système)

