# ADR-005: Système de permissions centralisé

**Statut** : Accepté  
**Date** : 2026-02-XX  
**Auteurs** : Équipe de développement

## Contexte

Le projet nécessite un système de gestion des permissions pour contrôler l'accès aux fonctionnalités par module et par rôle utilisateur. Les permissions doivent être centralisées pour éviter la duplication et assurer la cohérence.

## Décision

Créer un système de permissions centralisé dans `core/permissions/` avec :
- **PermissionService** : Service centralisé de gestion des permissions
- **PermissionRegistry** : Registre des permissions par module
- **ModulePermission** : Entité représentant une permission
- **UserRole** : Entité représentant un rôle utilisateur
- **Isolation** : Permissions définies par module dans `core/permissions/modules/`

## Conséquences

### Positives
- Centralisation des permissions (une seule source de vérité)
- Cohérence entre les modules
- Facilite l'audit et la maintenance
- Réutilisabilité du système de permissions
- Isolation multi-tenant (filtrage par entreprise)

### Négatives
- Nécessite une migration des permissions existantes
- Structure plus complexe qu'une solution décentralisée
- Nécessite une discipline pour maintenir la centralisation

### Alternatives Considérées
- **Permissions décentralisées** : Rejeté car risque de duplication et incohérence
- **Permissions hardcodées** : Rejeté car non maintenable
- **Permissions dans Firestore** : Considéré mais complexité ajoutée pour peu de bénéfice

## Références
- [core/permissions/README.md](../../lib/core/permissions/README.md)
- [core/permissions/INTEGRATION_GUIDE.md](../../lib/core/permissions/INTEGRATION_GUIDE.md)

