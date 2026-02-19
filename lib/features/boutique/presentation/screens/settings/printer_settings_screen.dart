
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/boutique/application/providers.dart';
import 'package:elyf_groupe_app/features/boutique/presentation/widgets/boutique_header.dart';
import 'package:elyf_groupe_app/core/printing/printer_provider.dart';

class PrinterSettingsScreen extends ConsumerStatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  ConsumerState<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends ConsumerState<PrinterSettingsScreen> {
  String _selectedType = 'sunmi'; // sunmi, bluetooth, system
  bool _isLoading = true;
  bool _isTesting = false;
  
  final _headerController = TextEditingController();
  final _footerController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _loadSettings();
  }



  @override
  void dispose() {
    _headerController.dispose();
    _footerController.dispose();
    super.dispose();
  }



  Future<void> _loadSettings() async {
    final settingsService = ref.read(boutiqueSettingsServiceProvider);
    setState(() {
      _selectedType = settingsService.printerType;
      _headerController.text = settingsService.receiptHeader;
      _footerController.text = settingsService.receiptFooter;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings(String type) async {
    setState(() => _selectedType = type);
    await ref.read(boutiqueSettingsServiceProvider).setPrinterType(type);
    if (mounted) {
      NotificationService.showSuccess(context, 'Type d\'imprimante mis à jour');
    }
  }

  Future<void> _saveReceiptConfig() async {
    final settings = ref.read(boutiqueSettingsServiceProvider);
    await settings.setReceiptHeader(_headerController.text);
    await settings.setReceiptFooter(_footerController.text);
    if (mounted) {
      NotificationService.showSuccess(context, 'Configuration du reçu enregistrée');
    }
  }



  Future<void> _testPrint() async {
    setState(() => _isTesting = true);
    
    try {
      if (_selectedType == 'sunmi') {
        final sunmi = ref.read(activePrinterProvider);
        await sunmi.initialize();
        await sunmi.printReceipt('TEST D\'IMPRESSION ELYF\n\nImprimante Sunmi OK\n\n\n');
        if (mounted) NotificationService.showSuccess(context, 'Test envoyé au Sunmi');
        if (mounted) NotificationService.showError(context, 'Action non disponible (Bluetooth retiré)');
      } else {
        if (mounted) NotificationService.showInfo(context, 'Impression test simulée (Système)');
      }
    } catch (e) {
      if (mounted) NotificationService.showError(context, 'Erreur d\'impression: $e');
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const BoutiqueHeader(
            title: "IMPRIMANTE",
            subtitle: "Configuration matérielle",
            gradientColors: [Color(0xFF334155), Color(0xFF1E293B)],
            shadowColor: Color(0xFF334155),
            showBackButton: true,
          ),
          SliverFillRemaining(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Sélectionnez le type d'appareil :", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  
                  _buildOptionCard(
                    id: 'sunmi',
                    title: 'Terminal Sunmi V2/V3',
                    description: 'Appareil tout-en-un Android avec imprimante intégrée.',
                    icon: Icons.android,
                    color: Colors.orange,
                  ),
                  
                  
                  
                  _buildOptionCard(
                    id: 'system',
                    title: 'Impression Système',
                    description: 'Utiliser le service d\'print Android standard (PDF).',
                    icon: Icons.print,
                    color: Colors.grey,
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
                      hintText: 'Ex: MA BOUTIQUE ELYF',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _footerController,
                    decoration: const InputDecoration(
                      labelText: 'Pied de page du reçu',
                      hintText: 'Ex: Merci de votre visite !',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _saveReceiptConfig,
                    child: const Text('Enregistrer la personnalisation'),
                  ),

                  const SizedBox(height: 32),
                  
                  Center(
                    child: _isTesting 
                      ? const CircularProgressIndicator()
                      : FilledButton.icon(
                          onPressed: _testPrint,
                          icon: const Icon(Icons.print_outlined),
                          label: const Text("Lancer une impression de test"),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                        ),
                  ),
                  const SizedBox(height: 24),
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
      onTap: () => _saveSettings(id),
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSelected ? color : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }
}
