import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/production_session.dart';
import '../../widgets/production_session_form_steps.dart';

/// Écran de formulaire de session de production avec progression.
class ProductionSessionFormScreen extends ConsumerStatefulWidget {
  const ProductionSessionFormScreen({
    super.key,
    this.session,
  });

  final ProductionSession? session;

  @override
  ConsumerState<ProductionSessionFormScreen> createState() =>
      _ProductionSessionFormScreenState();
}

class _ProductionSessionFormScreenState
    extends ConsumerState<ProductionSessionFormScreen> {
  int _currentStep = 0;
  final _formStepsKey = GlobalKey<ProductionSessionFormStepsState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.session != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier session' : 'Nouvelle session'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          _buildProgressIndicator(theme),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ProductionSessionFormSteps(
                key: _formStepsKey,
                session: widget.session,
                currentStep: _currentStep,
                onStepChanged: (step) {
                  setState(() => _currentStep = step);
                },
              ),
            ),
          ),
          _buildBottomActions(context, theme),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(ThemeData theme) {
    final steps = [
      'Informations',
      'Consommations',
      'Machines & Bobines',
      'Résumé',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stepWidth = constraints.maxWidth / steps.length;
          
          return Row(
            children: steps.asMap().entries.map((entry) {
              final index = entry.key;
              final label = entry.value;
              final isActive = index == _currentStep;
              final isCompleted = index < _currentStep;

              return SizedBox(
                width: stepWidth,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive || isCompleted
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surfaceContainerHighest,
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: isCompleted
                                ? Icon(
                                    Icons.check,
                                    size: 22,
                                    color: theme.colorScheme.onPrimary,
                                  )
                                : Text(
                                    '${index + 1}',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: isActive
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isActive
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    if (index < steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 3,
                          margin: const EdgeInsets.only(bottom: 20, left: 8, right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: isCompleted
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() => _currentStep--);
                    },
                    child: const Text('Précédent'),
                  ),
                )
              else
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                ),
              if (_currentStep > 0) const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    if (_currentStep < 3) {
                      // Valider l'étape actuelle avant de passer à la suivante
                      final formState = _formStepsKey.currentState;
                      if (formState != null && formState.validateCurrentStep()) {
                        setState(() => _currentStep++);
                      }
                    } else {
                      // Dernière étape : soumettre le formulaire
                      final state = _formStepsKey.currentState;
                      if (state != null) {
                        await state.submit();
                      }
                    }
                  },
                  child: Text(_currentStep < 3 ? 'Suivant' : 'Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

