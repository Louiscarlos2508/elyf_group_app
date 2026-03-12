import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:elyf_groupe_app/core/logging/app_logger.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/machine_material_usage.dart';
import 'machine_material_usage_form_field.dart' show machineMaterialsDisponiblesProvider;
import 'package:elyf_groupe_app/shared.dart';

/// Formulaire pour installer une matière sur une machine.
/// (Anciennement BobineInstallationForm).
class MachineMaterialInstallationForm extends ConsumerStatefulWidget {
  const MachineMaterialInstallationForm({
    super.key,
    required this.machine,
    this.onInstalled,
  });

  final Machine machine;
  final ValueChanged<MachineMaterialUsage>? onInstalled;

  @override
  ConsumerState<MachineMaterialInstallationForm> createState() =>
      _MachineMaterialInstallationFormState();
}

class _MachineMaterialInstallationFormState
    extends ConsumerState<MachineMaterialInstallationForm> {
  final _formKey = GlobalKey<FormState>();
  DateTime _dateInstallation = DateTime.now();
  TimeOfDay _heureInstallation = TimeOfDay.now();
  bool _isLoading = false;
  MachineMaterialUsage? _matiereNonFinieExistante;
  Product? _selectedMaterialProduct;
  bool _aChargeMatieres = false;

  @override
  void initState() {
    super.initState();
    _chargerMatiereNonFinie();
  }

  Future<void> _chargerMatiereNonFinie() async {
    if (_aChargeMatieres) return;

    try {
      final sessions = await ref.read(productionSessionsStateProvider.future);
      final sessionsTriees = sessions.toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      MachineMaterialUsage? matiereNonFinieTrouvee;

      for (final session in sessionsTriees) {
        for (final usage in session.machineMaterials) {
          if (!usage.estFinie && usage.machineId == widget.machine.id) {
            if (matiereNonFinieTrouvee == null) {
              matiereNonFinieTrouvee = usage;
              AppLogger.debug(
                'Matière non finie trouvée pour ${widget.machine.name}: ${usage.materialType} dans session ${session.id}',
                name: 'eau_minerale.production',
              );
            }
            break;
          }
        }
        if (matiereNonFinieTrouvee != null) break;
      }

      if (mounted) {
        setState(() {
          _matiereNonFinieExistante = matiereNonFinieTrouvee;
          _aChargeMatieres = true;
        });
      }
    } catch (e) {
      AppLogger.error(
        'Erreur lors du chargement de la matière non finie: $e',
        name: 'eau_minerale.production',
        error: e,
      );
      if (mounted) {
        setState(() {
          _aChargeMatieres = true;
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

      MachineMaterialUsage usage;

      if (_matiereNonFinieExistante != null) {
        usage = _matiereNonFinieExistante!.copyWith(
          isReused: true,
        );
      } else {
        if (_selectedMaterialProduct == null) {
          final materialStocks = await ref.read(machineMaterialsDisponiblesProvider.future);
          if (materialStocks.isNotEmpty) {
            final first = materialStocks.first;
            final allProds = await ref.read(productsProvider.future);
            _selectedMaterialProduct = allProds.where((p) => p.name.toLowerCase() == first.type.toLowerCase()).firstOrNull;
          }
        }

        if (_selectedMaterialProduct == null) {
          if (mounted) {
            NotificationService.showError(context, 'Veuillez sélectionner un type de matière');
            setState(() => _isLoading = false);
          }
          return;
        }

        usage = MachineMaterialUsage(
          id: const Uuid().v4(),
          materialType: _selectedMaterialProduct!.name,
          productId: _selectedMaterialProduct!.id,
          productName: _selectedMaterialProduct!.name,
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
          _matiereNonFinieExistante != null
              ? 'Matière réutilisée: ${_matiereNonFinieExistante!.materialType}'
              : 'Matière installée: ${usage.materialType}',
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
                              'Installation de matière',
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

            if (_matiereNonFinieExistante != null)
              _buildExistingMaterialAlert(theme, colors),

            const SizedBox(height: 16),

            if (_matiereNonFinieExistante == null) ...[
              const SizedBox(height: 16),
              _buildMaterialProductSelector(theme, colors),
            ],

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
                  
                  _buildDateTimePicker(
                    theme,
                    colors,
                    label: 'Date d\'installation',
                    value: _formatDate(_dateInstallation),
                    icon: Icons.calendar_today_rounded,
                    onTap: () => _selectDate(context),
                  ),
                  const SizedBox(height: 16),
                  
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

            if (_matiereNonFinieExistante == null)
              ref.watch(machineMaterialsDisponiblesProvider).maybeWhen(
                data: (stocks) => _buildStockInfo(theme, colors, stocks),
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

  Widget _buildExistingMaterialAlert(ThemeData theme, ColorScheme colors) {
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
                      'Matière précédente détectée',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                    ),
                    Text(
                      'Type: ${_matiereNonFinieExistante!.materialType}',
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
                      _matiereNonFinieExistante = null;
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
                   onPressed: null, 
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

  Widget _buildMaterialProductSelector(ThemeData theme, ColorScheme colors) {
    return ref.watch(productsProvider).when(
      data: (allProducts) {
        final products = allProducts.where((p) => p.name.toLowerCase().contains('bobine') || p.name.toLowerCase().contains('matière')).toList();
        if (products.isEmpty) return const SizedBox.shrink();

        if (_selectedMaterialProduct == null && products.length == 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedMaterialProduct = products.first);
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
                'Choix de la Matière',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Product>(
                initialValue: products.contains(_selectedMaterialProduct) ? _selectedMaterialProduct : null,
                borderRadius: BorderRadius.circular(16),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.inventory_2_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                items: products.map((p) => DropdownMenuItem(
                  value: p,
                  child: Text(p.name),
                )).toList(),
                onChanged: products.length <= 1 ? null : (p) => setState(() => _selectedMaterialProduct = p),
                validator: (v) => v == null ? 'Sélectionnez une matière' : null,
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildStockInfo(ThemeData theme, ColorScheme colors, List<dynamic> stocks) {
    if (_selectedMaterialProduct == null) return const SizedBox.shrink();
    if (stocks.isEmpty) return _buildEmptyStockWarning(theme, colors);
    
    final filteredStocks = stocks.where((stock) => 
      stock.type.toString().toLowerCase() == _selectedMaterialProduct!.name.toLowerCase()
    ).toList();

    if (filteredStocks.isEmpty) return _buildEmptyStockWarning(theme, colors);

    final total = filteredStocks.fold<int>(0, (sum, stock) => sum + (stock.quantity as num).toInt());
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
              '$total unité(s) disponible(s) en stock.',
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
            'Aucune matière disponible. Veuillez réapprovisionner.',
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
            'INSTALLER LA MATIÈRE',
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
