import 'package:flutter/material.dart';

import '../../../core/domain/entities/attached_file.dart';

/// Widget pour afficher un fichier joint avec option de suppression.
class AttachedFileItem extends StatelessWidget {
  const AttachedFileItem({
    super.key,
    required this.file,
    required this.onDelete,
  });

  final AttachedFile file;
  final VoidCallback onDelete;

  IconData _getFileIcon() {
    switch (file.type) {
      case AttachedFileType.image:
        return Icons.image;
      case AttachedFileType.pdf:
        return Icons.picture_as_pdf;
      case AttachedFileType.document:
        return Icons.description;
    }
  }

  Color _getFileColor(BuildContext context) {
    switch (file.type) {
      case AttachedFileType.image:
        return Colors.blue;
      case AttachedFileType.pdf:
        return Colors.red;
      case AttachedFileType.document:
        return Colors.orange;
    }
  }

  String _formatFileSize(int? size) {
    if (size == null) return 'Taille inconnue';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fileColor = _getFileColor(context);

    return Card(
      child: InkWell(
        onTap: () {
          // Dans une vraie implémentation, ouvrir le fichier
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Ouverture de ${file.name}')));
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getFileIcon(), color: fileColor, size: 24),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      file.name,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (file.size != null)
                      Text(
                        _formatFileSize(file.size),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                color: Colors.red,
                onPressed: onDelete,
                tooltip: 'Supprimer',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
