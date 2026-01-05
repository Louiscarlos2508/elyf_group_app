# Configuration des Variables d'Environnement

## Fichier .env

Le fichier `.env` contient les variables d'environnement sensibles pour l'application.
**⚠️ IMPORTANT : Ce fichier ne doit JAMAIS être commité dans Git.**

## Création du fichier .env

1. Copiez le fichier `.env.example` vers `.env` :
   ```bash
   cp .env.example .env
   ```

2. Générez le hash du mot de passe administrateur :
   ```bash
   dart scripts/generate_password_hash.dart admin123
   ```

3. Copiez le hash généré dans le fichier `.env` :
   ```
   ADMIN_EMAIL=admin@elyf.com
   ADMIN_PASSWORD_HASH=<hash_généré>
   ```

## Variables d'environnement disponibles

- `ADMIN_EMAIL` : Email de l'administrateur par défaut (défaut: `admin@elyf.com`)
- `ADMIN_PASSWORD_HASH` : Hash du mot de passe administrateur (requis)

## Exemple de fichier .env

```
# Configuration d'authentification
# ⚠️ NE PAS COMMITER CE FICHIER DANS GIT ⚠️

# Email de l'administrateur par défaut
ADMIN_EMAIL=admin@elyf.com

# Hash du mot de passe administrateur (généré avec scripts/generate_password_hash.dart)
ADMIN_PASSWORD_HASH=DRQbIikwNz5FTFNaYWhvdg==:4fc6ba0983830335164707aa921bb267e6e422e1961f3e61f24a41db082ebe08
```

## Génération d'un nouveau hash

Pour générer un hash pour un nouveau mot de passe :

```bash
dart scripts/generate_password_hash.dart <votre_mot_de_passe>
```

Le script affichera le hash à copier dans le fichier `.env`.

## Sécurité

- Le fichier `.env` est automatiquement exclu de Git via `.gitignore`
- Les mots de passe sont stockés sous forme de hash (SHA-256 avec salt)
- Les données de session sont stockées de manière sécurisée via `flutter_secure_storage`

