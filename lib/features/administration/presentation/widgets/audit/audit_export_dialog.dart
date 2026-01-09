import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../../domain/entities/audit_log.dart';
import '../../../domain/services/audit_export_service.dart';
import 'audit_export_option_card.dart';

/// Dialog for exporting audit logs.
class AuditExportDialog extends StatefulWidget {
  const AuditExportDialog({super.key, required this.logs});

  final List<AuditLog> logs;

  @override
  State<AuditExportDialog> createState() => _AuditExportDialogState();
}

class _AuditExportDialogState extends State<AuditExportDialog> {
  final _exportService = AuditExportService();
  bool _isExporting = false;
  String? _exportResult;
  bool _exportSuccess = false;

  Future<void> _exportToCsv() async {
    await _exportFile(
      content: _exportService.exportToCsv(widget.logs),
      extension: 'csv',
      formatName: 'CSV',
    );
  }

  Future<void> _exportToJson() async {
    await _exportFile(
      content: _exportService.exportToJson(widget.logs),
      extension: 'json',
      formatName: 'JSON',
    );
  }

  Future<void> _exportFile({
    required String content,
    required String extension,
    required String formatName,
  }) async {
    setState(() {
      _isExporting = true;
      _exportResult = null;
    });

    try {
      final filename = _exportService.generateFilename(extension);

      if (kIsWeb) {
        await Clipboard.setData(ClipboardData(text: content));
        setState(() {
          _exportResult = 'Contenu $formatName copié dans le presse-papiers';
          _exportSuccess = true;
        });
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$filename');
        await file.writeAsString(content);

        developer.log(
          'Audit logs exported to: ${file.path}',
          name: 'AuditExport',
        );

        setState(() {
          _exportResult = 'Fichier exporté: $filename\n'
              'Emplacement: ${directory.path}';
          _exportSuccess = true;
        });
      }
    } catch (e) {
      developer.log(
        'Error exporting audit logs: $e',
        name: 'AuditExport',
        level: 1000,
      );
      setState(() {
        _exportResult = 'Erreur: ${e.toString()}';
        _exportSuccess = false;
      });
    } finally {
      setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.download),
          SizedBox(width: 12),
          Text('Exporter les logs'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.logs.length} entrée(s) à exporter',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Format d\'export:',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AuditExportOptionCard(
                    icon: Icons.table_chart,
                    title: 'CSV',
                    subtitle: 'Tableur',
                    onTap: _isExporting ? null : _exportToCsv,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AuditExportOptionCard(
                    icon: Icons.data_object,
                    title: 'JSON',
                    subtitle: 'Données brutes',
                    onTap: _isExporting ? null : _exportToJson,
                  ),
                ),
              ],
            ),
            if (_isExporting) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
            ],
            if (_exportResult != null) _buildResultMessage(theme),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }

  Widget _buildResultMessage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _exportSuccess
              ? Colors.green.withValues(alpha: 0.1)
              : Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _exportSuccess
                ? Colors.green.withValues(alpha: 0.3)
                : Colors.red.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _exportSuccess ? Icons.check_circle : Icons.error,
              color: _exportSuccess ? Colors.green : Colors.red,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _exportResult!,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
