import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:elyf_groupe_app/shared.dart';

class FormImagePicker extends StatefulWidget {
  const FormImagePicker({
    super.key,
    this.initialImagePath,
    this.onImageSelected,
    this.label = 'Photo du document',
  });

  final String? initialImagePath;
  final void Function(File?)? onImageSelected;
  final String label;

  @override
  State<FormImagePicker> createState() => _FormImagePickerState();
}

class _FormImagePickerState extends State<FormImagePicker> {
  final _imagePicker = ImagePicker();
  File? _selectedImage;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isPickingImage) return;

    setState(() => _isPickingImage = true);

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 70, // Slightly lower quality for receipts to save space
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        widget.onImageSelected?.call(_selectedImage);
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      _handlePickerError(e);
    } catch (e) {
      if (!mounted) return;
      NotificationService.showError(context, 'Erreur inattendue: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  void _handlePickerError(PlatformException e) {
    String errorMessage = 'Erreur lors de la sélection d\'image';
    final errorCode = e.code.toLowerCase();
    
    if (errorCode == 'photo_access_denied' || errorCode == 'camera_access_denied') {
      errorMessage = 'Permission refusée. Veuillez autoriser l\'accès dans les paramètres.';
    } else if (errorCode == 'camera_unavailable') {
      errorMessage = 'Caméra non disponible sur cet appareil.';
    } else {
      errorMessage = 'Erreur: ${e.message ?? e.code}';
    }
    NotificationService.showError(context, errorMessage);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = _selectedImage != null || 
                    (widget.initialImagePath != null && _selectedImage == null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        if (hasImage)
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.15),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _selectedImage != null
                  ? Image.file(_selectedImage!, fit: BoxFit.contain, colorBlendMode: BlendMode.darken)
                  : Image.file(File(widget.initialImagePath!), fit: BoxFit.contain),
            ),
          ),
        if (hasImage) const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Galerie'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Prendre photo'),
              ),
            ),
          ],
        ),
          if (_selectedImage != null || widget.initialImagePath != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton.icon(
                onPressed: () {
                  setState(() => _selectedImage = null);
                  widget.onImageSelected?.call(null);
                },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Supprimer le reçu'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}
