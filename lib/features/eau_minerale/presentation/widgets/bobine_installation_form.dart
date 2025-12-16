import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/bobine_stock.dart';
import '../../domain/entities/bobine_usage.dart';
import '../../domain/entities/machine.dart';
import '../../domain/entities/production_session_status.dart';
import 'bobine_usage_form_field.dart' show bobineStocksDisponiblesProvider;

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
              debugPrint('Bobine non finie trouvée pour ${widget.machine.nom}: ${bobine.bobineType} dans session ${session.id}');
            }
            // Si on a trouvé une bobine, on peut arrêter (on prend la plus récente)
            break;
          }
        }
        // Si on a trouvé une bobine, on peut arrêter de chercher
        if (bobineNonFinieTrouvee != null) break;
      }
      
      setState(() {
        _bobineNonFinieExistante = bobineNonFinieTrouvee;
        _aChargeBobines = true;
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement de la bobine non finie: $e');
      setState(() {
        _aChargeBobines = true;
      });
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
        usage = _bobineNonFinieExistante!.copyWith(
          dateInstallation: dateHeureInstallation,
          heureInstallation: dateHeureInstallation,
        );
      } else {
        // Prendre automatiquement le premier type de bobine disponible
        final bobineStocks = await ref.read(bobineStocksDisponiblesProvider.future);
        if (bobineStocks.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Aucune bobine disponible en stock'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
        
        final bobineStock = bobineStocks.first;
        
        // Décrémenter le stock IMMÉDIATEMENT en temps réel lors de l'installation
        final stockController = ref.read(stockControllerProvider);
        try {
          await stockController.recordBobineExit(
            bobineType: bobineStock.type,
            quantite: 1,
            productionId: null, // Sera mis à jour lors de la sauvegarde de la session
            machineId: widget.machine.id,
            notes: 'Installation en production - ${widget.machine.nom}',
          );
          
          // Invalider le provider pour rafraîchir le stock en temps réel
          ref.invalidate(bobineStocksDisponiblesProvider);
          ref.invalidate(stockStateProvider);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur lors de la décrémentation du stock: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
        
        usage = BobineUsage(
          bobineType: bobineStock.type,
          machineId: widget.machine.id,
          machineName: widget.machine.nom,
          dateInstallation: dateHeureInstallation,
          heureInstallation: dateHeureInstallation,
          estInstallee: true,
          estFinie: false,
        );
      }

      widget.onInstalled?.call(usage);
      if (mounted) {
        Navigator.of(context).pop(usage);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _bobineNonFinieExistante != null
                  ? 'Bobine non finie réutilisée: ${_bobineNonFinieExistante!.bobineType}'
                  : 'Bobine installée: ${usage.bobineType}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'installation de la bobine: $e'),
            backgroundColor: Colors.red,
          ),
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

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Installation bobine - ${widget.machine.nom}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Si cette machine a une bobine non finie d\'une production précédente, elle sera réutilisée. Sinon, une bobine disponible sera automatiquement assignée.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            // Afficher l'info si une bobine non finie existe
            if (_bobineNonFinieExistante != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bobine non finie réutilisée',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'La bobine ${_bobineNonFinieExistante!.bobineType} sera réutilisée.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              // Affichage informatif : une bobine sera automatiquement assignée
              ref.watch(bobineStocksDisponiblesProvider).when(
                data: (bobineStocks) {
                  if (bobineStocks.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Aucune bobine disponible en stock',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Veuillez réapprovisionner le stock avant de continuer.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Une bobine sera automatiquement assignée',
                                style: theme.textTheme.bodyMedium,
                              ),
                              Text(
                                '${bobineStocks.fold<int>(0, (sum, stock) => sum + stock.quantity)} bobine${bobineStocks.fold<int>(0, (sum, stock) => sum + stock.quantity) > 1 ? 's' : ''} disponible${bobineStocks.fold<int>(0, (sum, stock) => sum + stock.quantity) > 1 ? 's' : ''}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Erreur lors du chargement des bobines',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date d\'installation *',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(_formatDate(_dateInstallation)),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _selectTime(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Heure d\'installation *',
                  prefixIcon: Icon(Icons.access_time),
                ),
                child: Text(_formatTime(_heureInstallation)),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isLoading ? null : _submit,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: Text(_isLoading ? 'Création...' : 'Ajouter et installer la bobine'),
            ),
          ],
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
    if (picked != null) {
      setState(() => _dateInstallation = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _heureInstallation,
    );
    if (picked != null) {
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
