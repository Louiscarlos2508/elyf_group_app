# Core Layer

Services et utilitaires transverses partagés par tous les modules.

## Sous-dossiers

- `auth/` – modèles utilisateur, repository Firebase Auth, contrôleurs Riverpod.
- `constants/` – chemins Firestore, rôles, flags, noms de collections.
- `firebase/` – wrappers Firestore, Cloud Functions, Messaging, Storage.
- `logging/` – intégration `dart:developer`, audit trail, crash reporting.
- `offline/` – Isar collections, synchronisation avec Firestore, job queue.
- `printing/` – intégration Sunmi V3, widgets d’impression, templates.
- `tenant/` – contexte multi-entreprises, sélecteur, repository tenants.

Chaque dossier contient des fichiers < 200 lignes, organisés en modèles,
repositories, services et contrôleurs.

