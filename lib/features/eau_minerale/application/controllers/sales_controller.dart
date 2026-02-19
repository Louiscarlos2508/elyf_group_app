import '../../domain/adapters/pack_stock_adapter.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/closing.dart';
import '../../domain/pack_constants.dart';
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
    this._packStockAdapter,
    this._productRepository,
    this._auditTrailService,
    this._treasuryRepository,
    this._closingRepository,
  );

  final SaleRepository _saleRepository;
  final PackStockAdapter _packStockAdapter;
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
      // _saleRepository.watchSales() already sorts, but we can ensure it?
      // It returns parsed sales.
      // Filter logic is inside repo if args provided, here no args = All.
      return SalesState(sales: sales);
    });
  }

  /// Crée une vente et décrémente le stock Pack si produit fini.
  ///
  /// Utilise [packProductId] pour le Pack (même que Stock, Dashboard, Paramètres).
  /// Décrémente toujours le StockItem Pack lorsqu'une vente Pack est créée.
  Future<String> createSale(Sale sale, String userId) async {
    // 1. Vérifier si une session de trésorerie est ouverte
    final currentSession = await _closingRepository.getCurrentSession();
    if (currentSession == null || currentSession.status != ClosingStatus.open) {
      throw ValidationException(
        'Impossible de réaliser une vente : la session de trésorerie est fermée. '
        'Veuillez ouvrir une session dans la section Trésorerie.',
        'TREASURY_SESSION_CLOSED',
      );
    }

    try {
      final id = await _saleRepository.createSale(sale);
      final isPack = sale.productId == packProductId;
      
      // Check if it's a finished good by fetching product details if not a Pack
      bool isOtherFinishedGood = false;
      if (!isPack) {
        try {
          final product = await _productRepository.getProduct(sale.productId);
          isOtherFinishedGood = product?.isFinishedGood == true;
        } catch (e) {
          AppLogger.error('Error checking finished good status: $e', name: 'SalesController');
        }
      }

      if ((isPack || isOtherFinishedGood) && sale.quantity > 0) {
        try {
          await _packStockAdapter.recordPackExit(
            sale.quantity,
            productId: sale.productId,
            reason: 'Vente',
            notes: 'Vente ${sale.productName}',
          );
        } catch (e, st) {
          AppLogger.error(
            'Failed to record pack exit for sale $id',
            error: e,
            stackTrace: st,
          );
        }
      }

      // Record Treasury Operations for payments
      await _recordTreasuryOperationsForSale(sale.copyWith(id: id), userId);

      // 4. Log to Audit Trail
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

  /// Annule une vente : met à jour le statut, restaure le stock et inverse la trésorerie.
  Future<void> voidSale(String saleId, String userId) async {
    // 1. Vérifier si une session de trésorerie est ouverte
    final currentSession = await _closingRepository.getCurrentSession();
    if (currentSession == null || currentSession.status != ClosingStatus.open) {
      throw ValidationException(
        'Impossible d\'annuler la vente : la session de trésorerie est fermée. '
        'Veuillez ouvrir une session dans la section Trésorerie.',
        'TREASURY_SESSION_CLOSED',
      );
    }

    try {
      final sale = await _saleRepository.getSale(saleId);
      if (sale == null) {
        throw NotFoundException('Vente non trouvée : $saleId');
      }

      if (sale.status == SaleStatus.voided) {
        throw ValidationException('La vente est déjà annulée.', 'SALE_ALREADY_VOIDED');
      }

      // 2. Mettre à jour le statut de la vente
      final voidedSale = sale.copyWith(
        status: SaleStatus.voided,
        deletedBy: userId,
      );
      await _saleRepository.updateSale(voidedSale);

      // 3. Restaurer le stock
      final isPack = sale.productId == packProductId;
      
      bool isOtherFinishedGood = false;
      if (!isPack) {
        try {
          final product = await _productRepository.getProduct(sale.productId);
          isOtherFinishedGood = product?.isFinishedGood == true;
        } catch (e) {
          AppLogger.error('Error checking finished good status: $e', name: 'SalesController');
        }
      }

      if ((isPack || isOtherFinishedGood) && sale.quantity > 0) {
        try {
          await _packStockAdapter.recordPackEntry(
            sale.quantity,
            productId: sale.productId,
            reason: 'Annulation Vente',
            notes: 'Annulation vente ${sale.id}',
          );
        } catch (e, st) {
          AppLogger.error(
            'Failed to record pack entry for voided sale $saleId',
            error: e,
            stackTrace: st,
          );
        }
      }

      // 4. Inverser les opérations de trésorerie
      await _recordReverseTreasuryOperationsForSale(sale, userId);

      // 5. Log to Audit Trail
      try {
        await _auditTrailService.logAction(
          enterpriseId: sale.enterpriseId,
          userId: userId,
          action: 'VOID_SALE',
          module: 'eau_minerale',
          entityId: saleId,
          entityType: 'sale',
          metadata: {
            'notes': 'Annulation vente de ${sale.totalPrice} FCFA pour ${sale.productName}',
            'saleId': saleId,
            'totalAmount': sale.totalPrice,
            'productName': sale.productName,
          },
        );
      } catch (e) {
        AppLogger.error('Failed to log eau_minerale void sale audit', error: e);
      }

    } catch (e, st) {
      AppLogger.error('Error in voidSale: $e', name: 'SalesController', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> _recordReverseTreasuryOperationsForSale(Sale sale, String userId) async {
    try {
      if (sale.cashAmount > 0) {
        await _treasuryRepository.createOperation(TreasuryOperation(
          id: '',
          enterpriseId: sale.enterpriseId,
          userId: userId,
          amount: -sale.cashAmount, // Montant négatif pour inverser
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
          id: '',
          enterpriseId: sale.enterpriseId,
          userId: userId,
          amount: -sale.orangeMoneyAmount, // Montant négatif
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
      if (sale.cashAmount > 0) {
        await _treasuryRepository.createOperation(TreasuryOperation(
          id: '',
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
          id: '',
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
      .where((sale) => _isToday(sale.date))
      .fold(0, (value, sale) => value + sale.totalPrice);

  int get todaySalesCount => sales.where((sale) => _isToday(sale.date)).length;

  int get todayCollections => sales
      .where((sale) => _isToday(sale.date))
      .fold(0, (value, sale) => value + sale.amountPaid);
}
