
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/boutique/application/providers.dart';
import 'package:elyf_groupe_app/features/boutique/presentation/widgets/boutique_header.dart';

class PaymentSettingsScreen extends ConsumerStatefulWidget {
  const PaymentSettingsScreen({super.key});

  @override
  ConsumerState<PaymentSettingsScreen> createState() => _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState extends ConsumerState<PaymentSettingsScreen> {
  late List<String> _enabledMethods;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settingsService = ref.read(boutiqueSettingsServiceProvider);
    setState(() {
      _enabledMethods = settingsService.enabledPaymentMethods;
      _isLoading = false;
    });
  }

  Future<void> _toggleMethod(String id, bool value) async {
    setState(() {
      if (value) {
        _enabledMethods.add(id);
      } else {
        _enabledMethods.remove(id);
      }
    });
    
    // Save immediately
    await ref.read(boutiqueSettingsServiceProvider).togglePaymentMethod(id, value);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const BoutiqueHeader(
            title: "PAIEMENTS",
            subtitle: "Méthodes acceptées",
            gradientColors: [Color(0xFF0D9488), Color(0xFF0F766E)], // Teal
            shadowColor: Color(0xFF0D9488),
            showBackButton: true,
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    _buildSwitchTile(
                      'cash',
                      'Espèces (Cash)',
                      Icons.money,
                      Colors.green,
                      'Autoriser les paiements en liquide',
                    ),
                    _buildSwitchTile(
                      'mobile_money',
                      'Mobile Money',
                      Icons.phone_android,
                      Colors.orange,
                      'Orange Money, Moov Money, etc.',
                    ),
                    _buildSwitchTile(
                      'card',
                      'Carte Bancaire / TPE',
                      Icons.credit_card,
                      Colors.blue,
                      'Visa, Mastercard via terminal',
                    ),
                    _buildSwitchTile(
                      'check',
                      'Chèque',
                      Icons.edit_document,
                      Colors.grey,
                      'Paiement par chèque bancaire',
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String id, String title, IconData icon, Color color, String subtitle) {
    final isEnabled = _enabledMethods.contains(id);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: SwitchListTile(
        value: isEnabled,
        onChanged: (value) => _toggleMethod(id, value),
        title: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        activeColor: AppColors.primary,
      ),
    );
  }
}
