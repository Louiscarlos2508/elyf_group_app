# 📂 Configuration et Installation - ELYF Group App

Ce guide centralise toutes les informations nécessaires pour configurer l'environnement de développement et les services d'authentification.

---

## 🛠️ 1. Configuration de l'Environnement

### Fichier .env
Le fichier `.env` contient les variables sensibles. **Ne jamais commiter ce fichier.**

1.  **Initialisation** : Copiez le modèle : `cp .env.example .env`
2.  **Configuration Admin** :
    - `ADMIN_EMAIL` : Email de l'administrateur (défaut: `admin@elyf.com`)
    - `ADMIN_PASSWORD_HASH` : Hash du mot de passe (généré via script).

### Génération du Hash
Pour sécuriser le mot de passe admin :
```bash
dart scripts/generate_password_hash.dart <votre_mot_de_passe>
```
Copiez le résultat dans votre `.env`.

---

## 🔐 2. Système d'Authentification

### Accès par Défaut (Mode Développement)
- **Email** : `admin@elyf.com`
- **Mot de passe** : `admin123` (si non modifié dans le .env)

### Flux de Connexion
1.  **Login** : Saisie des identifiants.
2.  **Validation** : Vérification locale (SharedPreferences) ou via Firebase Auth (si activé).
3.  **Accès** : Redirection vers le menu des modules protégé par `AuthGuard`.

### Migration vers Firebase Auth
Le système est prêt pour une transition complète :
1.  Remplacer `signInWithEmailAndPassword` dans `AuthService`.
2.  Utiliser `FirebaseAuth.instance.authStateChanges()` pour le suivi de session.
3.  Désactiver le système de mock au profit des utilisateurs réels de la console Firebase.

---

## 🏗️ 3. Routes Protégées
L'accès aux modules suivants nécessite une authentification active :
- `/admin` : Panel d'administration globale.
- `/modules/eau_minerale` : Gestion de la production d'eau.
- `/modules/gaz` : Gestion des stocks et ventes de gaz.
- `/modules/immobilier` : Gestion des baux et loyers.
- `/modules/boutique` : Point de vente e-commerce.

---

## 📚 Ressources Utiles
- [Wiki d'Installation](../../wiki/01-getting-started/installation.md)
- [Guide des Patterns](../PATTERNS_GUIDE.md)
