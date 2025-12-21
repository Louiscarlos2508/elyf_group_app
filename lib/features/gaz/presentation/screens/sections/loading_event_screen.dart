import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/loading_event.dart';
import '../../widgets/loading_event_card.dart';
import '../../widgets/loading_event_form_dialog.dart';
import '../../widgets/loading_expense_form_dialog.dart';

/// Écran de gestion des événements de chargement.
class LoadingEventScreen extends ConsumerStatefulWidget {
  const LoadingEventScreen({super.key});

  @override
  ConsumerState<LoadingEventScreen> createState() =>
      _LoadingEventScreenState();
}

class _LoadingEventScreenState extends ConsumerState<LoadingEventScreen> {
  String? _enterpriseId;
  LoadingEventStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    // TODO: Récupérer enterpriseId depuis le contexte/tenant
    _enterpriseId ??= 'default_enterprise';

    final eventsAsync = ref.watch(
      loadingEventsProvider(
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
                  Icons.local_shipping,
                  color: theme.colorScheme.primary,
                  size: isMobile ? 24 : 28,
                ),
                SizedBox(width: isMobile ? 8 : 12),
                Expanded(
                  child: Text(
                    'Événements de Chargement',
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
                        builder: (context) => const LoadingEventFormDialog(),
                      );
                      if (result == true && mounted) {
                        ref.invalidate(
                          loadingEventsProvider(
                            (enterpriseId: _enterpriseId!, status: null),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: Text(isMobile ? 'Nouveau' : 'Nouvel événement'),
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
                ...LoadingEventStatus.values.map((status) {
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
        eventsAsync.when(
          data: (events) {
            if (events.isEmpty) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        size: 64,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun événement de chargement',
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
                itemCount: events.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final event = events[index];
                  return LoadingEventCard(
                    event: event,
                    onAddExpense: () async {
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (context) => LoadingExpenseFormDialog(
                          eventId: event.id,
                        ),
                      );
                      if (result == true && mounted) {
                        ref.invalidate(
                          loadingEventsProvider(
                            (enterpriseId: _enterpriseId!, status: null),
                          ),
                        );
                      }
                    },
                    onComplete: () {
                      // TODO: Implémenter dialog de complétion avec réception
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fonctionnalité à implémenter'),
                        ),
                      );
                    },
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