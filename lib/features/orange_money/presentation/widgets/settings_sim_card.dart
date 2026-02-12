import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/shared.dart';

/// Card widget for SIM configuration settings.
class SettingsSimCard extends StatefulWidget {
  const SettingsSimCard({
    super.key,
    required this.simNumber,
    required this.onSimNumberChanged,
  });

  final String simNumber;
  final ValueChanged<String> onSimNumberChanged;

  @override
  State<SettingsSimCard> createState() => _SettingsSimCardState();
}

class _SettingsSimCardState extends State<SettingsSimCard> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.simNumber);
    _controller.addListener(() {
      widget.onSimNumberChanged(_controller.text);
    });
  }

  @override
  void didUpdateWidget(SettingsSimCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.simNumber != widget.simNumber) {
      _controller.text = widget.simNumber;
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
    
    return ElyfCard(
      padding: const EdgeInsets.all(24),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.sim_card_rounded, size: 22, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Text(
                'Configuration SIM',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Outfit',
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Identifiant SIM Orange Money',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Ex: sim_123456789',
              prefixIcon: Icon(Icons.phone_android_rounded, size: 20, color: theme.colorScheme.primary),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'Outfit',
            ),
            onChanged: widget.onSimNumberChanged,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ce numéro sera utilisé pour router toutes les transactions Mobile Money.',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSimConfiguredBox(theme, _controller.text),
        ],
      ),
    );
  }

  Widget _buildSimConfiguredBox(ThemeData theme, String simText) {
    final displaySim = simText.isEmpty ? 'SIM non configurée' : simText;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF00C897).withValues(alpha: 0.05),
        border: Border.all(color: const Color(0xFF00C897).withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00C897).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 20,
              color: Color(0xFF00C897),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statut du routage',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF008967),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF008967).withValues(alpha: 0.8),
                      height: 1.4,
                      fontFamily: 'Outfit',
                    ),
                    children: [
                      const TextSpan(text: 'La SIM '),
                      TextSpan(
                        text: displaySim,
                        style: const TextStyle(fontWeight: FontWeight.w900, decoration: TextDecoration.underline),
                      ),
                      const TextSpan(
                        text:
                            ' est bien configurée comme canal de communication par défaut.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
