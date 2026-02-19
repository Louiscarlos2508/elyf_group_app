import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../shared/shared.dart';
import '../../../../shared/providers/storage_provider.dart';
import '../../application/providers.dart';
import '../../domain/entities/commission.dart';
import '../widgets/commission_discrepancy_indicator.dart';

/// Dialog for declaring commission with SMS proof
class CommissionDeclarationDialog extends ConsumerStatefulWidget {
  final Commission commission;

  const CommissionDeclarationDialog({
    super.key,
    required this.commission,
  });

  @override
  ConsumerState<CommissionDeclarationDialog> createState() =>
      _CommissionDeclarationDialogState();
}

class _CommissionDeclarationDialogState
    extends ConsumerState<CommissionDeclarationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _declaredAmountController = TextEditingController();
  final _notesController = TextEditingController();
  final _imagePicker = ImagePicker();

  File? _smsProofImage;
  int? _declaredAmount;
  bool _isLoading = false;

  @override
  void dispose() {
    _declaredAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickSmsProof() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _smsProofImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, 'Erreur lors de la sélection de l\'image: $e');
      }
    }
  }

  void _calculateDiscrepancy(String value) {
    final amount = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
    setState(() {
      _declaredAmount = amount;
    });
  }

  Future<void> _handleDeclare() async {
    if (!_formKey.currentState!.validate()) return;

    if (_smsProofImage == null) {
      NotificationService.showError(context, 'Veuillez ajouter le screenshot du SMS');
      return;
    }

    if (_declaredAmount == null || _declaredAmount! <= 0) {
      NotificationService.showError(context, 'Montant invalide');
      return;
    }

    try {
      setState(() => _isLoading = true);

      // 1. Upload image
      final smsProofUrl = await ref.read(storageServiceProvider).uploadFile(
            file: _smsProofImage!,
            fileName: 'sms_proof_${DateTime.now().millisecondsSinceEpoch}.jpg',
            enterpriseId: widget.commission.enterpriseId,
            subfolder: 'commissions/${widget.commission.id}',
          );

      // 2. Get current user ID
      final userId = ref.read(currentUserIdProvider);

      // 3. Declare commission via service
      await ref.read(commissionServiceProvider).declareCommission(
            commissionId: widget.commission.id,
            declaredAmount: _declaredAmount!,
            smsProofUrl: smsProofUrl,
            declaredBy: userId,
          );

      // 4. Show success notification
      if (mounted) {
        NotificationService.showSuccess(context, 'Commission déclarée avec succès');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, 'Erreur: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Déclarer Commission ${widget.commission.period}'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Saisie montant SMS (PRIORITAIRE)
              TextFormField(
                controller: _declaredAmountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  labelText: 'Montant SMS (Reçu)',
                  labelStyle: const TextStyle(fontSize: 16),
                  hintText: 'ex: 50000',
                  prefixIcon: const Icon(Icons.message),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.blue.shade50.withOpacity(0.3),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Montant requis';
                  }
                  final amount = int.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Montant invalide';
                  }
                  return null;
                },
                onChanged: _calculateDiscrepancy,
              ),

              const SizedBox(height: 24),

              // 2. Upload screenshot SMS (OBLIGATOIRE)
              _buildImagePicker(),

              const SizedBox(height: 24),
              
              // 3. Vérification Système (Replié par défaut)
              ExpansionTile(
                title: const Text(
                  'Vérification Système',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: _declaredAmount != null 
                    ? CommissionDiscrepancyIndicator(
                        estimatedAmount: widget.commission.estimatedAmount,
                        declaredAmount: _declaredAmount!,
                        showDetails: false,
                      )
                    : const Text('Comparer avec le calcul théorique'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildEstimatedAmountCard(),
                        const SizedBox(height: 16),
                        if (widget.commission.calculationDetails != null)
                          _buildCalculationDetails(), // This will be nested, but OK for now or I should flatten it.
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 4. Notes optionnelles
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleDeclare,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Déclarer'),
        ),
      ],
    );
  }

  Widget _buildEstimatedAmountCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.calculate, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Montant Estimé (Système)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(widget.commission.estimatedAmount),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                if (widget.commission.transactionsCount > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${widget.commission.transactionsCount} transaction(s)',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationDetails() {
    final details = widget.commission.calculationDetails!;

    return ExpansionTile(
      title: const Text(
        'Détails du calcul',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _buildDetailRow(
                'Cash-In Total',
                CurrencyFormatter.format(details.totalCashIn),
              ),
              _buildDetailRow(
                'Commission Cash-In',
                CurrencyFormatter.format(details.cashInCommission),
              ),
              const Divider(),
              _buildDetailRow(
                'Cash-Out Total',
                CurrencyFormatter.format(details.totalCashOut),
              ),
              _buildDetailRow(
                'Commission Cash-Out',
                CurrencyFormatter.format(details.cashOutCommission),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Screenshot SMS Orange Money *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickSmsProof,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 2),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: _smsProofImage != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.file(
                          _smsProofImage!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _smsProofImage = null;
                            });
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate,
                          size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'Ajouter le screenshot du SMS',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
