import 'dart:async';
import 'dart:developer' as developer;

import '../errors/error_handler.dart';
import '../logging/app_logger.dart';

/// Gère les mises à jour optimistes de l'UI avec rollback automatique en cas d'échec.
///
/// L'Optimistic UI met à jour l'interface utilisateur immédiatement avant que
/// l'opération soit confirmée, puis fait un rollback si l'opération échoue.
///
/// Cela améliore la perception de la réactivité de l'application.
class OptimisticUI<T> {
  OptimisticUI({
    required this.onUpdate,
    required this.onRollback,
    this.onSuccess,
    this.onError,
  });

  /// Callback appelé pour mettre à jour l'UI immédiatement.
  final Future<void> Function(T entity) onUpdate;

  /// Callback appelé pour restaurer l'état précédent en cas d'échec.
  final Future<void> Function(T entity) onRollback;

  /// Callback optionnel appelé en cas de succès.
  final Future<void> Function(T entity)? onSuccess;

  /// Callback optionnel appelé en cas d'erreur.
  final Future<void> Function(T entity, dynamic error)? onError;

  /// État précédent sauvegardé pour rollback.
  T? _previousState;

  /// Exécute une opération avec mise à jour optimiste de l'UI.
  ///
  /// 1. Sauvegarde l'état actuel
  /// 2. Met à jour l'UI immédiatement
  /// 3. Exécute l'opération
  /// 4. En cas d'échec, restaure l'état précédent
  Future<T> executeWithOptimisticUpdate({
    required T entity,
    required Future<T> Function(T) operation,
  }) async {
    // Sauvegarder l'état précédent pour rollback
    _previousState = entity;

    try {
      // 1. Mettre à jour l'UI immédiatement (optimistic update)
      await onUpdate(entity);
      developer.log(
        'Optimistic UI update applied',
        name: 'optimistic.ui',
      );

      // 2. Exécuter l'opération réelle (save, delete, etc.)
      final result = await operation(entity);

      // 3. En cas de succès, appeler le callback de succès
      if (onSuccess != null) {
        await onSuccess!(result);
      }

      developer.log(
        'Optimistic UI operation succeeded',
        name: 'optimistic.ui',
      );

      return result;
    } catch (e, stackTrace) {
      developer.log(
        'Optimistic UI operation failed, rolling back: $e',
        name: 'optimistic.ui',
        error: e,
        stackTrace: stackTrace,
      );

      // 4. En cas d'échec, restaurer l'état précédent (rollback)
      try {
        if (_previousState != null) {
          await onRollback(_previousState!);
          developer.log(
            'Optimistic UI rollback completed',
            name: 'optimistic.ui',
          );
        }
      } catch (rollbackError, rollbackStackTrace) {
        final rollbackAppException = ErrorHandler.instance.handleError(rollbackError, rollbackStackTrace);
        AppLogger.error(
          'Error during optimistic UI rollback: ${rollbackAppException.message}',
          name: 'optimistic.ui',
          error: rollbackError,
          stackTrace: rollbackStackTrace,
        );
      }

      // Appeler le callback d'erreur si fourni
      if (onError != null) {
        await onError!(entity, e);
      }

      // Rethrow l'erreur pour que l'appelant puisse la gérer
      rethrow;
    }
  }

  /// Exécute une opération de suppression avec mise à jour optimiste.
  Future<void> executeDeleteWithOptimisticUpdate({
    required T entity,
    required Future<void> Function(T) deleteOperation,
  }) async {
    // Sauvegarder l'état précédent pour rollback
    _previousState = entity;

    try {
      // 1. Mettre à jour l'UI immédiatement (retirer de la liste)
      await onUpdate(entity);
      developer.log(
        'Optimistic UI delete update applied',
        name: 'optimistic.ui',
      );

      // 2. Exécuter l'opération de suppression réelle
      await deleteOperation(entity);

      // 3. En cas de succès, appeler le callback de succès
      if (onSuccess != null) {
        await onSuccess!(entity);
      }

      developer.log(
        'Optimistic UI delete operation succeeded',
        name: 'optimistic.ui',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Optimistic UI delete operation failed, rolling back: $e',
        name: 'optimistic.ui',
        error: e,
        stackTrace: stackTrace,
      );

      // 4. En cas d'échec, restaurer l'état précédent (rollback)
      try {
        if (_previousState != null) {
          await onRollback(_previousState!);
          developer.log(
            'Optimistic UI delete rollback completed',
            name: 'optimistic.ui',
          );
        }
      } catch (rollbackError, rollbackStackTrace) {
        final rollbackAppException = ErrorHandler.instance.handleError(rollbackError, rollbackStackTrace);
        AppLogger.error(
          'Error during optimistic UI delete rollback: ${rollbackAppException.message}',
          name: 'optimistic.ui',
          error: rollbackError,
          stackTrace: rollbackStackTrace,
        );
      }

      // Appeler le callback d'erreur si fourni
      if (onError != null) {
        await onError!(entity, e);
      }

      // Rethrow l'erreur pour que l'appelant puisse la gérer
      rethrow;
    }
  }
}

