# Intégrité des Stocks

Le module `StockIntegrityService` assure la cohérence entre les quantités affichées et l'historique des opérations.

## Diagnostic & Réparation
- **Vérification** : Compare la quantité stockée avec `Somme(entrées) - Somme(sorties)`.
- **Réparation** : Recalcule automatiquement la quantité stockée à partir des mouvements (source de vérité absolue).
- **Architecture des Mouvements** : Utilisation d'un document Firestore par mouvement (pas de tableau géant) pour garantir la scalabilité et éviter les limites de taille de document (1MB).
