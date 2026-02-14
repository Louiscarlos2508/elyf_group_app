
import 'package:flutter/material.dart';

import '../../../core/errors/error_handler.dart';
import '../../../core/logging/app_logger.dart';

/// Dialog générique pour les formulaires avec styling cohérent.
///
/// Ce widget fournit une structure standardisée pour tous les dialogs
/// de formulaire dans l'application, avec gestion responsive et du clavier.
import 'package:elyf_groupe_app/shared/presentation/widgets/elyf_ui/organisms/elyf_card.dart';

class FormDialog extends StatefulWidget {
  const FormDialog({
    super.key,
    required this.title,
    required this.child,
    this.onSave,
    this.saveLabel = 'Enregistrer',
    this.cancelLabel = 'Annuler',
    this.isLoading = false,
    this.subtitle,
    this.icon,
    this.isGlass = false,
    this.maxWidth = 600,
    this.customAction,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget child;
  final Future<dynamic> Function()? onSave;
  final String saveLabel;
  final String cancelLabel;
  final bool isLoading;
  final bool isGlass;
  final double maxWidth;
  final Widget? customAction;

  @override
  State<FormDialog> createState() => _FormDialogState();
}

class _FormDialogState extends State<FormDialog> {
  bool _isLoading = false;

  Future<void> _handleSave() async {
    if (widget.onSave == null) return;
    setState(() => _isLoading = true);
    try {
      final result = await widget.onSave!();
      if (result is bool) {
        if (result && mounted && ModalRoute.of(context)?.isCurrent == true) {
          Navigator.of(context).pop();
        }
      } else {
        if (mounted && ModalRoute.of(context)?.isCurrent == true) {
          Navigator.of(context).pop();
        }
      }
    } catch (e, stackTrace) {
      ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error('Error in FormDialog._handleSave', error: e, stackTrace: stackTrace);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _effectiveLoading => widget.isLoading || _isLoading;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;

    final availableHeight = screenHeight - keyboardHeight - 48;
    final dialogWidth = (screenWidth * 0.95).clamp(320.0, widget.maxWidth);

    Widget dialogBody = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Premium Header
        Container(
          padding: const EdgeInsets.fromLTRB(28, 28, 20, 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.icon, size: 24, color: colors.primary),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.close, size: 20),
                onPressed: _effectiveLoading ? null : () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        
        // Scrollable Content
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: widget.child,
          ),
        ),
        
        // Premium Footer
        Padding(
          padding: const EdgeInsets.all(28),
          child: Row(
            children: [
              if (widget.customAction != null) ...[
                widget.customAction!,
                const SizedBox(width: 16),
              ],
              Expanded(
                child: OutlinedButton(
                  onPressed: _effectiveLoading ? null : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(widget.cancelLabel),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _effectiveLoading ? null : _handleSave,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _effectiveLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(widget.saveLabel),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth < 600 ? 12 : 24,
        vertical: 24,
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: availableHeight.clamp(200.0, screenHeight * 0.85),
        ),
        child: widget.isGlass
            ? ElyfCard(
                isGlass: true,
                padding: EdgeInsets.zero,
                borderRadius: 32,
                child: dialogBody,
              )
            : Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: dialogBody,
              ),
      ),
    );
  }
}
