
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/wholesaler.dart';
import '../../application/providers.dart';
import '../../../../../shared/presentation/widgets/elyf_ui/atoms/elyf_button.dart';
import '../../../../../shared/utils/notification_service.dart';

class WholesalerFormDialog extends ConsumerStatefulWidget {
  const WholesalerFormDialog({
    super.key,
    this.wholesaler,
    required this.enterpriseId,
  });

  final Wholesaler? wholesaler;
  final String enterpriseId;

  @override
  ConsumerState<WholesalerFormDialog> createState() => _WholesalerFormDialogState();
}

class _WholesalerFormDialogState extends ConsumerState<WholesalerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late String _tier;
  bool _isLoading = false;

  final List<String> _tiers = ['default'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.wholesaler?.name);
    _phoneController = TextEditingController(text: widget.wholesaler?.phone);
    _addressController = TextEditingController(text: widget.wholesaler?.address);
    _tier = widget.wholesaler?.tier ?? 'default';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.wholesaler != null;

    return AlertDialog(
      title: Text(isEditing ? 'Modifier Grossiste' : 'Nouveau Grossiste'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du grossiste *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Champ requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Adresse',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              /* Dropdown de palier supprimé car prix unique */
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElyfButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enregistrer'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final controller = ref.read(wholesalerControllerProvider);
      
      if (widget.wholesaler != null) {
        final updated = widget.wholesaler!.copyWith(
          name: _nameController.text,
          phone: _phoneController.text,
          address: _addressController.text,
          tier: _tier,
        );
        await controller.updateWholesaler(updated);
      } else {
        final newWholesaler = Wholesaler(
          id: 'local_${DateTime.now().millisecondsSinceEpoch}',
          enterpriseId: widget.enterpriseId,
          name: _nameController.text,
          phone: _phoneController.text,
          address: _addressController.text,
          tier: _tier,
        );
        await controller.registerWholesaler(newWholesaler);
      }

      if (mounted) {
        NotificationService.showSuccess(context, 'Grossiste enregistré avec succès');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, 'Erreur lors de l\'enregistrement: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
