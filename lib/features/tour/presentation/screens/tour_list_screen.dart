import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../gaz/presentation/widgets/gaz_header.dart';
import '../../data/models/tour.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/tour.dart' as domain;

import 'package:elyf_groupe_app/features/gaz/presentation/widgets/wholesale/logistics_empty_state.dart';

class TourListScreen extends ConsumerWidget {
  const TourListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeEnterprise = ref.watch(activeEnterpriseProvider).value;
    
    // On observe les tours réels de l'entreprise active
    final toursAsync = ref.watch(toursStreamProvider((enterpriseId: activeEnterprise?.id ?? '', status: null)));

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed('tour-creation'),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau Tour'),
      ),
      body: CustomScrollView(
        slivers: [
          const GazHeader(
            title: 'GAZ',
            subtitle: 'Journal du Camion',
          ),
          SliverToBoxAdapter(
            child: toursAsync.when(
              data: (tours) {
                if (tours.isEmpty) {
                  return const LogisticsEmptyState();
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppDimensions.s16),
                  itemCount: tours.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.s12),
                  itemBuilder: (context, index) {
                    final tour = tours[index];
                    final status = TourStatusExtension.fromDomain(tour);
                    return _TourCard(
                      tour: tour,
                      onTap: () => context.pushNamed(
                        status.routeName, 
                        pathParameters: {'tourId': tour.id},
                      ),
                    );
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, __) => Center(child: Text('Erreur: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _TourCard extends ConsumerWidget {
  final domain.Tour tour;
  final VoidCallback onTap;

  const _TourCard({
    required this.tour,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final status = TourStatusExtension.fromDomain(tour);
    final statusColor = _getStatusColor(Theme.of(context), status);
    
    // Récupérer les prix d'achat pour l'estimation des dépenses
    final leaksAsync = ref.watch(tourLeaksProvider(tour.id));

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.r12),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Formatters.formatDate(tour.tourDate),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _StatusChip(status: status, color: statusColor),
                ],
              ),
              const SizedBox(height: AppDimensions.s8),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: AppDimensions.s4),
                  Text(
                    'Gérant', // Ou tour.driverName si disponible
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              const Divider(height: AppDimensions.s24),
              
              ref.watch(tourFinanceProvider(tour)).when(
                data: (finance) {
                  final leakCount = leaksAsync.value?.length ?? 0;

                  return Wrap(
                    spacing: AppDimensions.s16,
                    runSpacing: AppDimensions.s12,
                    children: [
                      _SummaryItem(label: 'Entrée', value: '${tour.totalEmptyBottlesCollected}', icon: Icons.download_outlined),
                      _SummaryItem(label: 'Sortie', value: '${tour.totalFullBottlesDelivered}', icon: Icons.upload_outlined),
                      _SummaryItem(label: 'Fuite', value: '$leakCount', icon: Icons.leak_add, valueColor: leakCount > 0 ? Colors.orange : null),
                      _SummaryItem(label: 'Dépense', value: Formatters.formatCurrency(finance.expenses), icon: Icons.money_off_outlined),
                      _SummaryItem(
                        label: 'Bénéfice', 
                        value: Formatters.formatCurrency(finance.profit), 
                        icon: Icons.account_balance_wallet_outlined,
                        valueColor: finance.profit >= 0 ? Colors.green : Colors.red,
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox(
                  height: 40,
                  child: Center(child: LinearProgressIndicator()),
                ),
                error: (e, __) => Text('Erreur Finance: $e'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ThemeData theme, TourStatus status) {
    return switch (status) {
      TourStatus.created    => theme.colorScheme.secondary,
      TourStatus.collecting => Colors.orange,
      TourStatus.recharging => Colors.blue,
      TourStatus.delivering => Colors.purple,
      TourStatus.closing    => Colors.teal,
      TourStatus.closed     => Colors.green,
    };
  }
}

class _StatusChip extends StatelessWidget {
  final TourStatus status;
  final Color color;

  const _StatusChip({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _SummaryItem({
    required this.label, 
    required this.value, 
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.primary),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value, 
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
            Text(label, style: theme.textTheme.labelSmall),
          ],
        ),
      ],
    );
  }
}
