# Synchronisation Avancée & Performance

## Stratégie de Synchronisation (SyncManager)
L'application utilise un système de synchronisation sophistiqué pour garantir l'intégrité des données multi-tenant :
- **Queue Persistante** : Les opérations sont stockées localement dans Drift et synchronisées avec un mécanisme de retry (exponential backoff).
- **Batch Operations** : Jusqu'à 500 opérations sont regroupées en une seule transaction Firestore pour optimiser les coûts et le réseau.
- **Delta Sync** : Utilisation de `lastSyncAt` pour ne récupérer que les modifications récentes au démarrage.
- **Priorisation** : Les ventes et paiements sont synchronisés avant les logs ou métriques.

## Résolution de Conflits
Le système suit une approche **Last-Write-Wins** basée sur le champ `updated_at`. En cas de conflit :
1. Le document avec le timestamp le plus récent est conservé.
2. Les données locales en attente de synchronisation sont prioritaires sur les données distantes plus anciennes.
