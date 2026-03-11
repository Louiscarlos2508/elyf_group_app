import 'stock_controller.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/closing.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/closing_repository.dart';
import '../../domain/repositories/sale_repository.dart';
import '../../domain/repositories/treasury_repository.dart';
import '../../../audit_trail/domain/services/audit_trail_service.dart';
import '../../../../shared/domain/entities/treasury_operation.dart';
import '../../../../shared/domain/entities/payment_method.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/logging/app_logger.dart';

class SalesController {
  SalesController(
    this._saleRepository,
    this._stockController,
    this._productRepository,
    this._auditTrailService,
    this._treasuryRepository,
    this._closingRepository,
  );

  final SaleRepository _saleRepository;
  final StockController _stockController;
  final ProductRepository _productRepository;
  final AuditTrailService _auditTrailService;
  final TreasuryRepository _treasuryRepository;
  final ClosingRepository _closingRepository;

  Future<SalesState> fetchRecentSales() async {
    final sales = await _saleRepository.fetchSales();
    sales.sort((a, b) => b.date.compareTo(a.date));
    return SalesState(sales: sales);
  }

  Stream<SalesState> watchRecentSales() {
    return _saleRepository.watchSales().map((sales) {
      return SalesState(sales: sales);
    });
  }

  /// Crée une vente et décrémente le stock si c'est un produit fini.
  Future<String> createSale(Sale sale, String userId) async {

    try {
      final id = await _saleRepository.createSale(sale);
      
      // Déterminer dynamiquement si on décrémente le stock
      bool isFinishedGood = false;
      try {
        final product = await _productRepository.getProduct(sale.productId);
        isFinishedGood = product?.isFinishedGood == true;
      } catch (e) {
        AppLogger.error('Error checking product type: $e', name: 'SalesController');
      }

      if (isFinishedGood && sale.quantity > 0) {
        try {
          // Idempotency: Use Sale ID to generate deterministic Stock Movement ID
          final stockMovementId = 'local_stk_sale_$id';
          
          await _stockController.recordExit(
            id: stockMovementId,
            productId: sale.productId,
            productName: sale.productName ?? 'Produit',
            quantite: sale.quantity.toDouble(),
            raison: 'Vente',
            notes: 'Vente ${sale.productName}',
          );
        } catch (e, st) {
          AppLogger.error('Failed to record stock exit for sale $id', error: e, stackTrace: st);
        }
      }

      await _recordTreasuryOperationsForSale(sale.copyWith(id: id), userId);

      try {
        await _auditTrailService.logSale(
          enterpriseId: sale.enterpriseId,
          userId: userId,
          saleId: id,
          module: 'eau_minerale',
          totalAmount: sale.totalPrice.toDouble(),
          extraMetadata: {
            'productName': sale.productName,
            'quantity': sale.quantity,
          },
        );
      } catch (e) {
        AppLogger.error('Failed to log eau_minerale sale audit', error: e);
      }

      return id;
    } catch (e, st) {
      AppLogger.error('Error in createSale: $e', name: 'SalesController', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Annule une vente et restaure le stock.
  Future<void> voidSale(String saleId, String userId) async {

    try {
      final sale = await _saleRepository.getSale(saleId);
      if (sale == null) throw NotFoundException('Vente non trouvée : $saleId');
      if (sale.status == SaleStatus.voided) throw const ValidationException('Déjà annulée.');

      final voidedSale = sale.copyWith(status: SaleStatus.voided, deletedBy: userId);
      await _saleRepository.updateSale(voidedSale);

      bool isFinishedGood = false;
      try {
        final product = await _productRepository.getProduct(sale.productId);
        isFinishedGood = product?.isFinishedGood == true;
      } catch (e) {
        AppLogger.error('Error checking product type: $e', name: 'SalesController');
      }

      if (isFinishedGood && sale.quantity > 0) {
        try {
          // Idempotency: Use Sale ID for stock restoration ID as well
          final restorationId = 'local_stk_void_$saleId';
          
          await _stockController.recordEntry(
            id: restorationId,
            productId: sale.productId,
            productName: sale.productName ?? 'Produit',
            quantite: sale.quantity.toDouble(),
            raison: 'Annulation Vente',
            notes: 'Annulation vente ${sale.id}',
          );
        } catch (e, st) {
          AppLogger.error('Failed to restore stock for voided sale $saleId', error: e, stackTrace: st);
        }
      }

      await _recordReverseTreasuryOperationsForSale(sale, userId);

      try {
        await _auditTrailService.logAction(
          enterpriseId: sale.enterpriseId,
          userId: userId,
          action: 'VOID_SALE',
          module: 'eau_minerale',
          entityId: saleId,
          entityType: 'sale',
          metadata: {
            'saleId': saleId,
            'totalAmount': sale.totalPrice,
          },
        );
      } catch (e) {
        AppLogger.error('Failed to log void sale audit', error: e);
      }
    } catch (e, st) {
      AppLogger.error('Error in voidSale: $e', name: 'SalesController', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> _recordReverseTreasuryOperationsForSale(Sale sale, String userId) async {
    try {
      final saleId = sale.id;
      if (sale.cashAmount > 0) {
        await _treasuryRepository.createOperation(TreasuryOperation(
          id: 'local_trs_void_cash_$saleId',
          enterpriseId: sale.enterpriseId,
          userId: userId,
          amount: -sale.cashAmount,
          type: TreasuryOperationType.supply,
          toAccount: PaymentMethod.cash,
          date: DateTime.now(),
          reason: 'Annulation Vente ${sale.id}',
          referenceEntityId: sale.id,
          referenceEntityType: 'sale_void',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      if (sale.orangeMoneyAmount > 0) {
        await _treasuryRepository.createOperation(TreasuryOperation(
          id: 'local_trs_void_om_$saleId',
          enterpriseId: sale.enterpriseId,
          userId: userId,
          amount: -sale.orangeMoneyAmount,
          type: TreasuryOperationType.supply,
          toAccount: PaymentMethod.mobileMoney,
          date: DateTime.now(),
          reason: 'Annulation Vente ${sale.id} (Orange Money)',
          referenceEntityId: sale.id,
          referenceEntityType: 'sale_void',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }
    } catch (e) {
      AppLogger.error('Failed to record reverse treasury operations for sale ${sale.id}', error: e);
    }
  }

  Future<void> _recordTreasuryOperationsForSale(Sale sale, String userId) async {
    try {
      final saleId = sale.id;
      if (sale.cashAmount > 0) {
        await _treasuryRepository.createOperation(TreasuryOperation(
          id: 'local_trs_sale_cash_$saleId',
          enterpriseId: sale.enterpriseId,
          userId: userId,
          amount: sale.cashAmount,
          type: TreasuryOperationType.supply,
          toAccount: PaymentMethod.cash,
          date: sale.date,
          reason: 'Vente ${sale.productName}',
          referenceEntityId: sale.id,
          referenceEntityType: 'sale',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      if (sale.orangeMoneyAmount > 0) {
        await _treasuryRepository.createOperation(TreasuryOperation(
          id: 'local_trs_sale_om_$saleId',
          enterpriseId: sale.enterpriseId,
          userId: userId,
          amount: sale.orangeMoneyAmount,
          type: TreasuryOperationType.supply,
          toAccount: PaymentMethod.mobileMoney,
          date: sale.date,
          reason: 'Vente ${sale.productName} (Orange Money)',
          referenceEntityId: sale.id,
          referenceEntityType: 'sale',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }
    } catch (e) {
      AppLogger.error('Failed to record treasury operations for sale ${sale.id}', error: e);
    }
  }
}

class SalesState {
  const SalesState({required this.sales});

  final List<Sale> sales;

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  int get todayRevenue => sales
      .where((sale) => _isToday(sale.date) && sale.status != SaleStatus.voided)
      .fold(0, (value, sale) => value + sale.totalPrice);

  int get todaySalesCount => sales.where((sale) => _isToday(sale.date)).length;

  int get todayCollections => sales
      .where((sale) => _isToday(sale.date) && sale.status != SaleStatus.voided)
      .fold(0, (value, sale) => value + sale.amountPaid);
}

