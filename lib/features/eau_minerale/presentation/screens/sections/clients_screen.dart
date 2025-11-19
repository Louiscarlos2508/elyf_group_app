import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/controllers/clients_controller.dart';
import '../../../application/providers.dart';
import '../../widgets/customer_form.dart';
import '../../widgets/enhanced_list_card.dart';
import '../../widgets/form_dialog.dart';
import '../../widgets/section_placeholder.dart';

class ClientsScreen extends ConsumerWidget {
  const ClientsScreen({super.key});

  void _showForm(BuildContext context) {
    final formKey = GlobalKey<CustomerFormState>();
    showDialog(
      context: context,
      builder: (context) => FormDialog(
        title: 'Nouveau client',
        child: CustomerForm(key: formKey),
        onSave: () async {
          final state = formKey.currentState;
          if (state != null) {
            await state.submit();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(clientsStateProvider);
    return Scaffold(
      body: state.when(
        data: (data) => _ClientsContent(state: data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => SectionPlaceholder(
          icon: Icons.people_alt_outlined,
          title: 'Clients indisponibles',
          subtitle: 'Impossible de charger les comptes clients.',
          primaryActionLabel: 'Réessayer',
          onPrimaryAction: () => ref.invalidate(clientsStateProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'clients_fab',
        onPressed: () => _showForm(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Nouveau client'),
      ),
    );
  }
}

class _ClientsContent extends StatelessWidget {
  const _ClientsContent({required this.state});

  final ClientsState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange.withValues(alpha: 0.2),
                Colors.orange.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                size: 32,
                color: theme.colorScheme.onSurface,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Crédits en cours',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${state.totalCredit} CFA',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: state.customers.length,
            itemBuilder: (context, index) {
              final client = state.customers[index];
              return EnhancedListCard(
                title: client.name,
                subtitle: client.phone,
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    client.name[0].toUpperCase(),
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                trailing: Chip(
                  label: Text(
                    client.totalCredit > 0
                        ? '${client.totalCredit} CFA'
                        : 'Aucun crédit',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: client.totalCredit > 0 ? Colors.orange : Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor:
                      (client.totalCredit > 0 ? Colors.orange : Colors.green)
                          .withValues(alpha: 0.1),
                  padding: EdgeInsets.zero,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
