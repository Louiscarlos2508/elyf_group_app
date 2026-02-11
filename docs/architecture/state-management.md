# State Management

## Riverpod

Le projet utilise **Riverpod** pour la gestion d'état :
- **Providers** : Définis dans `application/providers.dart`
- **Controllers** : Logique métier orchestrée par des controllers
- **AsyncValue** : Gestion des états asynchrones (loading, data, error)

## Diagramme de Flux State Management

```mermaid
graph LR
    subgraph UI["UI Layer"]
        Widget[Widget]
    end
    
    subgraph Riverpod["Riverpod"]
        Provider[Provider]
        Controller[Controller/StateNotifier]
    end
    
    subgraph Domain["Domain Layer"]
        Service[Service]
        Repository[Repository Interface]
    end
    
    subgraph Data["Data Layer"]
        RepoImpl[Repository Implementation]
        Drift[Drift (SQLite)]
    end
    
    Widget -->|watch| Provider
    Provider -->|uses| Controller
    Controller -->|calls| Service
    Service -->|uses| Repository
    Repository -->|implemented by| RepoImpl
    RepoImpl -->|reads/writes| Drift
```

## Patterns

1. **Repository Pattern** : Abstraction des sources de données
2. **Service Pattern** : Logique métier dans des services
3. **Controller Pattern** : Orchestration des opérations métier
