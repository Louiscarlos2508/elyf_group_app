# Dépannage - Impression

Guide pour résoudre les problèmes courants d'impression avec Sunmi V3.

## Problèmes courants

### L'imprimante n'est pas détectée

**Symptômes :**
- Le bouton d'impression n'apparaît pas
- Erreur "Not a Sunmi device"

**Solutions :**

1. Vérifier que l'appareil est bien un Sunmi :
   ```dart
   final deviceInfo = await DeviceInfoPlugin().androidInfo;
   print('Manufacturer: ${deviceInfo.manufacturer}');
   ```

2. Vérifier les permissions dans `AndroidManifest.xml` :
   ```xml
   <uses-permission android:name="android.permission.BLUETOOTH" />
   <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
   ```

3. Redémarrer l'application

### Erreur d'impression

**Symptômes :**
- L'impression échoue
- Message d'erreur affiché

**Solutions :**

1. Vérifier que l'imprimante est allumée
2. Vérifier le papier dans l'imprimante
3. Vérifier la connexion USB (si applicable)
4. Redémarrer l'imprimante
5. Vérifier les logs :
   ```dart
   developer.log('Print error', error: error, stackTrace: stackTrace);
   ```

### Impression incomplète

**Symptômes :**
- Seule une partie du contenu est imprimée
- Le contenu est tronqué

**Solutions :**

1. Vérifier la largeur du template (32 caractères pour 58mm)
2. Vérifier que le contenu ne dépasse pas la largeur
3. Utiliser des retours à la ligne appropriés
4. Tester avec un contenu plus court

### Formatage incorrect

**Symptômes :**
- Le texte n'est pas aligné correctement
- Les colonnes ne sont pas alignées

**Solutions :**

1. Utiliser des largeurs fixes pour les colonnes
2. Utiliser `padLeft` et `padRight` pour l'alignement
3. Tester l'alignement avec différents contenus
4. Vérifier les espaces et caractères spéciaux

### Lenteur d'impression

**Symptômes :**
- L'impression prend beaucoup de temps
- L'application se bloque pendant l'impression

**Solutions :**

1. Effectuer l'impression en arrière-plan :
   ```dart
   unawaited(
     compute(_printInBackground, receiptContent),
   );
   ```

2. Afficher un indicateur de chargement
3. Optimiser le contenu du template
4. Réduire la quantité de données imprimées

## Vérifications

### Checklist de dépannage

- [ ] L'appareil est bien un Sunmi
- [ ] L'imprimante est allumée
- [ ] Il y a du papier dans l'imprimante
- [ ] Les permissions sont accordées
- [ ] Le SDK Sunmi est correctement intégré
- [ ] Le template est correctement formaté
- [ ] Les logs ne montrent pas d'erreurs

### Tests

```dart
// Test de détection
final isSunmi = await SunmiV3Service.isSunmiDevice();
print('Is Sunmi: $isSunmi');

// Test d'impression simple
final success = await SunmiV3Service.printReceipt('Test');
print('Print success: $success');
```

## Support

En cas de problème persistant :

1. Consulter la documentation Sunmi
2. Vérifier les logs de l'application
3. Contacter le support technique
4. Vérifier les mises à jour du SDK

## Prochaines étapes

- [Intégration Sunmi](./sunmi-integration.md)
- [Templates d'impression](./templates.md)
