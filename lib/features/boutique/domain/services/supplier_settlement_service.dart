import 'package:rxdart/rxdart.dart';
import '../repositories/purchase_repository.dart';
import '../repositories/supplier_settlement_repository.dart';

class SupplierSettlementService {
  final PurchaseRepository purchaseRepository;
  final SupplierSettlementRepository settlementRepository;

  SupplierSettlementService({
    required this.purchaseRepository,
    required this.settlementRepository,
  });

  /// Groups debt by age: '0-30', '31-60', '61+' days.
  Stream<Map<String, int>> watchDebtAging(String supplierId) {
    return purchaseRepository.watchPurchases().map((purchases) {
      final supplierPurchases = purchases.where((p) => p.supplierId == supplierId && !p.isDeleted);
      
      int age0_30 = 0;
      int age31_60 = 0;
      int age61Plus = 0;
      
      final now = DateTime.now();

      for (final p in supplierPurchases) {
        final debt = p.debtAmount ?? 0;
        if (debt <= 0) continue;

        final difference = now.difference(p.date).inDays;
        if (difference <= 30) {
          age0_30 += debt;
        } else if (difference <= 60) {
          age31_60 += debt;
        } else {
          age61Plus += debt;
        }
      }

      return {
        '0-30': age0_30,
        '31-60': age31_60,
        '61+': age61Plus,
      };
    });
  }

  /// Calculates total debt vs total settlements for a supplier.
  Stream<({int totalDebt, int totalSettled, int balance})> watchSupplierSummary(String supplierId) {
    return CombineLatestStream.combine2(
      purchaseRepository.watchPurchases(),
      settlementRepository.watchSettlements(supplierId: supplierId),
      (purchases, settlements) {
        final totalDebt = purchases
            .where((p) => p.supplierId == supplierId && !p.isDeleted)
            .fold(0, (sum, p) => sum + (p.debtAmount ?? 0));
            
        final totalSettled = settlements
            .fold(0, (sum, s) => sum + s.amount);

        return (
          totalDebt: totalDebt,
          totalSettled: totalSettled,
          balance: totalDebt - totalSettled,
        );
      },
    );
  }
}
