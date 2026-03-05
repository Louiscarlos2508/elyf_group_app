import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/orange_money/application/providers.dart';
import 'package:elyf_groupe_app/features/orange_money/domain/entities/orange_money_settings.dart';
import '../../widgets/settings_notifications_card.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';

/// Settings screen for Orange Money configuration.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, this.enterpriseId});

  final String? enterpriseId;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  OrangeMoneySettings? _settings;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (widget.enterpriseId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final controller = ref.read(settingsControllerProvider);
      final settings = await controller.getSettings(widget.enterpriseId!);

      if (settings != null && mounted) {
        setState(() {
          _settings = settings;
        });
      } else if (mounted) {
        // Initialize default if not found
        _settings = OrangeMoneySettings(
          id: widget.enterpriseId!,
          enterpriseId: widget.enterpriseId!,
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, 'Erreur lors du chargement: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _autoSaveSettings(OrangeMoneySettings newSettings) async {
    if (widget.enterpriseId == null) return;

    try {
      final controller = ref.read(settingsControllerProvider);
      await controller.saveSettings(newSettings);

      if (mounted) {
        NotificationService.showSuccess(
          context,
          'Paramètres enregistrés automatiquement',
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, 'Erreur lors de l\'enregistrement: $e');
        // Revert UI state if save fails
        _loadSettings();
      }
    }
  }

  void _handleSettingsChanged(OrangeMoneySettings settings) {
    setState(() {
      _settings = settings;
    });
    _autoSaveSettings(settings);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _settings == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_settings == null) {
      return const Center(child: Text('Aucun paramètre trouvé'));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const ElyfModuleHeader(
            title: 'Paramètres du Module',
            subtitle: 'Personnalisez vos rappels et informations système.',
            module: EnterpriseModule.mobileMoney,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SettingsNotificationsCard(
                    settings: _settings!,
                    onSettingsChanged: _handleSettingsChanged,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
