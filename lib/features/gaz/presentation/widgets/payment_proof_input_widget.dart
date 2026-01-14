import 'package:flutter/material.dart';

/// Widget de saisie d'URL pour la capture SMS (pas d'upload pour l'instant).
class PaymentProofInputWidget extends StatefulWidget {
  const PaymentProofInputWidget({
    super.key,
    this.initialUrl,
    this.onUrlChanged,
  });

  final String? initialUrl;
  final ValueChanged<String>? onUrlChanged;

  @override
  State<PaymentProofInputWidget> createState() =>
      _PaymentProofInputWidgetState();
}

class _PaymentProofInputWidgetState extends State<PaymentProofInputWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialUrl ?? '');
  }

  @override
  void didUpdateWidget(PaymentProofInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialUrl != oldWidget.initialUrl) {
      _controller.text = widget.initialUrl ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preuve de Paiement (URL capture SMS)',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          onChanged: widget.onUrlChanged,
          decoration: InputDecoration(
            labelText: 'URL de l\'image',
            hintText: 'https://example.com/image.png',
            border: const OutlineInputBorder(),
            helperText:
                'L\'upload d\'image sera disponible dans une future version',
            prefixIcon: const Icon(Icons.image_outlined),
          ),
          keyboardType: TextInputType.url,
        ),
        if (widget.initialUrl != null && widget.initialUrl!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.initialUrl!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Impossible de charger l\'image',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}
