import 'package:flutter/material.dart';

import '../../../domain/entities/collection.dart';

/// Représente un client (grossiste ou point de vente).
/// TODO: Remplacer par une entité complète dans le domaine.
class Client {
  const Client({
    required this.id,
    required this.name,
    required this.phone,
    this.address,
    this.emptyStock = const {},
    this.fullStock = const {},
    this.leakStock = const {},
  });

  final String id;
  final String name;
  final String phone;
  final String? address;
  final Map<int, int> emptyStock; // poids -> quantité vide disponible
  final Map<int, int> fullStock;  // poids -> quantité pleine disponible
  final Map<int, int> leakStock;  // poids -> quantité fuite disponible

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Client && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Sélecteur de client avec affichage du stock pour les points de vente.
class ClientSelector extends StatelessWidget {
  const ClientSelector({
    super.key,
    required this.selectedClient,
    required this.clients,
    required this.collectionType,
    required this.onClientSelected,
  });

  final Client? selectedClient;
  final List<Client> clients;
  final CollectionType collectionType;
  final ValueChanged<Client> onClientSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _ClientDropdown(
          selectedClient: selectedClient,
          clients: clients,
          collectionType: collectionType,
          onClientSelected: onClientSelected,
        ),
        // Stock info pour point de vente
        if (collectionType == CollectionType.pointOfSale &&
            selectedClient != null)
          _StockInfoBox(client: selectedClient!),
      ],
    );
  }
}

class _ClientDropdown extends StatelessWidget {
  const _ClientDropdown({
    required this.selectedClient,
    required this.clients,
    required this.collectionType,
    required this.onClientSelected,
  });

  final Client? selectedClient;
  final List<Client> clients;
  final CollectionType collectionType;
  final ValueChanged<Client> onClientSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWholesaler = collectionType == CollectionType.wholesaler;

    return DropdownButtonFormField<Client>(
      key: ValueKey(selectedClient?.id),
      initialValue: selectedClient,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: isWholesaler ? 'Grossiste' : 'Point de Vente',
        prefixIcon: Icon(
          isWholesaler ? Icons.person_outline : Icons.storefront_outlined,
          color: theme.colorScheme.primary,
        ),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: clients.map((client) {
        return DropdownMenuItem<Client>(
          value: client,
          child: Text(
            client.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (client) {
        if (client != null) onClientSelected(client);
      },
    );
  }
}

class _StockInfoBox extends StatelessWidget {
  const _StockInfoBox({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final blueBg = isDark ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2) : const Color(0xFFEFF6FF);
    final blueBorder = isDark ? theme.colorScheme.primary.withValues(alpha: 0.3) : const Color(0xFFBEDBFF);
    final totalEmpty = client.emptyStock.values.fold<int>(0, (sum, qty) => sum + qty);
    final totalFull = client.fullStock.values.fold<int>(0, (sum, qty) => sum + qty);
    final totalLeaks = client.leakStock.values.fold<int>(0, (sum, qty) => sum + qty);

    final blueText = isDark ? theme.colorScheme.primary : const Color(0xFF1C398E);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: blueBg,
        border: Border.all(color: blueBorder, width: 1.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📍 Disponibilités au Point de Vente',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: blueText),
          ),
          const SizedBox(height: 12),
          _StockRow(label: 'Vides', stock: client.emptyStock, color: theme.colorScheme.onSurface),
          const SizedBox(height: 8),
          _StockRow(label: 'Pleines', stock: client.fullStock, color: isDark ? Colors.blue[300]! : Colors.blue[800]!),
          const SizedBox(height: 8),
          _StockRow(label: 'Fuites', stock: client.leakStock, color: theme.colorScheme.error),
          if (totalEmpty == 0 && totalFull == 0 && totalLeaks == 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Aucune bouteille disponible au POS',
                style: TextStyle(fontSize: 12, color: theme.colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }
}

class _StockRow extends StatelessWidget {
  const _StockRow({required this.label, required this.stock, required this.color});
  final String label;
  final Map<int, int> stock;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final total = stock.values.fold<int>(0, (sum, qty) => sum + qty);
    if (total == 0) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label :',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        Text(
          stock.entries.map((e) => '${e.value} × ${e.key}kg').join(', '),
          style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
