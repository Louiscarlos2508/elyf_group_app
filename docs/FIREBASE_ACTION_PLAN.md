# Plan d'Action Firebase - Complétion Intégration

## 📊 État Actuel (Janvier 2025)

### ✅ Complété
- **Services wrappers** : Tous les 4 services existent et sont bien implémentés
  - `FirestoreService` - CRUD complet avec multi-tenant
  - `FunctionsService` - Appels Cloud Functions avec retry
  - `MessagingService` - FCM complet avec topics
  - `StorageService` - Upload/download fichiers
- **Firebase Auth** : Utilisé via `firebase_auth` dans `AuthService`

### 🚨 À Faire (Critique)
1. Initialiser FCM dans bootstrap
2. Versionner règles Firestore
3. Intégrer Analytics & Crashlytics
4. Utiliser Cloud Functions
5. Configuration multi-environnements

---

## 1. Initialiser FCM (1 jour) ⚡ PRIORITÉ HAUTE

### Objectif
Initialiser `MessagingService` au démarrage de l'application pour activer les notifications push.

### Étapes

#### 1.1 Créer handlers de notifications
```dart
// lib/core/firebase/fcm_handlers.dart
Future<void> onMessage(RemoteMessage message) async {
  // Notification reçue en foreground
  NotificationService.showLocalNotification(
    title: message.notification?.title ?? 'Notification',
    body: message.notification?.body ?? '',
  );
}

Future<void> onMessageOpenedApp(RemoteMessage message) async {
  // App ouverte depuis une notification
  // Navigation vers l'écran approprié
}

@pragma('vm:entry-point')
Future<void> onBackgroundMessage(RemoteMessage message) async {
  // Notification reçue en background
  // Pas besoin de UI ici
}
```

#### 1.2 Modifier bootstrap.dart
```dart
// Ajouter après Firebase.initializeApp()
final messaging = FirebaseMessaging.instance;
final messagingService = MessagingService(messaging: messaging);

await messagingService.initialize(
  onMessage: onMessage,
  onMessageOpenedApp: onMessageOpenedApp,
  onBackgroundMessage: onBackgroundMessage,
);

// Récupérer enterpriseId et moduleId depuis le contexte
// S'abonner aux topics appropriés
final enterpriseId = /* récupérer depuis tenant context */;
await messagingService.subscribeToTopic(
  enterpriseId: enterpriseId,
  moduleId: null, // ou moduleId si disponible
);
```

#### 1.3 Enregistrer le token FCM dans Firestore
```dart
final token = await messagingService.getToken();
if (token != null && enterpriseId != null) {
  await FirestoreService(firestore: FirebaseFirestore.instance).setDocument(
    collectionName: 'user_devices',
    documentId: deviceId, // UUID unique par appareil
    enterpriseId: enterpriseId,
    data: {
      'fcmToken': token,
      'userId': currentUserId,
      'deviceInfo': Platform.operatingSystem,
      'updatedAt': FieldValue.serverTimestamp(),
    },
  );
}
```

### Checklist
- [ ] Créer `fcm_handlers.dart`
- [ ] Modifier `bootstrap.dart` pour initialiser FCM
- [ ] Tester notifications foreground
- [ ] Tester notifications background
- [ ] Tester ouverture app depuis notification
- [ ] Enregistrer tokens dans Firestore

---

## 2. Versionner Règles Firestore (1-2 jours) 🔒 PRIORITÉ HAUTE

### Objectif
Créer et versionner les règles de sécurité Firestore pour isoler les données par entreprise et module.

### Structure des règles

