import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../../features/audit_trail/domain/entities/audit_record.dart';

/// Utility to handle cryptographic hashing for ledger integrity.
///
/// This creates a hash-chain where each record contains the hash of the previous one.
class LedgerHasher {
  /// Calculates the SHA-256 hash for an [AuditRecord].
  ///
  /// Combines all immutable fields and the [previousHash] to ensure
  /// that any modification to a past record breaks the chain.
  static String calculateHash(AuditRecord record, String? previousHash) {
    // We normalize the metadata to JSON to ensure consistent hashing
    final metadataStr = record.metadata != null ? jsonEncode(record.metadata) : '{}';
    
    // Concatenate all important fields
    final dataToHash = [
      record.enterpriseId,
      record.userId,
      record.module,
      record.action,
      record.entityId,
      record.entityType,
      metadataStr,
      record.timestamp.toIso8601String(),
      previousHash ?? 'genesis_block', // Genesis value if no previous hash
    ].join('|');

    final bytes = utf8.encode(dataToHash);
    return sha256.convert(bytes).toString();
  }

  /// Verifies if a record's hash matches its content and a previous hash.
  static bool verifyIntegrity(AuditRecord record, String? previousHash) {
    if (record.hash == null) return false;
    final computedHash = calculateHash(record, previousHash);
    return computedHash == record.hash;
  }
}
