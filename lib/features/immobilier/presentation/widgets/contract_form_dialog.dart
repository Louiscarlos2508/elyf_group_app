import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/entities/attached_file.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/immobilier/application/providers.dart';
import '../../domain/entities/contract.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/tenant.dart';
import 'contract_form_fields.dart';

class ContractFormDialog extends ConsumerStatefulWidget {
  const ContractFormDialog({
    super.key,
    this.contract,
  });

  final Contract? contract;

  @override
  ConsumerState<ContractFormDialog> createState() => _ContractFormDialogState();
}

class _ContractFormDialogState extends ConsumerState<ContractFormDialog>
    with FormHelperMixin {
  final _formKey = GlobalKey<FormState>();
  Property? _selectedProperty;
  Tenant? _selectedTenant;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 365));
  final _monthlyRentController = TextEditingController();
  final _depositController = TextEditingController();
  final _depositInMonthsController = TextEditingController();
  int? _paymentDay;
  final _notesController = TextEditingController();
  ContractStatus _status = ContractStatus.pending;
  List<AttachedFile> _attachedFiles = [];

  @override
  void initState() {
    super.initState();
    if (widget.contract != null) {
      final c = widget.contract!;
      _selectedProperty = c.property;
      _selectedTenant = c.tenant;
      _startDate = c.startDate;
      _endDate = c.endDate;
      _monthlyRentController.text = c.monthlyRent.toString();
      if (c.depositInMonths != null) {
        _depositInMonthsController.text = c.depositInMonths.toString();
        _depositController.text = c.calculatedDeposit.toString();
      } else {
        _depositController.text = c.deposit.toString();
      }
      _paymentDay = c.paymentDay;
      _notesController.text = c.notes ?? '';
      _status = c.status;
      _attachedFiles = c.attachedFiles ?? [];
    }
  }

  @override
  void dispose() {
    _monthlyRentController.dispose();
    _depositController.dispose();
    _depositInMonthsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(
    BuildContext context,
    bool isStartDate,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 365));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    // Utiliser le service de validation pour extraire la logique métier
    final validationService = ref.read(contractValidationServiceProvider);
    
    if (!validationService.isPropertySelected(_selectedProperty)) {
      NotificationService.showWarning(context, 'Veuillez sélectionner une propriété');
      return;
    }
    if (!validationService.isTenantSelected(_selectedTenant)) {
      NotificationService.showWarning(context, 'Veuillez sélectionner un locataire');
      return;
    }

    // Validation supplémentaire des dates
    final dateError = validationService.validateDates(
      startDate: _startDate,
      endDate: _endDate,
    );
    if (dateError != null) {
      NotificationService.showError(context, dateError);
      return;
    }

    await handleFormSubmit(
      context: context,
      formKey: _formKey,
      onLoadingChanged: (_) {}, // Pas besoin de gestion d'état de chargement séparée
      onSubmit: () async {
        // Déterminer si la caution est en mois ou montant fixe
        final depositInMonths = _depositInMonthsController.text.trim().isNotEmpty
            ? int.tryParse(_depositInMonthsController.text.trim())
            : null;
        final deposit = validationService.calculateDeposit(
          monthlyRent: int.parse(_monthlyRentController.text),
          depositInMonths: depositInMonths,
          depositAmount: int.tryParse(_depositController.text),
        );

        final contract = Contract(
          id: widget.contract?.id ?? IdGenerator.generate(),
          propertyId: _selectedProperty!.id,
          tenantId: _selectedTenant!.id,
          startDate: _startDate,
          endDate: _endDate,
          monthlyRent: int.parse(_monthlyRentController.text),
          deposit: deposit,
          status: _status,
          property: _selectedProperty,
          tenant: _selectedTenant,
          paymentDay: _paymentDay,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          depositInMonths: depositInMonths,
          createdAt: widget.contract?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
          attachedFiles: _attachedFiles.isEmpty ? null : _attachedFiles,
        );

        final controller = ref.read(contractControllerProvider);
        if (widget.contract == null) {
          await controller.createContract(contract);
          // Invalider aussi les propriétés pour mettre à jour le statut
          ref.invalidate(propertiesProvider);
        } else {
          await controller.updateContract(contract);
          // Invalider aussi les propriétés pour mettre à jour le statut
          ref.invalidate(propertiesProvider);
        }

        if (mounted) {
          ref.invalidate(contractsProvider);
          Navigator.of(context).pop();
        }

        return widget.contract == null
            ? 'Contrat créé avec succès'
            : 'Contrat mis à jour avec succès';
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final propertiesAsync = ref.watch(propertiesProvider);
    final tenantsAsync = ref.watch(tenantsProvider);

    return FormDialog(
      title: widget.contract == null ? 'Nouveau contrat' : 'Modifier le contrat',
      saveLabel: widget.contract == null ? 'Créer' : 'Enregistrer',
      onSave: _save,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            propertiesAsync.when(
              data: (properties) {
                // Filtrer les propriétés : exclure celles déjà louées sauf si on modifie un contrat existant
                final availableProperties = widget.contract == null
                    ? properties.where((p) => p.status != PropertyStatus.rented).toList()
                    : properties;
                
                // Si aucune propriété disponible et qu'on crée un nouveau contrat
                if (availableProperties.isEmpty && widget.contract == null) {
                  return const Text(
                    'Aucune propriété disponible. Toutes les propriétés sont déjà louées.',
                    style: TextStyle(color: Colors.orange),
                  );
                }
                
                return ContractFormFields.propertyField(
                  selectedProperty: _selectedProperty,
                  properties: availableProperties,
                  onChanged: (value) => setState(() => _selectedProperty = value),
                  validator: (value) {
                    if (value == null) return 'La propriété est requise';
                    return null;
                  },
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Erreur de chargement'),
            ),
            const SizedBox(height: 16),
            tenantsAsync.when(
              data: (tenants) => ContractFormFields.tenantField(
                selectedTenant: _selectedTenant,
                tenants: tenants,
                onChanged: (value) => setState(() => _selectedTenant = value),
                validator: (value) {
                  if (value == null) return 'Le locataire est requis';
                  return null;
                },
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Erreur de chargement'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ContractFormFields.dateField(
                    label: 'Date de début *',
                    date: _startDate,
                    onTap: () => _selectDate(context, true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ContractFormFields.dateField(
                    label: 'Date de fin *',
                    date: _endDate,
                    onTap: () => _selectDate(context, false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ContractFormFields.monthlyRentField(
              controller: _monthlyRentController,
              validator: (value) => Validators.amount(value, customMessage: 'Le loyer est requis'),
            ),
            const SizedBox(height: 16),
            ContractFormFields.depositField(
              depositController: _depositController,
              depositInMonthsController: _depositInMonthsController,
              monthlyRent: _monthlyRentController.text.isNotEmpty
                  ? int.tryParse(_monthlyRentController.text)
                  : null,
              initialDeposit: widget.contract?.depositInMonths == null
                  ? widget.contract?.deposit
                  : null,
              initialDepositInMonths: widget.contract?.depositInMonths,
            ),
            const SizedBox(height: 16),
            ContractFormFields.paymentDayField(
              value: _paymentDay,
              onChanged: (value) => setState(() => _paymentDay = value),
            ),
            const SizedBox(height: 16),
            ContractFormFields.statusField(
              value: _status,
              onChanged: (value) {
                if (value != null) setState(() => _status = value);
              },
            ),
            const SizedBox(height: 16),
            ContractFormFields.notesField(
              controller: _notesController,
            ),
            const SizedBox(height: 16),
            FileAttachmentField(
              attachedFiles: _attachedFiles,
              onFilesChanged: (files) {
                setState(() => _attachedFiles = files);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

