import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../entities/sale.dart';
import '../../entities/expense.dart';
import '../../entities/purchase.dart';
import 'package:elyf_groupe_app/shared/domain/entities/treasury_operation.dart';
import '../../entities/supplier_settlement.dart';

class LedgerHashService {
  /// Generates a SHA-256 hash for a secure financial record.
  static String generateHash({
    required String? previousHash,
    required dynamic entity,
    required String shopSecret,
  }) {
    final prev = previousHash ?? 'GENESIS_HASH';
    String payload = '';

    if (entity is Sale) {
      final date = entity.date.toIso8601String();
      final amount = entity.totalAmount.toString();
      final items = entity.items.map((i) => '${i.productId}:${i.quantity}:${i.totalPrice}').toList();
      items.sort();
      final itemsStr = items.join(',');
      payload = 'SALE|$prev|$date|$amount|$itemsStr|$shopSecret';
    } else if (entity is TreasuryOperation) {
      final date = entity.date.toIso8601String();
      final amount = entity.amount.toString();
      final type = entity.type.name;
      payload = 'TREASURY|$prev|$date|$amount|$type|$shopSecret';
    } else if (entity is Expense) {
      final date = entity.date.toIso8601String();
      final amount = entity.amountCfa.toString();
      final label = entity.label;
      payload = 'EXPENSE|$prev|$date|$amount|$label|$shopSecret';
    } else if (entity is Purchase) {
      final date = entity.date.toIso8601String();
      final amount = entity.totalAmount.toString();
      final items = entity.items.map((i) => '${i.productId}:${i.quantity}:${i.totalPrice}').toList();
      items.sort();
      final itemsStr = items.join(',');
      payload = 'PURCHASE|$prev|$date|$amount|$itemsStr|$shopSecret';
    } else if (entity is SupplierSettlement) {
      final date = entity.date.toIso8601String();
      final amount = entity.amount.toString();
      final supplierId = entity.supplierId;
      payload = 'SETTLEMENT|$prev|$date|$amount|$supplierId|$shopSecret';
    } else {
      throw ArgumentError('Unsupported entity type for hashing: ${entity.runtimeType}');
    }

    final bytes = utf8.encode(payload);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifies a single entity against its previous hash.
  static bool verify(dynamic entity, String? previousHash, String shopSecret) {
    String? currentHash;
    if (entity is Sale) {
      currentHash = entity.ticketHash;
    } else if (entity is TreasuryOperation) currentHash = entity.hash;
    else if (entity is Expense) currentHash = entity.hash;
    else if (entity is Purchase) currentHash = entity.hash;
    else if (entity is SupplierSettlement) currentHash = entity.hash;
    
    if (currentHash == null) return false;

    final expectedHash = generateHash(
      previousHash: previousHash,
      entity: entity,
      shopSecret: shopSecret,
    );
    
    return currentHash == expectedHash;
  }
}
