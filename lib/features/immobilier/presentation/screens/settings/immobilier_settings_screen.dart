
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/immobilier/application/providers.dart';
import 'package:elyf_groupe_app/features/immobilier/presentation/widgets/immobilier_header.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/entities/immobilier_settings.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';


class ImmobilierSettingsScreen extends ConsumerStatefulWidget {
  const ImmobilierSettingsScreen({super.key});
 
  @override
  ConsumerState<ImmobilierSettingsScreen> createState() => _ImmobilierSettingsScreenState();
}
 
class _ImmobilierSettingsScreenState extends ConsumerState<ImmobilierSettingsScreen> {
  bool _isLoading = true;
  
  bool _autoBillingEnabled = true;
  final _gracePeriodController = TextEditingController();
  final _penaltyRateController = TextEditingController();
  String _penaltyType = 'fixed'; // fixed, daily
  String? _enterpriseId;
 
  @override
  void dispose() {
    _gracePeriodController.dispose();
    _penaltyRateController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (_enterpriseId == null) {
       NotificationService.showError(context, 'Aucune entreprise sélectionnée');
       return;
    }

    final repoSettings = await ref.read(immobilierSettingsRepositoryProvider).getSettings(_enterpriseId!) ?? 
                        ImmobilierSettings(enterpriseId: _enterpriseId!);
    
    final updatedSettings = repoSettings.copyWith(
      autoBillingEnabled: _autoBillingEnabled,
      overdueGracePeriod: int.tryParse(_gracePeriodController.text) ?? 5,
      penaltyRate: double.tryParse(_penaltyRateController.text) ?? 0.0,
      penaltyType: _penaltyType,
    );

    await ref.read(immobilierSettingsRepositoryProvider).saveSettings(updatedSettings);

    if (mounted) {
      NotificationService.showSuccess(context, 'Paramètres enregistrés');
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeEnterpriseAsync = ref.watch(activeEnterpriseProvider);
    
    return activeEnterpriseAsync.when(
      data: (enterprise) {
        if (enterprise == null) {
          return const Scaffold(
            body: Center(
              child: Text('Veuillez sélectionner une entreprise'),
            ),
          );
        }

        final hasAccessAsync = ref.watch(userHasImmobilierPermissionProvider('manage_settings'));
        
        return hasAccessAsync.when(
          data: (hasAccess) {
            if (!hasAccess) {
              return const Scaffold(
                body: Center(
                  child: Text('Accès refusé. Permissions insuffisantes.'),
                ),
              );
            }

            ref.listen<AsyncValue<ImmobilierSettings?>>(
              immobilierSettingsProvider(enterprise.id),
              (previous, next) {
                if (next is AsyncData) {
                  final settings = next.value;
                  if (_isLoading || _enterpriseId != enterprise.id) {
                    _isLoading = false;
                    _enterpriseId = enterprise.id;
                    _loadRepoSettings(settings);
                    setState(() {});
                  }
                }
              },
            );

            final repoSettingsAsync = ref.watch(immobilierSettingsProvider(enterprise.id));

            return repoSettingsAsync.when(
              data: (settings) => _buildContent(context),
              loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
              error: (e, _) => Scaffold(body: Center(child: Text('Erreur: $e'))),
            );
          },
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(body: Center(child: Text('Erreur permissions: $e'))),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Erreur: $e'))),
    );
  }

  void _loadRepoSettings(ImmobilierSettings? settings) {
    if (settings != null) {
      _autoBillingEnabled = settings.autoBillingEnabled;
      _gracePeriodController.text = settings.overdueGracePeriod.toString();
      _penaltyRateController.text = settings.penaltyRate.toString();
      _penaltyType = settings.penaltyType;
    }
  }

  Widget _buildContent(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const ImmobilierHeader(
            title: "PARAMÈTRES",
            subtitle: "Configuration globale",
            showBackButton: false,
          ),
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Automatisation :", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  
                  SwitchListTile(
                    title: const Text('Facturation automatique'),
                    subtitle: const Text('Génère les paiements en attente chaque mois'),
                    value: _autoBillingEnabled,
                    onChanged: (val) => setState(() => _autoBillingEnabled = val),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _gracePeriodController,
                    decoration: const InputDecoration(
                      labelText: 'Délai de grâce supplémentaire (jours)',
                      hintText: 'Ex: 5',
                      border: OutlineInputBorder(),
                      helperText: 'Nombre de jours de tolérance après le jour de paiement prévu dans le contrat',
                    ),
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: 16),
                  const Text("Pénalités de retard :", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _penaltyRateController,
                          decoration: const InputDecoration(
                            labelText: 'Taux de pénalité (%)',
                            hintText: 'Ex: 5.0',
                            border: OutlineInputBorder(),
                            helperText: 'Pourcentage appliqué au loyer',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _penaltyType,
                          decoration: const InputDecoration(
                            labelText: 'Type de pénalité',
                            border: OutlineInputBorder(),
                            helperText: 'Fréquence d\'application',
                          ),
                          items: const [
                            DropdownMenuItem(value: 'fixed', child: Text('Unique (One-time)')),
                            DropdownMenuItem(value: 'daily', child: Text('Journalier (Daily)')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _penaltyType = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveSettings,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Enregistrer tous les paramètres'),
                    ),
                  ),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
