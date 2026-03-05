
import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers.dart';
import '../../domain/entities/wholesaler.dart';
import '../widgets/wholesaler_form_dialog.dart';
import '../../../../../shared/presentation/widgets/elyf_ui/atoms/elyf_icon_button.dart';
import '../../../../../core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/shared.dart';

class WholesalerManagementScreen extends ConsumerWidget {
  const WholesalerManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? '';
    final wholesalersAsync = ref.watch(allWholesalersProvider(enterpriseId));

    return Scaffold(
      appBar: ElyfAppBar(
        title: 'Gestion des Grossistes',
        subtitle: 'PARTENAIRES GAZ',
        module: EnterpriseModule.gaz,
        actions: [
          EnterpriseSelectorWidget(style: EnterpriseSelectorStyle.appBar),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(allWholesalersProvider),
          ),
        ],
      ),
      body: wholesalersAsync.when(
        data: (wholesalers) {
          if (wholesalers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Aucun grossiste enregistré'),
                  const SizedBox(height: 24),
                  ElyfButton(
                    onPressed: () => _showWholesalerForm(context, enterpriseId, ref),
                    child: const Text('Ajouter mon premier grossiste'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: wholesalers.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final wholesaler = wholesalers[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    wholesaler.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  wholesaler.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (wholesaler.phone != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            Icon(Icons.phone, size: 14, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(wholesaler.phone!, style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _showWholesalerForm(context, enterpriseId, ref, wholesaler: wholesaler),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _confirmDelete(context, ref, wholesaler, enterpriseId),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showWholesalerForm(context, enterpriseId, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showWholesalerForm(BuildContext context, String enterpriseId, WidgetRef ref, {Wholesaler? wholesaler}) {
    showDialog(
      context: context,
      builder: (context) => WholesalerFormDialog(
        wholesaler: wholesaler,
        enterpriseId: enterpriseId,
      ),
    ).then((result) {
      if (result == true) {
        ref.invalidate(allWholesalersProvider);
      }
    });
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Wholesaler wholesaler, String enterpriseId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le grossiste ?'),
        content: Text('Voulez-vous vraiment supprimer ${wholesaler.name} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(wholesalerControllerProvider).deleteWholesaler(wholesaler.id);
              ref.invalidate(allWholesalersProvider(enterpriseId));
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