#### 2.1 Créer `firestore.rules`
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function getUserId() {
      return request.auth.uid;
    }
    
    function isSameEnterprise(enterpriseId) {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/users/$(getUserId())).data.enterpriseId == enterpriseId;
    }
    
    // Users collection - users can only read their own data
    match /users/{userId} {
      allow read: if isAuthenticated() && request.auth.uid == userId;
      allow write: if false; // Only via Cloud Functions or Admin SDK
    }
    
    // Enterprises collection
    match /enterprises/{enterpriseId} {
      // Users can read their own enterprise
      allow read: if isAuthenticated() && isSameEnterprise(enterpriseId);
      allow write: if false; // Only via Admin SDK
      
      // Modules subcollection
      match /modules/{moduleId}/collections/{collection}/{document=**} {
        allow read: if isAuthenticated() && isSameEnterprise(enterpriseId);
        allow write: if isAuthenticated() && isSameEnterprise(enterpriseId);
      }
      
      // Direct collections (without module)
      match /collections/{collection}/{document=**} {
        allow read: if isAuthenticated() && isSameEnterprise(enterpriseId);
        allow write: if isAuthenticated() && isSameEnterprise(enterpriseId);
      }
    }
    
    // User devices for FCM tokens
    match /user_devices/{deviceId} {
      allow read, write: if isAuthenticated() && 
        resource.data.userId == getUserId();
    }
  }
}
```

#### 2.2 Mettre à jour `firebase.json`
```json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "functions": {
    "source": "functions",
    "runtime": "nodejs18"
  }
}
```

#### 2.3 Créer `firestore.indexes.json`
```json
{
  "indexes": [
    {
      "collectionGroup": "sales",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "enterpriseId", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "DESCENDING" }
      ]
    }
  ]
}
```

#### 2.4 Tester les règles
```bash
firebase emulators:start --only firestore
firebase deploy --only firestore:rules
```

### Checklist
- [ ] Créer `firestore.rules` avec sécurité multi-tenant
- [ ] Créer `firestore.indexes.json` pour les index composés
- [ ] Mettre à jour `firebase.json`
- [ ] Tester règles avec emulator
- [ ] Déployer règles en staging
- [ ] Tester avec utilisateurs réels
- [ ] Déployer en production

---

## 3. Intégrer Analytics & Crashlytics (2-3 jours) 📊 PRIORITÉ MOYENNE

### Objectif
Ajouter Firebase Analytics et Crashlytics pour monitoring et observabilité.

### Étapes

#### 3.1 Ajouter dépendances
```yaml
# pubspec.yaml
dependencies:
  firebase_analytics: ^11.0.0
  firebase_crashlytics: ^4.0.0
```

#### 3.2 Créer service Analytics
```dart
// lib/core/firebase/analytics_service.dart
class AnalyticsService {
  final FirebaseAnalytics _analytics;
  
  AnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? FirebaseAnalytics.instance;
  
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
    String? enterpriseId,
    String? moduleId,
  }) async {
    final eventParams = Map<String, Object>.from(parameters ?? {});
    if (enterpriseId != null) eventParams['enterprise_id'] = enterpriseId;
    if (moduleId != null) eventParams['module_id'] = moduleId;
    
    await _analytics.logEvent(
      name: name,
      parameters: eventParams,
    );
  }
  
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    await _analytics.setUserProperty(name: name, value: value);
  }
  
  Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
  }
}
```

#### 3.3 Configurer Crashlytics
```dart
// Dans bootstrap.dart
await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

// Passer les erreurs Flutter à Crashlytics
FlutterError.onError = (errorDetails) {
  FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
};

// Passer les erreurs async à Crashlytics
PlatformDispatcher.instance.onError = (error, stack) {
  FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  return true;
};
```

### Checklist
- [ ] Ajouter dépendances
- [ ] Créer `AnalyticsService`
- [ ] Configurer Crashlytics dans bootstrap
- [ ] Logger événements clés (login, module switch, actions critiques)
- [ ] Tester crash reporting
- [ ] Configurer alertes dans Firebase Console

---

## 4. Utiliser Cloud Functions (7-10 jours) ⚙️ PRIORITÉ MOYENNE

### Objectif
Créer et utiliser des Cloud Functions pour la logique serveur (calculs complexes, validations, etc.).

### Exemple de fonction

#### 4.1 Créer structure functions
```
functions/
  src/
    index.ts
    modules/
      eau_minerale.ts
      gaz.ts
      orange_money.ts
  package.json
  tsconfig.json
