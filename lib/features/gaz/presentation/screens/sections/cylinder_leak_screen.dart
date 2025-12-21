import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/cylinder_leak.dart';
import '../../widgets/cylinder_leak_form_dialog.dart';

/// Écran de gestion des bouteilles avec fuites.
class CylinderLeakScreen extends ConsumerStatefulWidget {
  const CylinderLeakScreen({super.key});

  @override
  ConsumerState<CylinderLeakScreen> createState() =>
      _CylinderLeakScreenState();
}

class _CylinderLeakScreenState extends ConsumerState<CylinderLeakScreen> {
  String? _enterpriseId;
  LeakStatus? _filterStatus;

  Color _getStatusColor(LeakStatus status) {
    switch (status) {
      case LeakStatus.reported:
        return Colors.orange;
      case LeakStatus.sentForExchange:
        return Colors.blue;
      case LeakStatus.exchanged:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    // TODO: Récupérer enterpriseId depuis le contexte/tenant
    _enterpriseId ??= 'default_enterprise';

    final leaksAsync = ref.watch(
      cylinderLeaksProvider(
        (enterpriseId: _enterpriseId!, status: _filterStatus),
      ),
    );

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Row(
              children: [
                Icon(
                  Icons.warning,
                  color: theme.colorScheme.primary,
                  size: isMobile ? 24 : 28,
                ),
                SizedBox(width: isMobile ? 8 : 12),
                Expanded(
                  child: Text(
                    'Bouteilles avec Fuites',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 20 : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: FilledButton.icon(
                    onPressed: () async {
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (context) => const CylinderLeakFormDialog(),
                      );
                      if (result == true && mounted) {
                        ref.invalidate(
                          cylinderLeaksProvider(
                            (enterpriseId: _enterpriseId!, status: null),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: Text(isMobile ? 'Signaler' : 'Signaler fuite'),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
            child: Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Tous'),
                  selected: _filterStatus == null,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _filterStatus = null);
                    }
                  },
                ),
                ...LeakStatus.values.map((status) {
                  return FilterChip(
                    label: Text(status.label),
                    selected: _filterStatus == status,
                    onSelected: (selected) {
                      setState(() {
                        _filterStatus = selected ? status : null;
                      });
                    },
                  );
                }),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        leaksAsync.when(
          data: (leaks) {
            if (leaks.isEmpty) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_outlined,
                        size: 64,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune fuite signalée',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
              sliver: SliverList.separated(
                itemCount: leaks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final leak = leaks[index];
                  final statusColor = _getStatusColor(leak.status);
                  final dateStr = '${leak.reportedDate.day}/${leak.reportedDate.month}/${leak.reportedDate.year}';

                  return Card(
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.warning,
                          color: statusColor,
                        ),
                      ),
                      title: Text('Bouteille ${leak.weight}kg'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ID: ${leak.cylinderId}'),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: statusColor),
                                ),
                                child: Text(
                                  leak.status.label,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            dateStr,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (leak.exchangeDate != null)
                            Text(
                              'Échangée: ${leak.exchangeDate!.day}/${leak.exchangeDate!.month}/${leak.exchangeDate!.year}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => SliverFillRemaining(
            child: Center(child: Text('Erreur: $e')),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}