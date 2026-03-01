import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/utils/notification_service.dart';
import '../../../../../core/errors/app_exceptions.dart';
import 'package:elyf_groupe_app/features/orange_money/application/providers.dart';
import 'package:elyf_groupe_app/features/orange_money/domain/entities/orange_money_settings.dart';
import '../../widgets/settings_account_card.dart';
import '../../widgets/settings_notifications_card.dart';
import '../../widgets/settings_sim_card.dart';
import '../../widgets/settings_system_info_card.dart';
import '../../widgets/settings_thresholds_card.dart';
import '../../widgets/settings_tips_card.dart';
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
          _settings = settings;
          _hasChanges = false;
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

  Future<void> _saveSettings() async {
    if (widget.enterpriseId == null || !_hasChanges || _settings == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final controller = ref.read(settingsControllerProvider);

      // Validate thresholds
      if (_settings!.criticalLiquidityThreshold < 0) {
        throw ValidationException(
          'Le seuil de liquidité ne peut pas être négatif',
          'NEGATIVE_LIQUIDITY_THRESHOLD',
        );
      }

      // Update notifications
      await controller.updateNotifications(
        widget.enterpriseId!,
        enableLiquidityAlerts: _settings!.enableLiquidityAlerts,
        enableCommissionReminders: _settings!.enableCommissionReminders,
        enableCheckpointReminders: _settings!.enableCheckpointReminders,
        enableTransactionAlerts: _settings!.enableTransactionAlerts,
      );

      // Update thresholds
      await controller.updateThresholds(
        widget.enterpriseId!,
        criticalLiquidityThreshold: _settings!.criticalLiquidityThreshold,
        checkpointDiscrepancyThreshold: _settings!.checkpointDiscrepancyThreshold,
        commissionReminderDays: _settings!.commissionReminderDays,
        largeTransactionThreshold: _settings!.largeTransactionThreshold,
      );

      // Update SIM number
      await controller.updateSimNumber(
        widget.enterpriseId!,
        _settings!.simNumber,
      );

      if (mounted) {
        setState(() {
          _hasChanges = false;
        });

        NotificationService.showSuccess(
          context,
          'Paramètres enregistrés avec succès',
        );
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

  void _handleSettingsChanged(OrangeMoneySettings settings) {
    setState(() {
      _settings = settings;
      _hasChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _settings == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final theme = Theme.of(context);

    if (_settings == null) {
      return const Center(child: Text('Aucun paramètre trouvé'));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          ElyfModuleHeader(
            title: 'Paramètres du Module',
            subtitle: 'Personnalisez vos alertes, seuils de liquidité et informations système.',
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
                  const SizedBox(height: 24),
                  SettingsThresholdsCard(
                    settings: _settings!,
                    onSettingsChanged: _handleSettingsChanged,
                  ),
                  const SizedBox(height: 24),
                  SettingsSimCard(
                    simNumber: _settings!.simNumber,
                    onSimNumberChanged: (val) {
                      _handleSettingsChanged(_settings!.copyWith(simNumber: val));
                    },
                  ),
                  const SizedBox(height: 24),
                  const SettingsAccountCard(),
                  const SizedBox(height: 24),
                  const SettingsSystemInfoCard(),
                  const SizedBox(height: 24),
                  const SettingsTipsCard(),
                  const SizedBox(height: 48),
                  _buildActionButtons(theme),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        SizedBox(
          height: 48,
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => _loadSettings(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Text(
              'Annuler',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
                fontFamily: 'Outfit',
              ),
            ),
          ),
        ),
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isLoading || !_hasChanges ? null : _saveSettings,
            icon: _isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                    ),
                  )
                : const Icon(Icons.save_rounded, size: 20),
            label: Text(
              _isLoading ? 'Enregistrement...' : 'Enregistrer les paramètres',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontFamily: 'Outfit',
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
