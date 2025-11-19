import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/controllers/production_controller.dart';
import '../../../application/providers.dart';
import '../../widgets/enhanced_list_card.dart';
import '../../widgets/form_dialog.dart';
import '../../widgets/production_form.dart';
import '../../widgets/section_placeholder.dart';

class ProductionScreen extends ConsumerWidget {
  const ProductionScreen({super.key});

  void _showForm(BuildContext context) {
    final formKey = GlobalKey<ProductionFormState>();
    showDialog(
      context: context,
      builder: (dialogContext) => FormDialog(
        title: 'Nouveau lot de production',
        child: ProductionForm(key: formKey),
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
    final state = ref.watch(productionStateProvider);
    return Scaffold(
      body: state.when(
        data: (data) => _ProductionList(state: data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => SectionPlaceholder(
          icon: Icons.factory_outlined,
          title: 'Production indisponible',
          subtitle: 'Impossible de récupérer les lots pour le moment.',
          primaryActionLabel: 'Réessayer',
          onPrimaryAction: () => ref.invalidate(productionStateProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau lot'),
      ),
    );
  }
}

class _ProductionList extends StatelessWidget {
  const _ProductionList({required this.state});

  final ProductionState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: state.productions.length,
      itemBuilder: (context, index) {
        final production = state.productions[index];
        return EnhancedListCard(
          title: 'Production • Période ${production.period}',
          subtitle: '${production.quantity} packs produits',
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              'P${production.period}',
              style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
            ),
          ),
          trailing: Chip(
            label: Text(
              '${production.date.day}/${production.date.month}',
              style: theme.textTheme.labelSmall,
            ),
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        );
      },
    );
  }
}
