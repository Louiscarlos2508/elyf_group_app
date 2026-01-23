import 'dart:convert';
import 'dart:developer' as developer;

import 'package:crypto/crypto.dart';

/// Service de déduplication intelligente pour détecter et fusionner les doublons.
///
/// Détecte les doublons même avec des IDs différents en comparant les champs clés
/// et fusionne intelligemment les données en prenant les valeurs les plus récentes.
class SmartDeduplicator {
  SmartDeduplicator();

  /// Champs clés par collection pour la détection de doublons.
  ///
  /// Ces champs sont utilisés pour identifier les entités uniques même si
  /// elles ont des IDs différents.
  static const Map<String, List<String>> keyFieldsByCollection = {
    // Clients/Utilisateurs
    'customers': ['email', 'phone', 'name'],
    'users': ['email', 'phone'],
    'tenants': ['email', 'phone', 'name'],

    // Produits
    'products': ['name', 'code', 'barcode'],
    'stock_items': ['name', 'code', 'barcode'],

    // Transactions
    'sales': ['invoiceNumber', 'transactionId'],
    'purchases': ['invoiceNumber', 'transactionId'],
    'transactions': ['transactionId', 'reference'],

    // Autres
    'properties': ['address', 'reference'],
    'contracts': ['contractNumber', 'reference'],
  };

