
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/immobilier/application/providers.dart';
import 'package:elyf_groupe_app/features/immobilier/presentation/widgets/immobilier_header.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/entities/immobilier_settings.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/core/printing/printer_provider.dart';

class ImmobilierSettingsScreen extends ConsumerStatefulWidget {
  const ImmobilierSettingsScreen({super.key});
 
  @override
  ConsumerState<ImmobilierSettingsScreen> createState() => _ImmobilierSettingsScreenState();
}
 
class _ImmobilierSettingsScreenState extends ConsumerState<ImmobilierSettingsScreen> {
  String _selectedType = 'system'; // sunmi, bluetooth, system
  bool _isLoading = true;
  bool _isTesting = false;
  
  bool _autoBillingEnabled = true;
  final _gracePeriodController = TextEditingController();
  final _penaltyRateController = TextEditingController();
  String _penaltyType = 'fixed'; // fixed, daily
  String? _enterpriseId;
 
  final _headerController = TextEditingController();
  final _footerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initial load will happen when build watches the enterprise & settings
  }

  @override
  void dispose() {
    _headerController.dispose();
    _footerController.dispose();
    _gracePeriodController.dispose();
    _penaltyRateController.dispose();
    super.dispose();
  }




  Future<void> _savePrinterType(String type) async {
    setState(() => _selectedType = type);
    await ref.read(immobilierSettingsServiceProvider).setPrinterType(type);
    if (mounted) {
      NotificationService.showSuccess(context, 'Type d\'imprimante mis à jour');
    }
  }

  Future<void> _saveReceiptConfig() async {
    if (_enterpriseId == null) {
       NotificationService.showError(context, 'Aucune entreprise sélectionnée');
       return;
    }

    final localSettings = ref.read(immobilierSettingsServiceProvider);
    await localSettings.setReceiptHeader(_headerController.text);
    await localSettings.setReceiptFooter(_footerController.text);
    
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



  Future<void> _testPrint() async {
    setState(() => _isTesting = true);
    try {
      final printer = ref.read(activePrinterProvider);
      final success = await printer.printReceipt('TEST D\'IMPRESSION IMMOBILIER\n\nConfiguration OK\n\n\n');
      if (success) {
        if (mounted) NotificationService.showSuccess(context, 'Test envoyé à l\'imprimante');
      } else {
        if (mounted) NotificationService.showError(context, 'L\'imprimante n\'est pas prête');
      }
    } catch (e) {
      if (mounted) NotificationService.showError(context, 'Erreur: $e');
    } finally {
      if (mounted) setState(() => _isTesting = false);
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

        // 1. Permissions (using stable provider)
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

            // 2. Listen for settings changes and update local state
            ref.listen<AsyncValue<ImmobilierSettings?>>(
              immobilierSettingsProvider(enterprise.id),
              (previous, next) {
                if (next is AsyncData) {
                  final settings = next.value;
                  if (_isLoading || _enterpriseId != enterprise.id) {
                    _isLoading = false;
                    _enterpriseId = enterprise.id;
                    _loadLocalAndRepoSettings(settings);
                    setState(() {});
                  }
                }
              },
            );

            // 3. Watch settings for UI rendering (nested when is ok if logic is clean)
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

  void _loadLocalAndRepoSettings(ImmobilierSettings? settings) {
    final localSettings = ref.read(immobilierSettingsServiceProvider);
    _selectedType = localSettings.printerType;
    _headerController.text = localSettings.receiptHeader;
    _footerController.text = localSettings.receiptFooter;

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
                  const Text("Type d'imprimante :", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  
                  _buildOptionCard(
                    id: 'sunmi',
                    title: 'Terminal Sunmi V2/V3',
                    description: 'Imprimante intégrée au terminal Android.',
                    icon: Icons.android,
                    color: Colors.orange,
                  ),
                  
                  
                  
                  _buildOptionCard(
                    id: 'system',
                    title: 'Impression Système',
                    description: 'Service d\'impression standard (PDF).',
                    icon: Icons.print,
                    color: Colors.grey,
                  ),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 24),
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
                  const Divider(),
                  const SizedBox(height: 24),
                  const Text("Personnalisation du reçu :", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _headerController,
                    decoration: const InputDecoration(
                      labelText: 'En-tête du reçu',
                      hintText: 'Ex: ELYF IMMOBILIER',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _footerController,
                    decoration: const InputDecoration(
                      labelText: 'Pied de page du reçu',
                      hintText: 'Ex: Merci de votre confiance !',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveReceiptConfig,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Enregistrer tous les paramètres'),
                    ),
                  ),

                  const SizedBox(height: 48),
                  Center(
                    child: _isTesting 
                      ? const CircularProgressIndicator()
                      : FilledButton.icon(
                          onPressed: _testPrint,
                          icon: const Icon(Icons.print_outlined),
                          label: const Text("Impression de test"),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
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



  Widget _buildOptionCard({
    required String id,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedType == id;
    return GestureDetector(
      onTap: () => _savePrinterType(id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(description, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }
}
