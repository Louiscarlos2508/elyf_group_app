import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../application/tour_notifier.dart';
import '../../data/models/tour.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/features/administration/application/providers.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/wholesaler.dart';
import '../../../../shared/presentation/widgets/elyf_ui/atoms/elyf_button.dart';
import '../../../gaz/presentation/widgets/wholesaler_form_dialog.dart';

class CollecteScreen extends ConsumerWidget {
  final String tourId;

  const CollecteScreen({super.key, required this.tourId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(tourNotifierProvider(tourId)).value;
    
    // Récupération des données réelles
    final activeEnterprise = ref.watch(activeEnterpriseProvider).value;
    final enterpriseId = activeEnterprise?.id ?? '';
    
    // On utilise le provider réactif (Stream)
    final wholesalers = ref.watch(allWholesalersProvider(enterpriseId)).value ?? [];
    
    // Pour les POS, on récupère via le parent (l'entreprise active)
    final posList = ref.watch(enterprisesByParentAndTypeProvider((
      parentId: enterpriseId,
      type: EnterpriseType.gasPointOfSale,
    ))).value ?? [];

    // Fusion des sites (Grossistes + POS) pour la collecte
    final sites = [
      ...wholesalers.map((w) => Site(
        id: w.id, 
        nom: w.name, 
        adresse: w.address ?? '', 
        telephone: w.phone ?? '', 
        type: TypeSite.grossiste,
      )),
      ...posList.map((p) => Site(
        id: p.id, 
        nom: p.name, 
        adresse: p.address ?? '', 
        telephone: '', // Pas de téléphone dans Enterprise par défaut?
        type: TypeSite.pos,
      )),
    ];

    if (state == null) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.s16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Collecte des vides chez les clients',
                  style: theme.textTheme.titleMedium,
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _showWholesalerForm(context, enterpriseId, ref),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Ajouter Grossiste'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.s16),
              itemCount: sites.length,
              itemBuilder: (context, index) {
                final site = sites[index];
                final interaction = state.collectes.where((c) => c.siteId == site.id).firstOrNull;
                final isDone = interaction != null;

                return Card(
                  margin: const EdgeInsets.only(bottom: AppDimensions.s12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(AppDimensions.s12),
                    leading: CircleAvatar(
                      backgroundColor: site.type == TypeSite.pos ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      child: Icon(
                        site.type == TypeSite.pos ? Icons.shop : Icons.warehouse,
                        color: site.type == TypeSite.pos ? Colors.blue : Colors.orange,
                      ),
                    ),
                    title: Text(site.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(site.adresse),
                    trailing: isDone 
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.chevron_right),
                    onTap: () => context.pushNamed(
                      'collecte-site',
                      pathParameters: {'tourId': tourId, 'siteId': site.id},
                      extra: {'type': site.type, 'name': site.nom},
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.s16),
              child: FilledButton.icon(
                onPressed: state.collectes.isNotEmpty 
                    ? () async {
                        final router = GoRouter.of(context);
                        await ref.read(tourNotifierProvider(tourId).notifier).goToRecharge();
                        router.goNamed('recharge', pathParameters: {'tourId': tourId});
                      }
                    : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('ALLER À LA RECHARGE'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showWholesalerForm(BuildContext context, String enterpriseId, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      builder: (context) {
        return WholesalerFormDialog(
          enterpriseId: enterpriseId,
        );
      },
    ).then((result) {
      if (result == true) {
        ref.invalidate(allWholesalersProvider(enterpriseId));
      }
    });
  }
}