  /// Génère un hash pour une entité basé sur ses champs clés.
  ///
  /// Utilise les champs clés définis pour la collection pour créer un hash
  /// unique qui identifie l'entité indépendamment de son ID.
  String generateKeyHash({
    required String collectionName,
    required Map<String, dynamic> data,
  }) {
    final keyFields = keyFieldsByCollection[collectionName] ?? ['id'];
    final keyValues = <String>[];

    for (final field in keyFields) {
      final value = data[field];
      if (value != null) {
        // Normaliser la valeur (lowercase, trim)
        final normalized = value.toString().toLowerCase().trim();
        if (normalized.isNotEmpty) {
          keyValues.add('$field:$normalized');
        }
      }
    }

    // Si aucun champ clé trouvé, utiliser l'ID
    if (keyValues.isEmpty) {
      final id = data['id'] ?? data['localId'] ?? data['remoteId'] ?? '';
      keyValues.add('id:$id');
    }

    // Générer un hash SHA-256
    final keyString = keyValues.join('|');
    final bytes = utf8.encode(keyString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Vérifie si deux entités sont des doublons.
  ///
  /// Compare les entités en utilisant leurs champs clés plutôt que leurs IDs.
  bool isDuplicate({
    required String collectionName,
    required Map<String, dynamic> entity1,
    required Map<String, dynamic> entity2,
  }) {
    final hash1 = generateKeyHash(
      collectionName: collectionName,
      data: entity1,
    );
    final hash2 = generateKeyHash(
      collectionName: collectionName,
      data: entity2,
    );

    return hash1 == hash2;
  }

  /// Fusionne intelligemment plusieurs doublons en une seule entité.
  ///
  /// Prend les valeurs les plus récentes de chaque champ en comparant
  /// les timestamps `updatedAt` ou `createdAt`.
  Map<String, dynamic> mergeDuplicates({
    required String collectionName,
    required List<Map<String, dynamic>> duplicates,
  }) {
    if (duplicates.isEmpty) {
      return {};
    }

    if (duplicates.length == 1) {
      return duplicates.first;
    }

    developer.log(
      'Merging ${duplicates.length} duplicates for $collectionName',
      name: 'smart.deduplicator',
    );

    // Trier par updatedAt (plus récent en premier)
    final sorted = List<Map<String, dynamic>>.from(duplicates)
      ..sort((a, b) {
        final aUpdated = _parseTimestamp(a['updatedAt'] ?? a['createdAt']);
        final bUpdated = _parseTimestamp(b['updatedAt'] ?? b['createdAt']);
        return bUpdated.compareTo(aUpdated);
      });

    // Prendre la version la plus récente comme base
    final merged = Map<String, dynamic>.from(sorted.first);

    // Fusionner les champs manquants depuis les autres versions
    for (int i = 1; i < sorted.length; i++) {
      final other = sorted[i];
      for (final entry in other.entries) {
        final key = entry.key;
        final value = entry.value;

        // Ignorer les champs système
        if (key == 'id' ||
            key == 'localId' ||
            key == 'remoteId' ||
            key == 'createdAt' ||
            key == 'updatedAt') {
          continue;
        }

        // Si le champ n'existe pas dans merged ou est null, prendre la valeur
        if (!merged.containsKey(key) || merged[key] == null) {
          merged[key] = value;
        } else if (value != null) {
          // Si les deux valeurs existent, prendre la plus récente
          final mergedUpdated = _parseTimestamp(merged['updatedAt']);
          final otherUpdated = _parseTimestamp(other['updatedAt']);
          if (otherUpdated.isAfter(mergedUpdated)) {
            merged[key] = value;
          }
        }
      }
    }

    // Conserver l'ID le plus récent (remoteId si disponible, sinon localId)
    final mostRecent = sorted.first;
    if (mostRecent['remoteId'] != null) {
      merged['id'] = mostRecent['remoteId'];
      merged['remoteId'] = mostRecent['remoteId'];
    } else if (mostRecent['localId'] != null) {
      merged['id'] = mostRecent['localId'];
      merged['localId'] = mostRecent['localId'];
    }

    // Mettre à jour le timestamp avec le plus récent
    final latestUpdated = _parseTimestamp(
      sorted.first['updatedAt'] ?? sorted.first['createdAt'],
    );
    merged['updatedAt'] = latestUpdated.toIso8601String();

    developer.log(
      'Merged ${duplicates.length} duplicates into one entity for $collectionName',
      name: 'smart.deduplicator',
    );

    return merged;
  }

  /// Trouve tous les doublons dans une liste d'entités.
  ///
  /// Retourne une map où chaque clé est un hash de doublons et la valeur
  /// est la liste des entités dupliquées.
  Map<String, List<Map<String, dynamic>>> findDuplicates({
    required String collectionName,
    required List<Map<String, dynamic>> entities,
  }) {
    final duplicatesMap = <String, List<Map<String, dynamic>>>{};

    for (final entity in entities) {
      final hash = generateKeyHash(
        collectionName: collectionName,
        data: entity,
      );

      duplicatesMap.putIfAbsent(hash, () => []).add(entity);
    }

    // Filtrer pour ne garder que les vrais doublons (plus d'une entité)
    duplicatesMap.removeWhere((key, value) => value.length <= 1);

    if (duplicatesMap.isNotEmpty) {
      developer.log(
        'Found ${duplicatesMap.length} groups of duplicates in $collectionName '
        '(${duplicatesMap.values.map((v) => v.length).reduce((a, b) => a + b)} total duplicates)',
        name: 'smart.deduplicator',
      );
    }

    return duplicatesMap;
  }

  /// Nettoie une liste d'entités en fusionnant les doublons.
  ///
  /// Retourne une liste d'entités uniques avec les doublons fusionnés.
  List<Map<String, dynamic>> deduplicate({
    required String collectionName,
    required List<Map<String, dynamic>> entities,
  }) {
    if (entities.isEmpty) {
      return [];
    }

    final duplicates = findDuplicates(
      collectionName: collectionName,
      entities: entities,
    );

    if (duplicates.isEmpty) {
      return entities;
    }

    // Créer un set des hashs des doublons pour identification rapide
    final duplicateHashes = duplicates.keys.toSet();

    // Séparer les entités uniques et les doublons
    final uniqueEntities = <Map<String, dynamic>>[];
    final mergedDuplicates = <String, Map<String, dynamic>>{};

    for (final entity in entities) {
      final hash = generateKeyHash(
        collectionName: collectionName,
        data: entity,
      );

      if (duplicateHashes.contains(hash)) {
        // C'est un doublon, sera fusionné
        if (!mergedDuplicates.containsKey(hash)) {
          mergedDuplicates[hash] = mergeDuplicates(
            collectionName: collectionName,
            duplicates: duplicates[hash]!,
          );
        }
      } else {
        // Entité unique
        uniqueEntities.add(entity);
      }
    }

    // Combiner les entités uniques et les doublons fusionnés
    final result = [
      ...uniqueEntities,
      ...mergedDuplicates.values,
    ];

    developer.log(
      'Deduplicated ${entities.length} entities to ${result.length} unique entities '
      'for $collectionName',
      name: 'smart.deduplicator',
    );

    return result;
  }

  /// Parse un timestamp depuis différents formats.
  DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    if (timestamp is DateTime) {
      return timestamp;
    }

    if (timestamp is String) {
      final parsed = DateTime.tryParse(timestamp);
      if (parsed != null) {
        return parsed;
      }
    }

    if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
