
import 'package:flutter/material.dart';
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
                    onPressed: () => _showForm(context, enterpriseId, ref),
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
                  backgroundColor: _getTierColor(wholesaler.tier),
                  child: Text(
                    wholesaler.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  wholesaler.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(wholesaler.phone ?? 'Pas de téléphone'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getTierColor(wholesaler.tier).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        wholesaler.tier.toUpperCase(),
                        style: TextStyle(
                          color: _getTierColor(wholesaler.tier),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElyfIconButton(
                      icon: Icons.edit_outlined,
                      onPressed: () => _showForm(context, enterpriseId, ref, wholesaler: wholesaler),
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
        onPressed: () => _showForm(context, enterpriseId, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showForm(BuildContext context, String enterpriseId, WidgetRef ref, {Wholesaler? wholesaler}) {
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

  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'gold':
        return Colors.orange;
      case 'silver':
        return Colors.blueGrey;
      case 'bronze':
        return Colors.brown;
      default:
        return Colors.blue;
    }
  }
}
