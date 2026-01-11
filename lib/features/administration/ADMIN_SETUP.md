# Configuration de l'Utilisateur Admin

## Problème : Permission Denied lors de la création de rôles

Si vous rencontrez une erreur "Permission denied" lors de la création de rôles, c'est parce que votre utilisateur admin n'a pas les permissions nécessaires dans Firestore.

## Solution 1 : Vérifier et mettre à jour l'utilisateur dans Firestore

1. **Vérifier que l'utilisateur existe dans Firestore** :
   - Ouvrez Firebase Console
   - Allez dans Firestore Database
   - Collection : `users`
   - Recherchez votre utilisateur (ID Firebase Auth ou email)

2. **Vérifier que le flag `isAdmin` est à `true`** :
   ```json
   {
     "id": "votre-user-id",
     "email": "admin@elyf.com",
     "firstName": "Admin",
     "lastName": "System",
     "username": "admin",
     "isActive": true,
     "isAdmin": true  // ⚠️ Doit être true
   }
   ```

3. **Si l'utilisateur n'existe pas ou n'a pas `isAdmin: true`** :
   - Créez ou modifiez le document dans Firestore
   - Ajoutez `isAdmin: true`
   - Si l'utilisateur n'existe pas, utilisez l'ID Firebase Auth comme document ID

## Solution 2 : Configurer les règles de sécurité Firestore

Assurez-vous que les règles Firestore permettent aux admins de créer/modifier des rôles :

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper function pour vérifier si l'utilisateur est admin
    function isAdmin() {
      return request.auth != null && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }
    
    // Collection roles - accessible aux admins
    match /roles/{roleId} {
      allow read: if request.auth != null;
      allow write: if isAdmin();
    }
    
    // Collection users - accessible aux admins
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if isAdmin() || request.auth.uid == userId;
    }
    
    // Collection enterprise_module_users - accessible aux admins
    match /enterprise_module_users/{documentId} {
      allow read: if request.auth != null;
      allow write: if isAdmin();
    }
  }
}
```

## Solution 3 : Utiliser Cloud Functions pour initialiser l'admin

Si vous ne pouvez pas modifier Firestore manuellement, créez une Cloud Function :

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.initializeAdmin = functions.https.onCall(async (data, context) => {
  // Vérifier que l'appel est authentifié
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }
  
  const adminEmail = data.email || 'admin@elyf.com';
  const userId = context.auth.uid;
  
  // Vérifier que c'est le premier utilisateur ou l'email admin
  const usersRef = admin.firestore().collection('users');
  const adminsSnapshot = await usersRef.where('isAdmin', '==', true).limit(1).get();
  
  const isFirstAdmin = adminsSnapshot.empty;
  const shouldBeAdmin = isFirstAdmin || context.auth.token.email === adminEmail;
  
  if (shouldBeAdmin) {
    await usersRef.doc(userId).set({
      id: userId,
      email: context.auth.token.email,
      firstName: 'Admin',
      lastName: 'System',
      username: context.auth.token.email.split('@')[0],
      isActive: true,
      isAdmin: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    
    return { success: true, message: 'Admin initialized successfully' };
  }
  
  throw new functions.https.HttpsError('permission-denied', 'Cannot initialize admin');
});
```

## Solution 4 : Initialiser via l'application (recommandé pour développement)

L'application essaie déjà d'initialiser l'admin automatiquement lors de la première connexion avec `admin@elyf.com`. 

Si cela ne fonctionne pas, vérifiez :

1. **Que l'utilisateur Firebase Auth existe** :
   - Firebase Console → Authentication
   - Vérifiez que `admin@elyf.com` existe

2. **Que les règles Firestore permettent la création** :
   - Temporairement, utilisez des règles permissives pour le développement :
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if request.auth != null;
       }
     }
   }
   ```
   ⚠️ **Attention** : Ces règles sont permissives et ne doivent être utilisées que pour le développement !

## Vérification

Après avoir configuré l'admin, vérifiez que :

1. ✅ L'utilisateur existe dans Firestore avec `isAdmin: true`
2. ✅ Les règles Firestore permettent l'écriture pour les admins
3. ✅ Vous êtes connecté avec `admin@elyf.com`
4. ✅ L'application affiche votre statut admin (vérifiez via `isAdminProvider`)

## Dépannage

Si le problème persiste :

1. **Déconnectez-vous et reconnectez-vous** pour recharger les données utilisateur
2. **Vérifiez les logs Firebase** dans la console pour voir les erreurs exactes
3. **Vérifiez les règles Firestore** avec l'émulateur Firestore pour tester localement
4. **Utilisez le DebugView dans Firebase Console** pour voir les requêtes Firestore

## Notes importantes

- Le flag `isAdmin` dans Firestore est vérifié par `PermissionValidatorService`
- Les erreurs de permission sont maintenant affichées avec `NotificationService` dans l'application
- Les messages d'erreur indiquent clairement ce qui manque (permissions Firestore, règles, etc.)