```

#### 4.2 Exemple fonction
```typescript
// functions/src/modules/eau_minerale.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const calculateMonthlyReport = functions.https.onCall(
  async (data, context) => {
    // Vérifier authentification
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    
    const { enterpriseId, moduleId, startDate, endDate } = data;
    
    // Valider permissions
    const userDoc = await admin.firestore()
      .doc(`users/${context.auth.uid}`)
      .get();
    
    if (userDoc.data()?.enterpriseId !== enterpriseId) {
      throw new functions.https.HttpsError('permission-denied', 'Access denied');
    }
    
    // Calculs complexes côté serveur
    const sales = await admin.firestore()
      .collection(`enterprises/${enterpriseId}/modules/${moduleId}/collections/sales`)
      .where('date', '>=', startDate)
      .where('date', '<=', endDate)
      .get();
    
    // Calculer métriques
    const totalRevenue = sales.docs.reduce((sum, doc) => {
      return sum + (doc.data().totalPrice || 0);
    }, 0);
    
    return { totalRevenue, salesCount: sales.size };
  }
);
```

#### 4.3 Appeler depuis l'app
```dart
// Dans un provider ou service
final functionsService = FunctionsService(
  functions: FirebaseFunctions.instance,
);

final result = await functionsService.callFunction(
  functionName: 'calculateMonthlyReport',
  data: {
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
  },
  enterpriseId: enterpriseId,
  moduleId: 'eau_minerale',
);
```

### Checklist
- [ ] Initialiser functions avec `firebase init functions`
- [ ] Créer fonction exemple (calcul rapport)
- [ ] Déployer fonction en staging
- [ ] Appeler depuis l'app
- [ ] Tester avec données réelles
- [ ] Créer autres fonctions selon besoins

---

## 5. Configuration Multi-Environnements (2-3 jours) 🌍 PRIORITÉ MOYENNE

### Objectif
Séparer dev, staging et production avec des projets Firebase distincts.

### Structure

#### 5.1 Créer fichiers de configuration
```
lib/config/
  firebase_config.dart
  firebase_config_dev.dart
  firebase_config_staging.dart
  firebase_config_prod.dart
```

#### 5.2 Configuration
```dart
// lib/config/firebase_config.dart
abstract class FirebaseConfig {
  String get projectId;
  String get apiKey;
  String get appId;
  String get messagingSenderId;
}

class DevFirebaseConfig implements FirebaseConfig {
  @override
  String get projectId => 'elyf-group-app-dev';
  // ...
}

class StagingFirebaseConfig implements FirebaseConfig {
  @override
  String get projectId => 'elyf-group-app-staging';
  // ...
}

class ProdFirebaseConfig implements FirebaseConfig {
  @override
  String get projectId => 'elyf-group-app';
  // ...
}
```

#### 5.3 Utiliser dans bootstrap
```dart
FirebaseConfig config;
if (kDebugMode) {
  config = DevFirebaseConfig();
} else if (dotenv.env['ENVIRONMENT'] == 'staging') {
  config = StagingFirebaseConfig();
} else {
  config = ProdFirebaseConfig();
}

await Firebase.initializeApp(
  options: DefaultFirebaseOptions.fromConfig(config),
);
```

### Checklist
- [ ] Créer projets Firebase pour dev/staging
- [ ] Créer fichiers de configuration
- [ ] Modifier bootstrap pour utiliser config dynamique
- [ ] Tester avec chaque environnement
- [ ] Documenter processus de déploiement

---

## Priorisation Recommandée

### Sprint 1 (Semaine 1) - 🔴 Critique
1. ✅ Initialiser FCM (1 jour)
2. ✅ Versionner règles Firestore (2 jours)

### Sprint 2 (Semaine 2-3) - 🟠 Important
3. ✅ Intégrer Analytics & Crashlytics (3 jours)
4. ✅ Configuration multi-environnements (3 jours)

### Sprint 3 (Semaines 4-5) - 🟡 Amélioration
5. ✅ Utiliser Cloud Functions (10 jours)

---

## Ressources
- [Firebase Flutter Documentation](https://firebase.flutter.dev/)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Cloud Functions TypeScript](https://firebase.google.com/docs/functions/typescript)
- [Firebase Analytics](https://firebase.google.com/docs/analytics)

