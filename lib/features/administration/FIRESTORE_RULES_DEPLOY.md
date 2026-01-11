# Déploiement des Règles Firestore

## 📋 Modes disponibles

### Mode Test (actuel - `firestore.rules`)
- **Règles très permissives** : Tous les utilisateurs authentifiés peuvent lire/écrire toutes les collections
- **Utilisation** : Développement et tests
- **Sécurité** : ⚠️ **NE PAS UTILISER EN PRODUCTION**

### Mode Production (`firestore.rules.production`)
- **Règles strictes** : Basées sur les permissions et les rôles utilisateurs
- **Utilisation** : Environnement de production
- **Sécurité** : ✅ Sécurisé pour la production

## ⚠️ Important : Déployer les règles

Les règles Firestore **doivent être déployées** pour être actives. Le fichier `firestore.rules` est actuellement en **mode test** pour permettre l'initialisation de l'application.

## Déploiement via Firebase CLI

### 1. Installer Firebase CLI (si pas déjà fait)

```bash
npm install -g firebase-tools
```

### 2. Se connecter à Firebase

```bash
firebase login
```

### 3. Déployer uniquement les règles Firestore

```bash
firebase deploy --only firestore:rules
```

### 4. Vérifier le déploiement

```bash
firebase firestore:rules:list
```

## Déploiement via Firebase Console

1. Ouvrir [Firebase Console](https://console.firebase.google.com)
2. Sélectionner votre projet
3. Aller dans **Firestore Database** → **Règles**
4. Copier le contenu de `firestore.rules` (mode test) ou `firestore.rules.production` (mode production)
5. Coller dans l'éditeur
6. Cliquer sur **Publier**

## Passer du mode test au mode production

### Prérequis avant de passer en production

1. ✅ Vérifier que votre utilisateur admin existe dans Firestore avec `isAdmin: true`
2. ✅ Vérifier que tous les utilisateurs ont les champs nécessaires (`enterpriseIds`, `enterprises`, etc.)
3. ✅ Tester toutes les fonctionnalités principales (création de rôles, assignations, etc.)

### Étapes pour passer en production

1. **Sauvegarder les règles de test actuelles** (optionnel, déjà sauvegardées dans `firestore.rules`)

2. **Remplacer le contenu de `firestore.rules` par celui de `firestore.rules.production`** :
   ```bash
   cp firestore.rules.production firestore.rules
   ```

3. **Déployer les nouvelles règles** :
   ```bash
   firebase deploy --only firestore:rules
   ```
   
   Ou via Firebase Console (copier-coller le contenu de `firestore.rules.production`)

4. **Tester immédiatement** après le déploiement pour vérifier que tout fonctionne

### Revenir en mode test (si problème)

Si vous avez besoin de revenir en mode test :
```bash
# Restaurer les règles de test
cat > firestore.rules << 'EOF'
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isAuthenticated() {
      return request.auth != null;
    }
    match /{document=**} {
      allow read, write: if isAuthenticated();
    }
  }
}
EOF

# Déployer
firebase deploy --only firestore:rules
```

## Vérification post-déploiement

### 1. Vérifier que votre utilisateur admin existe dans Firestore

```bash
# Via Firebase Console
Collection: users
Document ID: [Votre Firebase Auth UID]
```

Le document doit contenir :
```json
{
  "id": "votre-uid",
  "email": "admin@elyf.com",
  "firstName": "Admin",
  "lastName": "System",
  "username": "admin",
  "isActive": true,
  "isAdmin": true,  // ⚠️ CRITIQUE : Doit être true
  "createdAt": "...",
  "updatedAt": "..."
}
```

### 2. Si l'utilisateur n'existe pas ou n'a pas `isAdmin: true`

**Option A : Créer manuellement via Firebase Console**
1. Collection `users`
2. Document ID = Firebase Auth UID de admin@elyf.com
3. Ajouter les champs ci-dessus avec `isAdmin: true`

**Option B : Utiliser l'application pour créer le profil**
- Se connecter avec admin@elyf.com
- L'application devrait créer automatiquement le profil
- Mais il faudra ensuite modifier `isAdmin` manuellement dans Firestore

**Option C : Utiliser Cloud Functions (recommandé)**
Créer une Cloud Function pour initialiser automatiquement le premier admin :

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.initializeFirstAdmin = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }
  
  const userId = context.auth.uid;
  const adminEmail = context.auth.token.email;
  
  // Vérifier si c'est le premier utilisateur
  const usersSnapshot = await admin.firestore()
    .collection('users')
    .where('isAdmin', '==', true)
    .limit(1)
    .get();
  
  const isFirstAdmin = usersSnapshot.empty;
  
  if (isFirstAdmin || adminEmail === 'admin@elyf.com') {
    await admin.firestore().collection('users').doc(userId).set({
      id: userId,
      email: adminEmail,
      firstName: 'Admin',
      lastName: 'System',
      username: adminEmail.split('@')[0],
      isActive: true,
      isAdmin: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    
    return { success: true, message: 'Admin initialized' };
  }
  
  throw new functions.https.HttpsError('permission-denied', 'Cannot initialize admin');
});
```

## Test des règles

Après déploiement, tester la création d'un rôle :
1. Se connecter avec admin@elyf.com
2. Aller dans Administration → Gestion des rôles
3. Cliquer sur "Nouveau Rôle"
4. Remplir le formulaire
5. Cliquer sur "Créer"

**Résultat attendu** :
- ✅ Si `isAdmin: true` et règles déployées → Création réussie
- ❌ Si `isAdmin: false` ou absent → Erreur "Permission denied"
- ❌ Si règles non déployées → Erreur "Permission denied"

## Dépannage

### Erreur : "Permission denied" après déploiement

1. **Vérifier que les règles sont bien déployées** :
   ```bash
   firebase firestore:rules:list
   ```
   
2. **Vérifier que l'utilisateur a `isAdmin: true`** :
   - Firebase Console → Firestore → users → [Votre UID]
   - Vérifier le champ `isAdmin`
   
3. **Vérifier que vous êtes bien connecté** :
   - L'UID dans Firestore doit correspondre à votre Firebase Auth UID
   
4. **Vérifier les logs Firebase** :
   - Firebase Console → Firestore → Utilisation → Voir les logs

### Erreur : "No AppCheckProvider installed"

Cette erreur est un **warning** et n'empêche pas Firestore de fonctionner. Pour le développement, vous pouvez l'ignorer.

Si vous voulez l'éliminer :
1. Configurer App Check dans Firebase Console
2. Ou configurer App Check Debug Token pour le développement
3. Ou désactiver App Check dans les règles Firestore (non recommandé pour la production)

## Notes importantes

- ⚠️ Les règles sont **défensives** : par défaut, elles refusent l'accès
- ✅ Seuls les utilisateurs avec `isAdmin: true` peuvent créer/modifier des rôles
- ✅ Les règles vérifient l'existence de l'utilisateur avant de vérifier `isAdmin`
- ✅ Les utilisateurs peuvent lire leurs propres documents
- ✅ Les admins système peuvent tout lire/écrire

