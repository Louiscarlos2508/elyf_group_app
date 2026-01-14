import 'package:flutter/material.dart';

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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: Colors.black.withValues(alpha: 0.1),
          width: 1.219,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sim_card, size: 20, color: Color(0xFF0A0A0A)),
                const SizedBox(width: 8),
                const Text(
                  'Configuration SIM',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF0A0A0A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Numéro SIM pour toutes les transactions',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0A0A0A),
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.transparent, width: 1.219),
                  ),
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0A0A0A),
                    ),
                    decoration: InputDecoration(
                      hintText: 'sim_123456789',
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF717182),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: true,
                  onChanged: null,
                  activeColor: const Color(0xFF030213),
                ),
                const Expanded(
                  child: Text(
                    '📱 Ce numéro sera automatiquement utilisé pour toutes les transactions Mobile Money',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF4A5565),
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSimConfiguredBox(_controller.text),
          ],
        ),
      ),
    );
  }

  Widget _buildSimConfiguredBox(String simText) {
    final displaySim = simText.isEmpty ? 'sim_123456789' : simText;

    return Container(
      padding: const EdgeInsets.fromLTRB(17, 17, 1, 1),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        border: Border.all(color: const Color(0xFFB9F8CF), width: 1.219),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.check_circle,
              size: 20,
              color: Color(0xFF0D542B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '✅ SIM configurée',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF0D542B),
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF016630),
                      fontWeight: FontWeight.normal,
                    ),
                    children: [
                      const TextSpan(text: 'SIM '),
                      TextSpan(
                        text: displaySim,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(
                        text:
                            ' sera utilisée automatiquement. Plus besoin de la sélectionner à chaque transaction !',
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
