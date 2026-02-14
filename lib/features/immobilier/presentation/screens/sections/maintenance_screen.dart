import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/immobilier/application/providers.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/entities/maintenance_ticket.dart';
import 'package:elyf_groupe_app/shared.dart';

import '../../widgets/immobilier_header.dart';
import '../../widgets/maintenance_ticket_card.dart';
import '../../widgets/maintenance_form_dialog.dart';
import '../../widgets/property_search_bar.dart';
import '../../widgets/maintenance_filters.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';

class MaintenanceScreen extends ConsumerStatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  ConsumerState<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen> {
  final _searchController = TextEditingController();
  MaintenanceStatus? _selectedStatus;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MaintenanceTicket> _filterTickets(List<MaintenanceTicket> tickets) {
    var filtered = tickets;

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((t) {
        return t.description.toLowerCase().contains(query) ||
            (t.propertyId.toLowerCase().contains(query));
      }).toList();
    }

    if (_selectedStatus != null) {
      filtered = filtered.where((t) => t.status == _selectedStatus).toList();
    }

    filtered.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
    
    return filtered;
  }

  Future<void> _deleteTicket(MaintenanceTicket ticket) async {
    final isArchived = ticket.deletedAt != null;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArchived ? 'Restaurer le ticket' : 'Archiver le ticket'),
        content: Text(
          isArchived 
              ? 'Voulez-vous restaurer ce ticket ?\nIl sera de nouveau visible dans la liste active.' 
              : 'Voulez-vous archiver ce ticket ?\nIl sera déplacé dans les archives.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: isArchived ? Colors.green : Colors.red,
            ),
            child: Text(isArchived ? 'Restaurer' : 'Archiver'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final controller = ref.read(maintenanceControllerProvider);
        if (isArchived) {
          await controller.restoreTicket(ticket.id);
          if (mounted) {
            ref.invalidate(maintenanceTicketsProvider);
            NotificationService.showSuccess(
              context,
              'Ticket restauré avec succès',
            );
          }
        } else {
          await controller.deleteTicket(ticket.id);
          if (mounted) {
            ref.invalidate(maintenanceTicketsProvider);
            NotificationService.showSuccess(
              context,
              'Ticket archivé avec succès',
            );
          }
        }
      } catch (e) {
        if (mounted) {
          NotificationService.showError(context, 'Erreur: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(maintenanceTicketsProvider);
    final propertiesAsync = ref.watch(propertiesProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const MaintenanceFormDialog(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nouveau Ticket'),
      ),
      body: ticketsAsync.when(
        data: (tickets) {
          final filtered = _filterTickets(tickets);

          return LayoutBuilder(
            builder: (context, constraints) {
              return CustomScrollView(
                slivers: [
                  const ImmobilierHeader(
                    title: 'MAINTENANCE',
                    subtitle: 'Suivi des incidents',
                  ),
                  
                  SliverToBoxAdapter(
                     child: PropertySearchBar(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      onClear: () => setState(() {}),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: MaintenanceFilters(
                      selectedStatus: _selectedStatus,
                      selectedArchiveFilter: ref.watch(archiveFilterProvider),
                      onStatusChanged: (status) =>
                          setState(() => _selectedStatus = status),
                      onArchiveFilterChanged: (filter) =>
                          ref.read(archiveFilterProvider.notifier).set(filter),
                      onClear: () {
                        setState(() => _selectedStatus = null);
                        ref.read(archiveFilterProvider.notifier).set(ArchiveFilter.active);
                      },
                    ),
                  ),

                  SliverPadding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    sliver: filtered.isEmpty
                        ? const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Text('Aucun ticket trouvé.'),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final ticket = filtered[index];
                                final prop = propertiesAsync.value?.where((p) => p.id == ticket.propertyId).firstOrNull;
                                
                                return MaintenanceTicketCard(
                                  ticket: ticket,
                                  property: prop,
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => MaintenanceFormDialog(
                                        ticket: ticket,
                                        onDelete: () => _deleteTicket(ticket),
                                      ),
                                    );
                                  },
                                );
                              },
                              childCount: filtered.length,
                            ),
                          ),
                  ),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }
}
