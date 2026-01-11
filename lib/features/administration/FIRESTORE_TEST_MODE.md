# Mode Test Firestore - Guide Rapide

## ✅ Règles en Mode Test

Les règles Firestore sont maintenant en **mode test** (permissives) pour permettre l'initialisation de l'application.

### Caractéristiques du mode test

- ✅ **Tous les utilisateurs authentifiés** peuvent lire/écrire **toutes les collections**
- ✅ Permet la création du premier utilisateur admin
- ✅ Permet l'initialisation complète de l'application
- ⚠️ **NE PAS UTILISER EN PRODUCTION**

## 🚀 Déployer les Règles (Firebase Console)

### Méthode 1 : Via Firebase Console Web

1. **Ouvrir Firebase Console** :
   - Aller sur https://console.firebase.google.com
   - Sélectionner votre projet

2. **Accéder aux règles Firestore** :
   - Menu gauche : **Firestore Database**
   - Onglet : **Règles**

3. **Copier les règles** :
   - Ouvrir le fichier `firestore.rules` dans votre projet
   - Copier **tout le contenu** (Ctrl+A, Ctrl+C)

4. **Coller et publier** :
   - Coller dans l'éditeur Firebase Console (Ctrl+V)
   - Cliquer sur **Publier**

5. **Vérifier** :
   - Attendre quelques secondes
   - Vérifier qu'il n'y a pas d'erreur de syntaxe
   - Tester la connexion dans l'application

### Méthode 2 : Vérification rapide

Les règles en mode test sont très simples :

```javascript
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
```

Si vous voyez ce contenu dans Firebase Console, les règles sont correctement déployées.

## 📝 Étapes Suivantes

Une fois les règles déployées :

1. **Tester la connexion** avec `admin@elyf.com`
2. **Vérifier que l'utilisateur peut être créé** dans Firestore
3. **S'assurer que `isAdmin: true` est défini** dans le document utilisateur
4. **Tester la création de rôles** dans l'interface admin

## ⚠️ Rappel Important

Ces règles sont **temporaires** et **trop permissives** pour la production.

Pour passer en production plus tard :
- Utiliser `firestore.rules.production`
- Suivre le guide dans `FIRESTORE_RULES_DEPLOY.md`

## 🐛 Résolution de Problèmes

### Erreur "Permission denied" après déploiement

1. Vérifier que les règles sont bien déployées dans Firebase Console
2. Vérifier que l'utilisateur est bien authentifié (`request.auth != null`)
3. Attendre quelques secondes après le déploiement (propagation)

### Firebase n'est pas initialisé

1. Vérifier que `firebase_options.dart` est correctement configuré
2. Vérifier que Firebase est initialisé dans `bootstrap.dart`
3. Redémarrer l'application après le déploiement des règles

### L'utilisateur admin n'existe pas dans Firestore

1. Se connecter avec `admin@elyf.com`
2. Vérifier dans Firebase Console → Firestore → Collection `users`
3. Si le document n'existe pas, il sera créé automatiquement lors de la première connexion
4. Vérifier que le champ `isAdmin` est défini à `true`

