import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/immobilier/application/providers.dart';
import '../../../domain/entities/maintenance_ticket.dart';
import '../../widgets/immobilier_header.dart';
import '../../widgets/maintenance_ticket_card.dart';
import '../../widgets/maintenance_form_dialog.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';

class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          return CustomScrollView(
            slivers: [
              const ImmobilierHeader(
                title: 'MAINTENANCE',
                subtitle: 'Suivi des incidents',
              ),
              SliverPadding(
                padding: EdgeInsets.all(AppSpacing.lg),
                sliver: tickets.isEmpty
                    ? const SliverFillRemaining(
                        child: Center(
                          child: Text('Aucun ticket de maintenance.'),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final ticket = tickets[index];
                            final prop = propertiesAsync.value?.where((p) => p.id == ticket.propertyId).firstOrNull;
                            
                            return MaintenanceTicketCard(
                              ticket: ticket,
                              property: prop,
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => MaintenanceFormDialog(
                                    ticket: ticket,
                                    // initialProperty is for creation mode, so not needed here
                                    // but form dialog logic handles finding property via ticket.propertyId
                                  ),
                                );
                              },
                            );
                          },
                          childCount: tickets.length,
                        ),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }
}
