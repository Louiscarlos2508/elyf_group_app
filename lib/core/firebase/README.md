# Core › Firebase

Services Firebase pour l'application multi-tenant.

## Services disponibles

- `firebase_options.dart` (généré) – Configuration Firebase
- `firestore_user_service.dart` – Service spécialisé pour les utilisateurs
- `firestore_service.dart` ✅ – Service générique pour accès Firestore avec support multi-tenant
- `functions_service.dart` ✅ – Appels Cloud Functions sécurisés avec retry
- `messaging_service.dart` ✅ – FCM + topics par entreprise/module
- `storage_service.dart` ✅ – Gestion upload/download de fichiers avec organisation par entreprise/module

## Utilisation

### FirestoreService

Service générique pour toutes les opérations Firestore avec isolation multi-tenant.

```dart
final firestoreService = FirestoreService(firestore: FirebaseFirestore.instance);

// Créer un document
await firestoreService.setDocument(
  collectionName: 'products',
  documentId: 'prod-123',
  enterpriseId: 'enterprise-1',
  moduleId: 'boutique',
  data: {'name': 'Product', 'price': 100},
);

// Récupérer un document
final product = await firestoreService.getDocument(
  collectionName: 'products',
  documentId: 'prod-123',
  enterpriseId: 'enterprise-1',
  moduleId: 'boutique',
);

// Écouter les changements
firestoreService.watchCollection(
  collectionName: 'products',
  enterpriseId: 'enterprise-1',
  moduleId: 'boutique',
).listen((products) {
  // Mettre à jour l'UI
});
```

### FunctionsService

Service pour appeler les Cloud Functions avec gestion d'erreurs et retry.

```dart
final functionsService = FunctionsService(
  functions: FirebaseFunctions.instance,
);

final result = await functionsService.callFunction(
  functionName: 'calculateTotal',
  data: {'items': [...]},
  enterpriseId: 'enterprise-1',
  moduleId: 'boutique',
);
```

### MessagingService

Service pour gérer les notifications push FCM.

```dart
final messagingService = MessagingService(
  messaging: FirebaseMessaging.instance,
);

await messagingService.initialize(
  onMessage: (message) => _handleMessage(message),
  onMessageOpenedApp: (message) => _handleOpenedApp(message),
  onBackgroundMessage: _backgroundMessageHandler,
);

// S'abonner aux notifications d'une entreprise/module
await messagingService.subscribeToTopic(
  enterpriseId: 'enterprise-1',
  moduleId: 'boutique',
);
```

### StorageService

Service pour upload/download de fichiers.

```dart
final storageService = StorageService(
  storage: FirebaseStorage.instance,
);

// Upload un fichier
final downloadUrl = await storageService.uploadFile(
  file: File('/path/to/file.jpg'),
  fileName: 'receipt-123.jpg',
  enterpriseId: 'enterprise-1',
  moduleId: 'boutique',
  subfolder: 'receipts',
  contentType: 'image/jpeg',
);

// Download un fichier
final bytes = await storageService.downloadFile(
  fileName: 'receipt-123.jpg',
  enterpriseId: 'enterprise-1',
  moduleId: 'boutique',
  subfolder: 'receipts',
);
```

## Structure des chemins

### Firestore
- `enterprises/{enterpriseId}/modules/{moduleId}/collections/{collectionName}/{documentId}`
- `enterprises/{enterpriseId}/collections/{collectionName}/{documentId}` (si pas de module)

### Storage
- `enterprises/{enterpriseId}/modules/{moduleId}/files/{subfolder}/{fileName}`
- `enterprises/{enterpriseId}/files/{subfolder}/{fileName}` (si pas de module)

### Topics FCM
- `enterprise_{enterpriseId}` : Toutes les notifications de l'entreprise
- `enterprise_{enterpriseId}_module_{moduleId}` : Notifications du module spécifique

