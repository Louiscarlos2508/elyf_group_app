import 'dart:convert';
import 'package:drift/drift.dart';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/drift/app_database.dart';
import '../../../audit_trail/domain/entities/audit_record.dart';
import '../../../audit_trail/domain/repositories/audit_trail_repository.dart';
import '../../domain/entities/sale.dart';
import '../../domain/repositories/sale_repository.dart';
import '../../domain/services/security/ledger_hash_service.dart';

/// Offline-first repository for Sale entities using Relational Drift Tables.
class SaleOfflineRepository extends OfflineRepository<Sale>
    implements SaleRepository {
  SaleOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
    required this.moduleType,
    required this.auditTrailRepository,
    this.userId = 'system',
    this.shopSecret = 'DEFAULT_SECRET', // Should be injected via env/config
  });

  final String enterpriseId;
  final String moduleType;
  final AuditTrailRepository auditTrailRepository;
  final String userId;
  final String shopSecret;

  @override
  String get collectionName => 'sales';

  AppDatabase get db => driftService.db;

  // --- Entity Mapping ---

  @override
  Sale fromMap(Map<String, dynamic> map) {
    return Sale.fromMap(map, enterpriseId);
  }

  @override
  Map<String, dynamic> toMap(Sale entity) {
    return entity.toMap();
  }

  @override
  String getLocalId(Sale entity) => entity.id;

  @override
  String? getRemoteId(Sale entity) => null; // We use local IDs primarily

  @override
  String? getEnterpriseId(Sale entity) => enterpriseId;

  // --- Secure Receipt Logic ---

  Future<String> _generateTicketHash(Sale sale) async {
    // 1. Get the last sale's hash for chaining
    final lastSaleQuery = db.select(db.salesTable)
      ..where((t) => t.enterpriseId.equals(enterpriseId))
      ..where((t) => t.id.equals(sale.id).not()) // Don't chain to yourself if updating
      ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)])
      ..limit(1);
    
    final lastSale = await lastSaleQuery.getSingleOrNull();
    final previousHash = lastSale?.ticketHash;

    // 2. Generate new hash
    return LedgerHashService.generateHash(
      previousHash: previousHash,
      entity: sale,
      shopSecret: shopSecret,
    );
  }

  // --- Data Access Overrides (Relational) ---

  @override
  Future<void> saveToLocal(Sale sale) async {
    // 1. Generate Secure Hash
    final lastSale = await (db.select(db.salesTable)
          ..where((t) => t.enterpriseId.equals(enterpriseId))
          ..where((t) => t.id.equals(sale.id).not())
          ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)])
          ..limit(1))
        .getSingleOrNull();
        
    final previousHash = lastSale?.ticketHash;
    final ticketHash = await _generateTicketHash(sale);

    final saleWithHash = sale.copyWith(
      ticketHash: ticketHash,
      previousHash: previousHash,
      updatedAt: DateTime.now(),
    );

    // 2. Prepare Companions
    final saleCompanion = SalesTableCompanion(
      id: Value(saleWithHash.id),
      enterpriseId: Value(enterpriseId),
      date: Value(saleWithHash.date),
      totalAmount: Value(saleWithHash.totalAmount),
      amountPaid: Value(saleWithHash.amountPaid),
      customerName: Value(saleWithHash.customerName),
      paymentMethod: Value(saleWithHash.paymentMethod?.name),
      notes: Value(saleWithHash.notes),
      cashAmount: Value(saleWithHash.cashAmount),
      mobileMoneyAmount: Value(saleWithHash.mobileMoneyAmount),
      ticketHash: Value(ticketHash),
      previousHash: Value(previousHash),
      createdAt: Value(saleWithHash.createdAt),
      updatedAt: Value(saleWithHash.updatedAt),
      deletedAt: Value(saleWithHash.deletedAt),
      deletedBy: Value(saleWithHash.deletedBy),
      number: Value(saleWithHash.number),
    );

    await db.transaction(() async {
      // Upsert Sale
      await db.into(db.salesTable).insertOnConflictUpdate(saleCompanion);

      // Replace Items (Simpler than diffing)
      await (db.delete(db.saleItemsTable)..where((t) => t.saleId.equals(sale.id))).go();

      for (final item in sale.items) {
        await db.into(db.saleItemsTable).insert(
              SaleItemsTableCompanion(
                saleId: Value(sale.id),
                productId: Value(item.productId),
                productName: Value(item.productName),
                quantity: Value(item.quantity),
                unitPrice: Value(item.unitPrice),
                purchasePrice: Value(item.purchasePrice),
                totalPrice: Value(item.totalPrice),
              ),
            );
      }
    });

    // We still queue the FULL JSON for sync (handled by OfflineRepository base class)
    // base.save() calls saveToLocal(), so we are good.
  }

  @override
  Future<void> deleteFromLocal(Sale entity) async {
    // Soft delete is preferred in our system, but if hard delete is requested:
    await (db.delete(db.salesTable)..where((t) => t.id.equals(entity.id))).go();
    // Cascade delete of items handles the rest if configured, else:
    await (db.delete(db.saleItemsTable)..where((t) => t.saleId.equals(entity.id))).go();
  }

  @override
  Future<List<Sale>> getAllForEnterprise(String enterpriseId) async {
    final salesQuery = db.select(db.salesTable)
      ..where((t) => t.enterpriseId.equals(enterpriseId))
      ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]);

    final salesRows = await salesQuery.get();
    
    // Efficiently fetch all items for these sales
    // Logic: Fetch all items where saleId IN (salesRows.ids)
    final saleIds = salesRows.map((e) => e.id).toList();
    final itemsQuery = db.select(db.saleItemsTable)
      ..where((t) => t.saleId.isIn(saleIds));
    final itemsRows = await itemsQuery.get();

    // Group items by SaleId
    final Map<String, List<SaleItem>> itemsMap = {};
    for (final itemRow in itemsRows) {
      if (!itemsMap.containsKey(itemRow.saleId)) {
        itemsMap[itemRow.saleId] = [];
      }
      itemsMap[itemRow.saleId]!.add(
        SaleItem(
          productId: itemRow.productId,
          productName: itemRow.productName,
          quantity: itemRow.quantity,
          unitPrice: itemRow.unitPrice,
          purchasePrice: itemRow.purchasePrice,
          totalPrice: itemRow.totalPrice,
        ),
      );
    }

    // Map rows to Entities
    return salesRows.map((row) {
      return _mapRowToEntity(row, itemsMap[row.id] ?? []);
    }).toList();
  }

  @override
  Future<int> getCountForDate(DateTime date) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      
      final query = driftService.db.select(driftService.db.salesTable)
        ..where((t) => t.enterpriseId.equals(enterpriseId))
        ..where((t) => t.date.isBetweenValues(start, end))
        ..where((t) => t.deletedAt.isNull());
      
      final rows = await query.get();
      return rows.length;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error counting sales for date: $date',
        name: 'SaleOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<Sale?> getByLocalId(String id) async {
    final saleRow = await (db.select(db.salesTable)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (saleRow == null) return null;

    final itemsRows = await (db.select(db.saleItemsTable)..where((t) => t.saleId.equals(id))).get();
    final items = itemsRows.map((itemRow) => SaleItem(
      productId: itemRow.productId,
      productName: itemRow.productName,
      quantity: itemRow.quantity,
      unitPrice: itemRow.unitPrice,
      purchasePrice: itemRow.purchasePrice,
      totalPrice: itemRow.totalPrice,
    )).toList();

    return _mapRowToEntity(saleRow, items);
  }

  Sale _mapRowToEntity(SaleEntity row, List<SaleItem> items) {
    PaymentMethod? paymentMethod;
    if (row.paymentMethod != null) {
      switch (row.paymentMethod) {
        case 'cash': paymentMethod = PaymentMethod.cash; break;
        case 'mobileMoney': paymentMethod = PaymentMethod.mobileMoney; break;
        case 'both': paymentMethod = PaymentMethod.both; break;
      }
    }

    return Sale(
      id: row.id,
      enterpriseId: row.enterpriseId,
      date: row.date,
      items: items,
      totalAmount: row.totalAmount,
      amountPaid: row.amountPaid,
      customerName: row.customerName,
      paymentMethod: paymentMethod,
      notes: row.notes,
      cashAmount: row.cashAmount,
      mobileMoneyAmount: row.mobileMoneyAmount,
      ticketHash: row.ticketHash,
      previousHash: row.previousHash,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
      deletedBy: row.deletedBy,
      number: row.number,
    );
  }

  // --- SaleRepository Constraints ---

  @override
  Future<Sale> createSale(Sale sale) async {
    try {
      // 1. Generate Secure Hash explicitly here to return it
      final lastSale = await (db.select(db.salesTable)
            ..where((t) => t.enterpriseId.equals(enterpriseId))
            ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)])
            ..limit(1))
          .getSingleOrNull();
          
      final previousHash = lastSale?.ticketHash;
      final ticketHash = await _generateTicketHash(sale);

      final saleWithHash = sale.copyWith(
        ticketHash: ticketHash,
        previousHash: previousHash,
        updatedAt: DateTime.now(),
      );

      // 2. Save the sale with hash
      // We pass saleWithHash to save(), which calls saveToLocal.
      // Note: saveToLocal also calculates hash? We should optimize this.
      // To avoid double calculation, we can update saveToLocal to reuse if present,
      // or just assume createSale handles it and saveToLocal is for sync/restore too.
      // For now, let's just make saveToLocal use existing hash if present.
      await save(saleWithHash); 
      
      // Audit Log
      await _logAudit(
        action: 'create_sale',
        entityId: saleWithHash.id,
        metadata: {'totalAmount': saleWithHash.totalAmount, 'hash': saleWithHash.ticketHash},
      );

      return saleWithHash;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error('Error creating sale: ${appException.message}', error: error);
      throw appException;
    }
  }

  @override
  Stream<List<Sale>> watchRecentSales({int limit = 50}) {
    return (db.select(db.salesTable)
          ..where((t) => t.enterpriseId.equals(enterpriseId))
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)])
          ..limit(limit))
        .watch()
        .asyncMap((rows) async {
          final sales = <Sale>[];
          for (final row in rows) {
             final items = await _fetchItemsForSale(row.id);
             sales.add(_mapRowToEntity(row, items));
          }
          return sales;
        });
  }

  Future<List<SaleItem>> _fetchItemsForSale(String saleId) async {
    final itemsRows = await (db.select(db.saleItemsTable)
          ..where((t) => t.saleId.equals(saleId)))
        .get();
    return itemsRows.map((itemRow) => SaleItem(
      productId: itemRow.productId,
      productName: itemRow.productName,
      quantity: itemRow.quantity,
      unitPrice: itemRow.unitPrice,
      purchasePrice: itemRow.purchasePrice,
      totalPrice: itemRow.totalPrice,
    )).toList();
  }

  // --- Helpers ---
  
  // Re-implementing unimplemented methods from interface with standard logic
  @override
  Future<List<Sale>> fetchRecentSales({int limit = 50}) async {
    final all = await getAllForEnterprise(enterpriseId);
    return all.take(limit).toList();
  }

  @override
  Future<List<Sale>> getSalesInPeriod(DateTime start, DateTime end) async {
     final query = db.select(db.salesTable)
      ..where((t) => t.enterpriseId.equals(enterpriseId))
      ..where((t) => t.date.isBetweenValues(start, end))
      ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]);
    
    // We reuse the logic to fetch items... or just fetch all and filter
    // Optimally, duplicate the join logic
    // For brevity, fetching all matching rows then items
    final rows = await query.get();
     final sales = <Sale>[];
      for (final row in rows) {
          final itemsRows = await (db.select(db.saleItemsTable)..where((t) => t.saleId.equals(row.id))).get();
          final items = itemsRows.map((r) => SaleItem(
            productId: r.productId,
            productName: r.productName,
            quantity: r.quantity,
            unitPrice: r.unitPrice,
            purchasePrice: r.purchasePrice,
            totalPrice: r.totalPrice,
          )).toList();
          sales.add(_mapRowToEntity(row, items));
      }
      return sales;
  }
  
  @override
  Future<Sale?> getSale(String id) => getByLocalId(id);

  @override
  Future<void> deleteSale(String id, {String? deletedBy}) async {
    final sale = await getSale(id);
    if (sale != null) {
      await save(sale.copyWith(deletedAt: DateTime.now(), deletedBy: deletedBy));
    }
  }

  @override
  Future<void> restoreSale(String id) async {
     final sale = await getSale(id);
    if (sale != null) {
      await save(sale.copyWith(deletedAt: null)); // Validation logic handled in save/entity
    }
  }

  @override
  Future<List<Sale>> getDeletedSales() async {
    try {
      final query = db.select(db.salesTable)
        ..where((t) => t.enterpriseId.equals(enterpriseId))
        ..where((t) => t.deletedAt.isNotNull())
        ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]);
      
      final rows = await query.get();
      final sales = <Sale>[];
      for (final row in rows) {
        final items = await _fetchItemsForSale(row.id);
        sales.add(_mapRowToEntity(row, items));
      }
      return sales;
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
    }
  }

  @override
  Stream<List<Sale>> watchDeletedSales() {
    return (db.select(db.salesTable)
          ..where((t) => t.enterpriseId.equals(enterpriseId))
          ..where((t) => t.deletedAt.isNotNull())
          ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]))
        .watch()
        .asyncMap((rows) async {
          final sales = <Sale>[];
          for (final row in rows) {
             final items = await _fetchItemsForSale(row.id);
             sales.add(_mapRowToEntity(row, items));
          }
          return sales;
        });
  }

  Future<void> _logAudit({
    required String action,
    required String entityId,
    Map<String, dynamic>? metadata,
  }) async {
     await auditTrailRepository.log(
        AuditRecord(
          id: '', 
          enterpriseId: enterpriseId,
          userId: userId, 
          module: 'boutique',
          action: action,
          entityId: entityId,
          entityType: 'sale',
          metadata: metadata,
          timestamp: DateTime.now(),
        ),
      );
  }
  @override
  Future<bool> verifyChain() async {
    try {
      final sales = await getAllForEnterprise(enterpriseId);
      if (sales.isEmpty) return true;

      // Reverse list to go from oldest to newest (or just rely on index - 1)
      // Actually sales are ordered by date DESC.
      // So [0] is newest, [1] is previous to [0].
      
      for (int i = 0; i < sales.length; i++) {
        final current = sales[i];
        final previous = i + 1 < sales.length ? sales[i + 1] : null;
        
        final isValid = LedgerHashService.verify(
          current,
          previous?.ticketHash,
          shopSecret,
        );
        
        if (!isValid) {
          AppLogger.error(
            'Chain integrity violation at sale ${current.id}. Previous: ${previous?.id}',
            name: 'SaleOfflineRepository',
          );
          return false;
        }
      }
      return true;
    } catch (e) {
      AppLogger.error('Chain verification failed', error: e);
      return false;
    }
  }

  @override
  Future<List<Sale>> fetchSales({int limit = 1000}) async {
    return fetchRecentSales(limit: limit);
  }
}
