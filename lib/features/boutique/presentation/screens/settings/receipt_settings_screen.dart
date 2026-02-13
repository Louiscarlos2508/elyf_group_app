
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/boutique/application/providers.dart';
import 'package:elyf_groupe_app/features/boutique/presentation/widgets/boutique_header.dart';

class ReceiptSettingsScreen extends ConsumerStatefulWidget {
  const ReceiptSettingsScreen({super.key});

  @override
  ConsumerState<ReceiptSettingsScreen> createState() => _ReceiptSettingsScreenState();
}

class _ReceiptSettingsScreenState extends ConsumerState<ReceiptSettingsScreen> {
  final _headerController = TextEditingController();
  final _footerController = TextEditingController();
  bool _showLogo = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settingsService = ref.read(boutiqueSettingsServiceProvider);
    setState(() {
      _headerController.text = settingsService.receiptHeader;
      _footerController.text = settingsService.receiptFooter;
      _showLogo = settingsService.showLogo;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    final service = ref.read(boutiqueSettingsServiceProvider);
    
    await service.setReceiptHeader(_headerController.text);
    await service.setReceiptFooter(_footerController.text);
    await service.setShowLogo(_showLogo);

    if (mounted) {
      setState(() => _isLoading = false);
      NotificationService.showSuccess(context, 'Format du reçu mis à jour');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const BoutiqueHeader(
            title: "FORMAT REÇU",
            subtitle: "Personnalisation du ticket",
            gradientColors: [Color(0xFF4F46E5), Color(0xFF4338CA)], // Indigo
            shadowColor: Color(0xFF4F46E5),
            showBackButton: true,
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildPreviewCard(),
                  const SizedBox(height: 32),
                  SwitchListTile(
                    title: const Text("Afficher le Logo ELYF"),
                    value: _showLogo,
                    onChanged: (val) => setState(() => _showLogo = val),
                    secondary: const Icon(Icons.image),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _headerController,
                    decoration: const InputDecoration(
                      labelText: "En-tête (Nom de la Boutique)",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    onChanged: (_) => setState(() {}), // Update preview
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _footerController,
                    decoration: const InputDecoration(
                      labelText: "Pied de page (Message)",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.short_text),
                    ),
                    maxLines: 2,
                    onChanged: (_) => setState(() {}), // Update preview
                  ),
                  const Spacer(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saveSettings,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text("Enregistrer"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)), // Receipt style
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            if (_showLogo) const Icon(Icons.store, size: 48, color: Colors.indigo),
            const SizedBox(height: 8),
            Text(
              _headerController.text.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildDashedLine(),
            const SizedBox(height: 8),
            _buildFakeItem("Article 1", "500"),
            _buildFakeItem("Article 2", "1 500"),
            const SizedBox(height: 8),
            _buildDashedLine(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("TOTAL", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("2 000 FCFA", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _footerController.text,
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFakeItem(String name, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(name)),
          Text(price),
        ],
      ),
    );
  }

  Widget _buildDashedLine() {
    return Row(
      children: List.generate(
        150 ~/ 5,
        (index) => Expanded(
          child: Container(
            color: index % 2 == 0 ? Colors.transparent : Colors.grey,
            height: 1,
          ),
        ),
      ),
    );
  }
}
