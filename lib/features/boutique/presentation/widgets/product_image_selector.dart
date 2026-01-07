import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared.dart';

class ProductImageSelector extends StatefulWidget {
  const ProductImageSelector({
    super.key,
    this.initialImageUrl,
    this.onImageSelected,
  });

  final String? initialImageUrl;
  final void Function(File?)? onImageSelected;

  @override
  State<ProductImageSelector> createState() => _ProductImageSelectorState();
}

class _ProductImageSelectorState extends State<ProductImageSelector> {
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
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        widget.onImageSelected?.call(_selectedImage);
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      String errorMessage = 'Erreur lors de la sélection d\'image';
      
      if (e.code == 'photo_access_denied' || e.code == 'camera_access_denied') {
        errorMessage = 'Permission refusée. Veuillez autoriser l\'accès à la caméra/galerie dans les paramètres.';
      } else if (e.code == 'photo_access_denied_permanently') {
        errorMessage = 'Permission refusée définitivement. Veuillez l\'activer dans les paramètres de l\'application.';
      } else if (e.code == 'camera_unavailable') {
        errorMessage = 'Caméra non disponible sur cet appareil.';
      } else if (e.message?.contains('channel') == true || 
                 e.message?.contains('connection') == true ||
                 e.code.contains('channel')) {
        errorMessage = 'Erreur de connexion avec le plugin. Veuillez redémarrer complètement l\'application (Hot Restart ou rebuild).';
      } else {
        errorMessage = 'Erreur: ${e.message ?? e.code}';
      }
      
      NotificationService.showError(context, errorMessage);
    } catch (e) {
      if (!mounted) return;
      String errorMessage = 'Erreur inattendue: ${e.toString()}';
      if (e.toString().contains('channel') || e.toString().contains('connection')) {
        errorMessage = 'Erreur de connexion avec le plugin. Veuillez redémarrer complètement l\'application (Hot Restart ou rebuild).';
      }
      NotificationService.showError(context, errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = _selectedImage != null || 
        (widget.initialImageUrl != null && _selectedImage == null);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Image du produit',
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        if (hasImage)
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _selectedImage != null
                  ? Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                    )
                  : widget.initialImageUrl != null
                      ? Image.network(
                          widget.initialImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildImagePlaceholder(theme),
                        )
                      : _buildImagePlaceholder(theme),
            ),
          ),
        if (hasImage) const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Galerie'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Appareil photo'),
              ),
            ),
          ],
        ),
        if (_selectedImage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              onPressed: () {
                setState(() => _selectedImage = null);
                widget.onImageSelected?.call(null);
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Supprimer l\'image'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImagePlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

