import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/gas_sale.dart';
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
    final theme = Theme.of(context);
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
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.swap_vert_circle_outlined, size: 56, color: theme.colorScheme.outline),
                const SizedBox(height: 12),
                Text('Aucun mouvement enregistré', style: theme.textTheme.bodyLarge),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: movementRecords.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final record = movementRecords[index];
            final isEntry = record.action == 'POS_STOCK_ENTRY';
            final meta = record.metadata ?? {};
            
            // Decode full & empty bottle quantities from metadata
            final fullQties = _decodeQtyMap(meta['fullQuantities']);
            final emptyQties = _decodeQtyMap(meta['emptyQuantities']);
            final allQties = _decodeQtyMap(meta['quantities']); // legacy

            final Color cardColor = isEntry
                ? AppColors.success.withValues(alpha: 0.05)
                : AppColors.warning.withValues(alpha: 0.05);
            final Color iconColor = isEntry ? AppColors.success : AppColors.warning;
            final String label = isEntry ? 'Entrée de Stock' : 'Sortie — Rechargement';
            final IconData icon = isEntry ? Icons.download_rounded : Icons.upload_rounded;

            return Card(
              color: cardColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: iconColor.withValues(alpha: 0.2)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: iconColor.withValues(alpha: 0.15),
                          child: Icon(icon, color: iconColor, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: iconColor)),
                              Text(
                                DateFormat('dd/MM/yyyy – HH:mm').format(record.timestamp),
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (isEntry && (fullQties.isNotEmpty || emptyQties.isNotEmpty)) ...[
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      // Full bottles received
                      if (fullQties.isNotEmpty) ...[
                        _QuantityRow(
                          label: 'Pleins reçus',
                          icon: Icons.inventory_2_rounded,
                          color: AppColors.success,
                          quantities: fullQties,
                          theme: theme,
                        ),
                      ],
                      // Empty bottles returned (non-reloaded)
                      if (emptyQties.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _QuantityRow(
                          label: 'Vides retournés',
                          icon: Icons.assignment_return_rounded,
                          color: theme.colorScheme.tertiary,
                          quantities: emptyQties,
                          theme: theme,
                        ),
                      ],
                    ] else if (!isEntry && (allQties.isNotEmpty || emptyQties.isNotEmpty)) ...[
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      _QuantityRow(
                        label: 'Vides envoyés',
                        icon: Icons.upload_rounded,
                        color: AppColors.warning,
                        quantities: emptyQties.isNotEmpty ? emptyQties : allQties,
                        theme: theme,
                      ),
                    ] else if (allQties.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      _QuantityRow(
                        label: 'Bouteilles',
                        icon: Icons.local_gas_station_outlined,
                        color: iconColor,
                        quantities: allQties,
                        theme: theme,
                      ),
                    ],
                    if (record.metadata?['notes'] != null && (record.metadata!['notes'] as String).isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '💬 ${record.metadata!['notes']}',
                        style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Map<int, int> _decodeQtyMap(dynamic raw) {
    if (raw is! Map) return {};
    final result = <int, int>{};
    for (final e in raw.entries) {
      final key = int.tryParse(e.key.toString());
      final val = int.tryParse(e.value.toString());
      if (key != null && val != null && val > 0) result[key] = val;
    }
    return result;
  }
}

class _QuantityRow extends StatelessWidget {
  const _QuantityRow({
    required this.label,
    required this.icon,
    required this.color,
    required this.quantities,
    required this.theme,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Map<int, int> quantities;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final sorted = quantities.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Text('$label : ', style: theme.textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 2,
            children: sorted.map((e) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text(
                '${e.key}kg × ${e.value}',
                style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600),
              ),
            )).toList(),
          ),
        ),
      ],
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
