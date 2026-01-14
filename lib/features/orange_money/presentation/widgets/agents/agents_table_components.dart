import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/agent.dart';

/// Composants réutilisables pour le tableau des agents.
class AgentsTableComponents {
  /// Construit la cellule du nom de l'agent.
  static Widget buildAgentNameCell(Agent agent) {
    final isLowLiquidity = agent.isLowLiquidity(50000);
    final dateFormat = DateFormat('d/M/yyyy');
    final dateStr = agent.createdAt != null
        ? dateFormat.format(agent.createdAt!)
        : 'N/A';

    return SizedBox(
      width: 171.673,
      child: Padding(
        padding: const EdgeInsets.only(left: 8, top: 8.61, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    agent.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Color(0xFF0A0A0A),
                      height: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (isLowLiquidity)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 12,
                      color: Color(0xFFFDC700),
                    ),
                  ),
              ],
            ),
            Text(
              'Depuis le $dateStr',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Color(0xFF6A7282),
                height: 1.2,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  /// Construit le badge de l'opérateur.
  static Widget buildOperatorBadge(MobileOperator operator) {
    return Container(
      height: 22.438,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.1),
          width: 1.219,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          operator.label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            color: Color(0xFF0A0A0A),
          ),
        ),
      ),
    );
  }

  /// Construit le chip de statut.
  static Widget buildStatusChip(AgentStatus status) {
    final isActive = status == AgentStatus.active;
    return Container(
      height: 22.438,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF030213) : Colors.transparent,
        border: isActive
            ? Border.all(color: Colors.transparent, width: 1.219)
            : Border.all(
                color: Colors.black.withValues(alpha: 0.1),
                width: 1.219,
              ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          status.label,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF6A7282),
            fontSize: 12,
            fontWeight: FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// Construit la cellule d'actions.
  static Widget buildActionsCell({
    required VoidCallback onView,
    required VoidCallback onRefresh,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.only(
          left: 8,
          top: 10.61,
          right: 8,
          bottom: 10.61,
        ),
        child: Row(
          children: [
            _buildActionButton(icon: Icons.visibility, onPressed: onView),
            const SizedBox(width: 4),
            _buildActionButton(icon: Icons.refresh, onPressed: onRefresh),
            const SizedBox(width: 4),
            _buildActionButton(icon: Icons.edit, onPressed: onEdit),
            const SizedBox(width: 4),
            _buildActionButton(
              icon: Icons.close,
              color: Colors.red,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Container(
      width: 38.437,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.1),
          width: 1.219,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: Icon(
              icon,
              size: 16,
              color: color ?? const Color(0xFF0A0A0A),
            ),
          ),
        ),
      ),
    );
  }
}
