# ADR-003: Implémentation offline-first avec Isar

**Statut** : Accepté  
**Date** : 2026-02-XX  
**Auteurs** : Équipe de développement

## Contexte

L'application doit fonctionner en mode offline pour garantir la disponibilité même sans connexion internet. Une stratégie offline-first est nécessaire avec synchronisation automatique avec Firestore.

## Décision

Implémenter une architecture offline-first avec :
- **Isar** : Base de données locale (remplacé par ObjectBox dans le futur)
- **OfflineRepository<T>** : Classe de base pour repositories offline-first
- **SyncManager** : Gestionnaire de synchronisation avec Firestore
- **ConnectivityService** : Surveillance de la connectivité réseau
- **Stratégie** : Écriture locale d'abord, synchronisation en arrière-plan

## Conséquences

### Positives
- Application fonctionnelle même sans internet
- Expérience utilisateur améliorée (pas d'attente réseau)
- Résilience aux pannes réseau
- Synchronisation automatique quand la connexion revient
- Résolution de conflits avec `updated_at` (last write wins)

### Négatives
- Complexité accrue (gestion de la synchronisation, conflits)
- Plus de code à maintenir
- Nécessite une stratégie de migration des données
- Isar actuellement déprécié (migration vers ObjectBox prévue)

### Alternatives Considérées
- **SQLite** : Rejeté car moins performant et moins moderne
- **Hive** : Rejeté car moins adapté aux relations complexes
- **ObjectBox** : Considéré mais Isar était disponible à l'époque (migration prévue)
- **Online-only** : Rejeté car ne répond pas au besoin offline

## Références
- [docs/ARCHITECTURE.md](../ARCHITECTURE.md#offline-first-architecture)
- [core/offline/README.md](../../lib/core/offline/README.md)

