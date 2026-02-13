import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../entities/sale.dart';

class TicketHashHelper {
  /// Generates a SHA-256 hash for a secure receipt.
  /// 
  /// Format: SHA256(previousHash + | + isoDate + | + totalAmount + | + itemsString + | + secret)
  static String generateHash({
    required String? previousHash,
    required Sale sale,
    required String shopSecret,
  }) {
    final prev = previousHash ?? 'GENESIS_HASH';
    final date = sale.date.toIso8601String();
    final amount = sale.totalAmount.toString();
    
    // Sort items to ensure consistent hashing regardless of order
    final items = sale.items.map((i) => '${i.productId}:${i.quantity}:${i.totalPrice}').toList();
    items.sort();
    final itemsStr = items.join(',');

    final payload = '$prev|$date|$amount|$itemsStr|$shopSecret';
    
    final bytes = utf8.encode(payload);
    final digest = sha256.convert(bytes);
    
    return digest.toString();
  }
}
