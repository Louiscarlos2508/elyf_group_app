import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:elyf_groupe_app/core/logging/app_logger.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/bobine_usage.dart';
import '../../domain/entities/machine.dart';
import 'bobine_usage_form_field.dart' show bobineStocksDisponiblesProvider;
import 'package:elyf_groupe_app/shared.dart';
import '../../domain/entities/product.dart';

/// Formulaire pour installer une bobine.
/// Crée automatiquement une nouvelle bobine et l'installe sur la machine.
class BobineInstallationForm extends ConsumerStatefulWidget {
  const BobineInstallationForm({
    super.key,
    required this.machine,
    this.onInstalled,
  });

  final Machine machine;
  final ValueChanged<BobineUsage>? onInstalled;

  @override
  ConsumerState<BobineInstallationForm> createState() =>
      _BobineInstallationFormState();
}

class _BobineInstallationFormState
    extends ConsumerState<BobineInstallationForm> {
  final _formKey = GlobalKey<FormState>();
  DateTime _dateInstallation = DateTime.now();
  TimeOfDay _heureInstallation = TimeOfDay.now();
  bool _isLoading = false;
  BobineUsage? _bobineNonFinieExistante;
  Product? _selectedBobineProduct;
  bool _aChargeBobines = false;

  @override
  void initState() {
    super.initState();
    _chargerBobineNonFinie();
  }

  Future<void> _chargerBobineNonFinie() async {
    if (_aChargeBobines) return;

    try {
      // Vérifier s'il existe déjà une bobine non finie pour cette machine
      final sessions = await ref.read(productionSessionsStateProvider.future);

      // Parcourir TOUTES les sessions de la plus récente à la plus ancienne
      // IMPORTANT: Même les sessions terminées peuvent avoir des bobines non finies
      // qui restent sur les machines et doivent être réutilisées
      final sessionsTriees = sessions.toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      // Chercher la bobine non finie la plus récente pour cette machine
      BobineUsage? bobineNonFinieTrouvee;

      for (final session in sessionsTriees) {
        for (final bobine in session.bobinesUtilisees) {
          // Si la bobine n'est pas finie et est sur cette machine
          if (!bobine.estFinie && bobine.machineId == widget.machine.id) {
            // Prendre la première trouvée (la plus récente car les sessions sont triées)
            if (bobineNonFinieTrouvee == null) {
              bobineNonFinieTrouvee = bobine;
              AppLogger.debug(
                'Bobine non finie trouvée pour ${widget.machine.name}: ${bobine.bobineType} dans session ${session.id}',
                name: 'eau_minerale.production',
              );
            }
            // Si on a trouvé une bobine, on peut arrêter (on prend la plus récente)
            break;
          }
        }
        // Si on a trouvé une bobine, on peut arrêter de chercher
        if (bobineNonFinieTrouvee != null) break;
      }

      if (mounted) {
        setState(() {
          _bobineNonFinieExistante = bobineNonFinieTrouvee;
          _aChargeBobines = true;
        });
      }
    } catch (e) {
      AppLogger.error(
        'Erreur lors du chargement de la bobine non finie: $e',
        name: 'eau_minerale.production',
        error: e,
      );
      if (mounted) {
        setState(() {
          _aChargeBobines = true;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final dateHeureInstallation = DateTime(
        _dateInstallation.year,
        _dateInstallation.month,
        _dateInstallation.day,
        _heureInstallation.hour,
        _heureInstallation.minute,
      );

      BobineUsage usage;

      if (_bobineNonFinieExistante != null) {
        // Réutiliser la bobine non finie existante (ne pas décrémenter car déjà fait)
        // On conserve son ID unique d'utilisation
        usage = _bobineNonFinieExistante!.copyWith(
          isReused: true,
        );
      } else {
        if (_selectedBobineProduct == null) {
          final bobineStocks = await ref.read(bobineStocksDisponiblesProvider.future);
          if (bobineStocks.isNotEmpty) {
            final first = bobineStocks.first;
            // Tenter de trouver le produit correspondant par nom
            final allProds = await ref.read(productsProvider.future);
            _selectedBobineProduct = allProds.where((p) => p.name.toLowerCase() == first.type.toLowerCase()).firstOrNull;
          }
        }

        if (_selectedBobineProduct == null) {
          if (mounted) {
            NotificationService.showError(context, 'Veuillez sélectionner un type de bobine');
            setState(() => _isLoading = false);
          }
          return;
        }

        usage = BobineUsage(
          id: const Uuid().v4(), // Nouvel ID unique pour cette nouvelle bobine physique
          bobineType: _selectedBobineProduct!.name,
          productId: _selectedBobineProduct!.id,
          productName: _selectedBobineProduct!.name,
          machineId: widget.machine.id,
          machineName: widget.machine.name,
          dateInstallation: dateHeureInstallation,
          heureInstallation: dateHeureInstallation,
          estInstallee: true,
          estFinie: false,
          isReused: false,
        );
      }

      widget.onInstalled?.call(usage);
      if (mounted) {
        Navigator.of(context).pop(usage);
        NotificationService.showSuccess(
          context,
          _bobineNonFinieExistante != null
              ? 'Bobine réutilisée: ${_bobineNonFinieExistante!.bobineType}'
              : 'Bobine installée: ${usage.bobineType}',
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(
          context,
          'Erreur lors de l\'installation: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section info
            ElyfCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 24,
              backgroundColor: colors.primary.withValues(alpha: 0.03),
              borderColor: colors.primary.withValues(alpha: 0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.settings_input_component_rounded, color: colors.primary, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.machine.name} (${widget.machine.reference})',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: colors.onSurface),
                            ),
                            Text(
                              'Installation de bobine',
                              style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Bobine Existante Alert
            if (_bobineNonFinieExistante != null)
              _buildExistingBobineAlert(theme, colors),

            const SizedBox(height: 16),

            // Bobine Product Selector (if not reusing)
            if (_bobineNonFinieExistante == null) ...[
              const SizedBox(height: 16),
              _buildBobineProductSelector(theme, colors),
            ],

            // Configuration Section
            ElyfCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 24,
              backgroundColor: colors.surfaceContainerLow,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time_filled_rounded, size: 18, color: colors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Configuration Temps',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Date Picker
                  _buildDateTimePicker(
                    theme,
                    colors,
                    label: 'Date d\'installation',
                    value: _formatDate(_dateInstallation),
                    icon: Icons.calendar_today_rounded,
                    onTap: () => _selectDate(context),
                  ),
                  const SizedBox(height: 16),
                  
                  // Time Picker
                  _buildDateTimePicker(
                    theme,
                    colors,
                    label: 'Heure d\'installation',
                    value: _formatTime(_heureInstallation),
                    icon: Icons.schedule_rounded,
                    onTap: () => _selectTime(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Stocks Disponibles Section (if not reusing)
            if (_bobineNonFinieExistante == null)
              ref.watch(bobineStocksDisponiblesProvider).maybeWhen(
                data: (bobineStocks) => _buildStockInfo(theme, colors, bobineStocks),
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
                orElse: () => const SizedBox.shrink(),
              ),

            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildExistingBobineAlert(ThemeData theme, ColorScheme colors) {
    return ElyfCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      backgroundColor: Colors.orange.withValues(alpha: 0.05),
      borderColor: Colors.orange.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.history_rounded, color: Colors.orange.shade800),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bobine précédente détectée',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                    ),
                    Text(
                      'Type: ${_bobineNonFinieExistante!.bobineType}',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange.shade800),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _bobineNonFinieExistante = null;
                      _dateInstallation = DateTime.now();
                      _heureInstallation = TimeOfDay.now();
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.error,
                    side: BorderSide(color: colors.error.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('IGNORER', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                   onPressed: null, // Déjà sélectionné
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.orange.shade800,
                    disabledBackgroundColor: Colors.orange.shade800,
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('RÉUTILISER', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBobineProductSelector(ThemeData theme, ColorScheme colors) {
    return ref.watch(productsProvider).when(
      data: (allProducts) {
        final products = allProducts.where((p) => p.name.toLowerCase().contains('bobine')).toList();
        if (products.isEmpty) return const SizedBox.shrink();

        // Auto-sélection si une seule bobine
        if (_selectedBobineProduct == null && products.length == 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedBobineProduct = products.first);
          });
        }

        return ElyfCard(
          padding: const EdgeInsets.all(20),
          borderRadius: 24,
          backgroundColor: colors.surfaceContainerLow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choix de la Bobine',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Product>(
                value: products.contains(_selectedBobineProduct) ? _selectedBobineProduct : null,
                borderRadius: BorderRadius.circular(16),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.inventory_2_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                items: products.map((p) => DropdownMenuItem(
                  value: p,
                  child: Text(p.name),
                )).toList(),
                onChanged: products.length <= 1 ? null : (p) => setState(() => _selectedBobineProduct = p),
                validator: (v) => v == null ? 'Sélectionnez une bobine' : null,
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildStockInfo(ThemeData theme, ColorScheme colors, List<dynamic> bobineStocks) {
    if (bobineStocks.isEmpty) return _buildEmptyStockWarning(theme, colors);
    
    final total = bobineStocks.fold<int>(0, (sum, stock) => sum + (stock.quantity as num).toInt());
    return ElyfCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      backgroundColor: colors.primary.withValues(alpha: 0.05),
      child: Row(
        children: [
          Icon(Icons.inventory_2_rounded, size: 18, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$total bobine${total > 1 ? 's' : ''} disponible${total > 1 ? 's' : ''} en stock.',
              style: theme.textTheme.bodySmall?.copyWith(color: colors.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStockWarning(ThemeData theme, ColorScheme colors) {
    return ElyfCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      backgroundColor: colors.errorContainer.withValues(alpha: 0.2),
      borderColor: colors.error.withValues(alpha: 0.3),
      child: Column(
        children: [
          Icon(Icons.report_problem_rounded, color: colors.error, size: 32),
          const SizedBox(height: 12),
          Text(
            'Stock Épuisé',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: colors.error),
          ),
          const SizedBox(height: 4),
          Text(
            'Aucune bobine disponible. Veuillez réapprovisionner.',
            style: theme.textTheme.bodySmall?.copyWith(color: colors.error),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimePicker(ThemeData theme, ColorScheme colors, {required String label, required String value, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outline.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: colors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
                  Text(value, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Icon(Icons.expand_more_rounded, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colors.primary, colors.secondary]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isLoading 
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text(
            'INSTALLER LA BOBINE',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateInstallation,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _dateInstallation = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _heureInstallation,
    );
    if (picked != null && mounted) {
      setState(() => _heureInstallation = picked);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }
}
