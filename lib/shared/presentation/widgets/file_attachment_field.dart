import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/domain/entities/attached_file.dart';
import 'attached_file_item.dart';

/// Champ pour gérer les fichiers joints avec support réel de file_picker.
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
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
      );

      if (result != null && result.files.isNotEmpty) {
        final newFiles = List<AttachedFile>.from(attachedFiles);
        
        for (final file in result.files) {
          if (newFiles.length >= maxFiles) break;
          if (file.path == null) continue;

          // Déterminer le type de fichier
          final extension = file.extension?.toLowerCase() ?? '';
          final type = _getAttachedFileType(extension);

          newFiles.add(AttachedFile(
            id: DateTime.now().millisecondsSinceEpoch.toString() + file.name,
            name: file.name,
            path: file.path!,
            type: type,
            size: file.size,
            uploadedAt: DateTime.now(),
          ));
        }
        
        onFilesChanged(newFiles);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection des fichiers: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  AttachedFileType _getAttachedFileType(String extension) {
    if (['jpg', 'jpeg', 'png'].contains(extension)) {
      return AttachedFileType.image;
    } else if (extension == 'pdf') {
      return AttachedFileType.pdf;
    } else {
      return AttachedFileType.document;
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
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
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
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ),
      ],
    );
  }
}