/// Helper pour créer un OptimisticUI avec des callbacks simples.
class OptimisticUIHelper {
  /// Crée un OptimisticUI pour une liste d'entités.
  ///
  /// Utile pour les StateNotifiers qui gèrent des listes.
  static OptimisticUI<T> forList<T>({
    required List<T> Function() getCurrentList,
    required void Function(List<T>) updateList,
    Future<void> Function(T)? onSuccess,
    Future<void> Function(T, dynamic)? onError,
  }) {
    return OptimisticUI<T>(
      onUpdate: (entity) async {
        // Ajouter ou mettre à jour l'entité dans la liste
        final currentList = getCurrentList();
        final index = currentList.indexWhere(
          (e) => _getEntityId(e) == _getEntityId(entity),
        );

        if (index >= 0) {
          // Mettre à jour l'entité existante
          currentList[index] = entity;
        } else {
          // Ajouter la nouvelle entité
          currentList.add(entity);
        }

        updateList(List.from(currentList));
      },
      onRollback: (entity) async {
        // Retirer l'entité ou restaurer l'état précédent
        final currentList = getCurrentList();
        final index = currentList.indexWhere(
          (e) => _getEntityId(e) == _getEntityId(entity),
        );

        if (index >= 0) {
          // Si c'était une mise à jour, restaurer l'état précédent
          // Si c'était une création, retirer l'entité
          currentList.removeAt(index);
          updateList(List.from(currentList));
        }
      },
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  /// Crée un OptimisticUI pour une entité unique.
  ///
  /// Utile pour les StateNotifiers qui gèrent une seule entité.
  ///
  /// Exemple avec Riverpod:
  /// ```dart
  /// final optimisticUI = OptimisticUIHelper.forSingle<Purchase>(
  ///   getCurrentEntity: () => ref.read(purchaseProvider),
  ///   updateEntity: (purchase) => ref.read(purchaseProvider.notifier).state = purchase,
  ///   onSuccess: (purchase) => showSnackBar('Achat enregistré'),
  ///   onError: (purchase, error) => showSnackBar('Erreur: $error'),
  /// );
  /// ```
  static OptimisticUI<T> forSingle<T>({
    required T? Function() getCurrentEntity,
    required void Function(T?) updateEntity,
    Future<void> Function(T)? onSuccess,
    Future<void> Function(T, dynamic)? onError,
  }) {
    T? _previousState;

    return OptimisticUI<T>(
      onUpdate: (entity) async {
        // Sauvegarder l'état précédent
        _previousState = getCurrentEntity();
        // Mettre à jour l'entité immédiatement
        updateEntity(entity);
      },
      onRollback: (entity) async {
        // Restaurer l'entité précédente
        updateEntity(_previousState);
      },
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  /// Extrait l'ID d'une entité (utilise une méthode générique).
  static String _getEntityId<T>(T entity) {
    // Essayer différentes méthodes communes pour obtenir l'ID
    if (entity is Map) {
      return (entity['id'] ?? entity['localId'] ?? entity['remoteId'] ?? '').toString();
    }

    // Utiliser la réflexion si disponible (nécessite package reflectable)
    // Pour l'instant, on suppose que l'entité a une méthode getId() ou un champ id
    try {
      // Fallback: utiliser hashCode comme identifiant temporaire
      return entity.hashCode.toString();
    } catch (e) {
      return '';
    }
  }
}

/// Mixin pour ajouter le support Optimistic UI aux repositories.
///
/// Les repositories peuvent utiliser ce mixin pour fournir des méthodes
/// avec support Optimistic UI.
///
/// Note: Les méthodes `save` et `delete` doivent être implémentées par
/// la classe qui utilise ce mixin.
mixin OptimisticUIRepositoryMixin<T> {
  /// Méthode abstraite pour sauvegarder une entité.
  /// Doit être implémentée par la classe utilisant ce mixin.
  Future<void> save(T entity);

  /// Méthode abstraite pour supprimer une entité.
  /// Doit être implémentée par la classe utilisant ce mixin.
  Future<void> delete(T entity);

  /// Sauvegarde une entité avec mise à jour optimiste de l'UI.
  ///
  /// Nécessite que le repository implémente `save` et que l'appelant
  /// fournisse un OptimisticUI.
  Future<T> saveWithOptimisticUpdate({
    required T entity,
    required OptimisticUI<T> optimisticUI,
  }) async {
    return await optimisticUI.executeWithOptimisticUpdate(
      entity: entity,
      operation: (e) async {
        await save(e);
        return e;
      },
    );
  }

  /// Supprime une entité avec mise à jour optimiste de l'UI.
  ///
  /// Nécessite que le repository implémente `delete` et que l'appelant
  /// fournisse un OptimisticUI.
  Future<void> deleteWithOptimisticUpdate({
    required T entity,
    required OptimisticUI<T> optimisticUI,
  }) async {
    await optimisticUI.executeDeleteWithOptimisticUpdate(
      entity: entity,
      deleteOperation: (e) => delete(e),
    );
  }
}
