import 'package:flutter/material.dart';

/// Dialog générique pour les formulaires avec style cohérent.
/// 
/// Ce composant unifie les différentes implémentations de FormDialog
/// pour offrir une expérience utilisateur cohérente à travers tous les modules.
class FormDialog extends StatefulWidget {
  const FormDialog({
    super.key,
    required this.title,
    required this.child,
    this.onSave,
    this.saveLabel = 'Enregistrer',
    this.cancelLabel = 'Annuler',
    this.isLoading,
    this.maxWidth = 600,
  });

  final String title;
  final Widget child;
  final Future<void> Function()? onSave;
  final String saveLabel;
  final String cancelLabel;
  final bool? isLoading;
  final double maxWidth;

  @override
  State<FormDialog> createState() => _FormDialogState();
}

class _FormDialogState extends State<FormDialog> {
  bool _internalLoading = false;

  bool get _isLoading => widget.isLoading ?? _internalLoading;

  Future<void> _handleSave() async {
    if (widget.onSave == null || _isLoading) return;
    if (widget.isLoading == null) {
      setState(() => _internalLoading = true);
    }
    try {
      await widget.onSave!();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted && widget.isLoading == null) {
        setState(() => _internalLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;
    final availableHeight = screenHeight - keyboardHeight - 100;
    final maxWidth = (screenWidth * 0.9).clamp(320.0, widget.maxWidth);

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth < 600 ? 16 : 24,
        vertical: keyboardHeight > 0 ? 16 : 24,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: availableHeight.clamp(300.0, screenHeight * 0.9),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header fixe
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Contenu scrollable
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  bottom: keyboardHeight > 0 ? 8 : 0,
                ),
                child: widget.child,
              ),
            ),
            // Footer fixe avec padding adaptatif pour le clavier
            Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: keyboardHeight > 0 ? 16 : 24,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text(widget.cancelLabel),
                  ),
                  const SizedBox(width: 12),
                  IntrinsicWidth(
                    child: FilledButton(
                      onPressed:
                          (_isLoading || widget.onSave == null) ? null : _handleSave,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.saveLabel),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

