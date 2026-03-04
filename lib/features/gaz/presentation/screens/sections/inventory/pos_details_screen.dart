import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/gas_sale.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/cylinder_stock.dart';
import 'package:elyf_groupe_app/features/audit_trail/domain/entities/audit_record.dart';
import 'package:elyf_groupe_app/features/audit_trail/application/providers.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import 'package:elyf_groupe_app/features/gaz/domain/services/gaz_stock_calculation_service.dart';
import 'package:intl/intl.dart';
import '../../../widgets/point_of_sale_stock_card.dart';
import '../../../widgets/wholesale_sale_card.dart';
import '../../../widgets/gaz_header.dart';

class PosDetailsScreen extends ConsumerStatefulWidget {
  const PosDetailsScreen({super.key, required this.pos});

  final Enterprise pos;

  @override
  ConsumerState<PosDetailsScreen> createState() => _PosDetailsScreenState();
}

class _PosDetailsScreenState extends ConsumerState<PosDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          GazHeader(
            title: widget.pos.name,
            subtitle: 'Vue d\'ensemble POS',
            asSliver: true,
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: const [
                Tab(text: 'Stock'),
                Tab(text: 'Mouvements'),
                Tab(text: 'Ventes'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _PosStockTab(pos: widget.pos),
            _PosMovementsTab(pos: widget.pos),
            _PosSalesTab(pos: widget.pos),
          ],
        ),
      ),
    );
  }
}

class _PosStockTab extends ConsumerWidget {
  const _PosStockTab({required this.pos});
  final Enterprise pos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allStocksAsync = ref.watch(gazStocksProvider);
    final cylinders = ref.watch(cylindersProvider).value ?? [];

    return allStocksAsync.when(
      data: (allStocks) {
        final metrics = GazStockCalculationService.calculatePosStockMetrics(
          enterpriseId: pos.id,
          allStocks: allStocks,
          cylinders: cylinders,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: PointOfSaleStockCard(
            enterprise: pos,
            fullBottles: metrics.totalFull,
            emptyBottles: metrics.totalEmpty,
            totalInTransit: metrics.totalInTransit,
            issueBottles: metrics.totalIssues,
            stockByCapacity: metrics.stockByCapacity,
          ),
        );
      },
      loading: () => AppShimmers.card(context),
      error: (e, _) => Center(child: Text('Erreur: $e')),
    );
  }
}

class _PosMovementsTab extends ConsumerWidget {
  const _PosMovementsTab({required this.pos});
  final Enterprise pos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditRepo = ref.watch(auditTrailRepositoryProvider);
    
    return FutureBuilder<List<AuditRecord>>(
      future: auditRepo.fetchRecords(
        enterpriseId: pos.id,
        module: 'gaz',
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AppShimmers.list(context);
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final records = snapshot.data ?? [];
        final movementRecords = records.where((r) => 
          r.action == 'POS_STOCK_ENTRY' || r.action == 'POS_STOCK_EXIT'
        ).toList();
        
        movementRecords.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        if (movementRecords.isEmpty) {
          return const Center(child: Text('Aucun mouvement enregistré'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: movementRecords.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final record = movementRecords[index];
            final isEntry = record.action == 'POS_STOCK_ENTRY';
            final quantities = record.metadata?['quantities'] as Map<String, dynamic>? ?? {};

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isEntry ? AppColors.success.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
                  child: Icon(
                    isEntry ? Icons.download_rounded : Icons.upload_rounded,
                    color: isEntry ? AppColors.success : AppColors.warning,
                  ),
                ),
                title: Text(isEntry ? 'Approvisionnement' : 'Retour de Vides'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('dd/MM/yyyy HH:mm').format(record.timestamp)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: quantities.entries.map((e) => Chip(
                        label: Text('${e.key}kg: ${e.value}'),
                        visualDensity: VisualDensity.compact,
                      )).toList(),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PosSalesTab extends ConsumerWidget {
  const _PosSalesTab({required this.pos});
  final Enterprise pos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gasController = ref.watch(gasControllerProvider);
    
    return StreamBuilder<List<GasSale>>(
      stream: gasController.watchSales(enterpriseIds: [pos.id]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AppShimmers.list(context);
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final sales = snapshot.data ?? [];
        sales.sort((a, b) => b.saleDate.compareTo(a.saleDate));

        if (sales.isEmpty) {
          return const Center(child: Text('Aucune vente enregistrée'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: sales.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final sale = sales[index];
            return WholesaleSaleCard(sale: sale);
          },
        );
      },
    );
  }
}
