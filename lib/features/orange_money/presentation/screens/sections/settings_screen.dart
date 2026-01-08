import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/utils/notification_service.dart';
import 'package:elyf_groupe_app/features/orange_money/application/providers.dart';
import '../../../domain/entities/settings.dart';
import '../../widgets/settings_account_card.dart';
import '../../widgets/settings_notifications_card.dart';
import '../../widgets/settings_sim_card.dart';
import '../../widgets/settings_system_info_card.dart';
import '../../widgets/settings_thresholds_card.dart';
import '../../widgets/settings_tips_card.dart';

/// Settings screen for Orange Money configuration.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, this.enterpriseId});

  final String? enterpriseId;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  NotificationSettings _notifications = const NotificationSettings();
  ThresholdSettings _thresholds = const ThresholdSettings();
  String _simNumber = '';
  bool _isLoading = false;
  bool _hasChanges = false;

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
          _notifications = settings.notifications;
          _thresholds = settings.thresholds;
          _simNumber = settings.simNumber;
          _hasChanges = false;
        });
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

  Future<void> _saveSettings() async {
    if (widget.enterpriseId == null || !_hasChanges) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final controller = ref.read(settingsControllerProvider);

      // Validate thresholds
      if (_thresholds.criticalLiquidityThreshold < 0) {
        throw Exception('Le seuil de liquidité ne peut pas être négatif');
      }
      if (_thresholds.paymentDueDaysBefore < 0 || _thresholds.paymentDueDaysBefore > 30) {
        throw Exception('Le nombre de jours doit être entre 0 et 30');
      }

      // Update notifications
      await controller.updateNotifications(
        widget.enterpriseId!,
        _notifications,
      );

      // Update thresholds
      await controller.updateThresholds(
        widget.enterpriseId!,
        _thresholds,
      );

      // Update SIM number
      await controller.updateSimNumber(
        widget.enterpriseId!,
        _simNumber,
      );

      if (mounted) {
        setState(() {
          _hasChanges = false;
        });
        
        NotificationService.showSuccess(context, 'Paramètres enregistrés avec succès');
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, 'Erreur: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleNotificationsChanged(NotificationSettings notifications) {
    setState(() {
      _notifications = notifications;
      _hasChanges = true;
    });
  }

  void _handleThresholdsChanged(ThresholdSettings thresholds) {
    setState(() {
      _thresholds = thresholds;
      _hasChanges = true;
    });
  }

  void _handleSimNumberChanged(String simNumber) {
    setState(() {
      _simNumber = simNumber;
      _hasChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _simNumber.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                SettingsNotificationsCard(
                  notifications: _notifications,
                  onNotificationsChanged: _handleNotificationsChanged,
                ),
                const SizedBox(height: 16),
                SettingsThresholdsCard(
                  thresholds: _thresholds,
                  onThresholdsChanged: _handleThresholdsChanged,
                ),
                const SizedBox(height: 16),
                SettingsSimCard(
                  simNumber: _simNumber,
                  onSimNumberChanged: _handleSimNumberChanged,
                ),
                const SizedBox(height: 16),
                const SettingsAccountCard(),
                const SizedBox(height: 16),
                const SettingsSystemInfoCard(),
                const SizedBox(height: 16),
                const SettingsTipsCard(),
                const SizedBox(height: 24),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Paramètres',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF101828),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Personnalisez les notifications et les seuils de l\'application',
          style: TextStyle(
            fontSize: 14,
            color: const Color(0xFF4A5565),
            fontWeight: FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        OutlinedButton(
          onPressed: _isLoading ? null : () {
            _loadSettings();
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            side: BorderSide(
              color: Colors.black.withValues(alpha: 0.1),
              width: 1.219,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 9),
            minimumSize: const Size(0, 36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Annuler',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF0A0A0A),
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading || !_hasChanges
              ? null
              : _saveSettings,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.save, size: 16),
          label: Text(_isLoading ? 'Enregistrement...' : 'Enregistrer les paramètres'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF54900),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFF54900).withValues(alpha: 0.5),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            minimumSize: const Size(0, 36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}
