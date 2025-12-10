import 'package:flutter/material.dart';

import '../../../core/domain/entities/attached_file.dart';
import 'attached_file_item.dart';

/// Champ pour gérer les fichiers joints.
class FileAttachmentField extends StatelessWidget {
  const FileAttachmentField({
    super.key,
    required this.attachedFiles,
    required this.onFilesChanged,
    this.maxFiles = 10,
  });

  final List<AttachedFile> attachedFiles;
  final ValueChanged<List<AttachedFile>> onFilesChanged;
  final int maxFiles;

  Future<void> _pickFile(BuildContext context) async {
    // Pour l'instant, simulation d'un fichier
    // Dans une vraie implémentation, utiliser file_picker ou image_picker
    final result = await showDialog<AttachedFile>(
      context: context,
      builder: (context) => _FilePickerDialog(),
    );

    if (result != null && attachedFiles.length < maxFiles) {
      final newFiles = List<AttachedFile>.from(attachedFiles);
      newFiles.add(result);
      onFilesChanged(newFiles);
    } else if (attachedFiles.length >= maxFiles) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Maximum $maxFiles fichiers autorisés'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Fichiers joints',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (attachedFiles.length < maxFiles)
              IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: () => _pickFile(context),
                tooltip: 'Ajouter un fichier',
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (attachedFiles.isEmpty)
          Text(
            'Aucun fichier joint',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: attachedFiles.asMap().entries.map((entry) {
              final index = entry.key;
              final file = entry.value;
              return AttachedFileItem(
                file: file,
                onDelete: () {
                  final newFiles = List<AttachedFile>.from(attachedFiles);
                  newFiles.removeAt(index);
                  onFilesChanged(newFiles);
                },
              );
            }).toList(),
          ),
        if (attachedFiles.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${attachedFiles.length} fichier(s) joint(s)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ),
      ],
    );
  }
}

/// Dialog pour sélectionner un type de fichier (simulation).
class _FilePickerDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un fichier'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text('Photo'),
            onTap: () {
              // Simulation : créer un fichier image
              final file = AttachedFile(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
                path: '/simulated/path/to/image.jpg',
                type: AttachedFileType.image,
                size: 1024000, // 1 MB
                uploadedAt: DateTime.now(),
              );
              Navigator.of(context).pop(file);
            },
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: const Text('PDF'),
            onTap: () {
              // Simulation : créer un fichier PDF
              final file = AttachedFile(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: 'document_${DateTime.now().millisecondsSinceEpoch}.pdf',
                path: '/simulated/path/to/document.pdf',
                type: AttachedFileType.pdf,
                size: 2048000, // 2 MB
                uploadedAt: DateTime.now(),
              );
              Navigator.of(context).pop(file);
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Document'),
            onTap: () {
              // Simulation : créer un fichier document
              final file = AttachedFile(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: 'document_${DateTime.now().millisecondsSinceEpoch}.doc',
                path: '/simulated/path/to/document.doc',
                type: AttachedFileType.document,
                size: 512000, // 512 KB
                uploadedAt: DateTime.now(),
              );
              Navigator.of(context).pop(file);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}

