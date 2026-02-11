# Multi-Tenant Architecture

## Principe

L'application supporte plusieurs entreprises (multi-tenant) :
- Chaque entreprise a ses propres données
- Isolation des données par `enterpriseId`
- Support de plusieurs modules par entreprise

## Diagramme Multi-Tenant

```mermaid
graph TB
    subgraph Tenant1["Entreprise 1"]
        E1Gaz[Module Gaz]
        E1Boutique[Module Boutique]
    end
    
    subgraph Tenant2["Entreprise 2"]
        E2Gaz[Module Gaz]
        E2Immobilier[Module Immobilier]
    end
    
    subgraph CoreServices["Services Core"]
        TenantProvider[TenantProvider]
        AuthService[AuthService]
        PermissionService[PermissionService]
    end
    
    TenantProvider --> E1Gaz
    TenantProvider --> E1Boutique
    TenantProvider --> E2Gaz
    TenantProvider --> E2Immobilier
```

## Implémentation

- **Enterprise** : Entité représentant une entreprise
- **ActiveEnterpriseProvider** : Provider pour l'entreprise active
- **Filtrage** : Tous les repositories filtrent par `enterpriseId`
- **ModuleId** : Identifie le module actif (boutique, gaz, etc.)
