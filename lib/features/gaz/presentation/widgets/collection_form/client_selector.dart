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
  });

  final String id;
  final String name;
  final String phone;
  final String? address;
  final Map<int, int> emptyStock; // poids -> quantité disponible
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
        Text(
          collectionType == CollectionType.wholesaler
              ? 'Grossiste'
              : 'Point de vente',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            color: const Color(0xFF0A0A0A),
          ),
        ),
        const SizedBox(height: 8),
        _ClientDropdownButton(
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

class _ClientDropdownButton extends StatelessWidget {
  const _ClientDropdownButton({
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
    final lightGray = const Color(0xFFF3F3F5);
    final textGray = const Color(0xFF717182);

    return PopupMenuButton<Client>(
      onSelected: onClientSelected,
      child: Container(
        constraints: const BoxConstraints(minHeight: 36),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 4),
        decoration: BoxDecoration(
          color: lightGray,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: selectedClient == null
                  ? Center(
                      child: Text(
                        collectionType == CollectionType.wholesaler
                            ? 'Sélectionner un grossiste'
                            : 'Sélectionner un point de vente',
                        style: TextStyle(fontSize: 14, color: textGray),
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedClient!.name,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF0A0A0A),
                          ),
                        ),
                        if (selectedClient!.address != null)
                          Text(
                            '- ${selectedClient!.address}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6A7282),
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: Color(0xFF717182),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => clients
          .map(
            (client) => PopupMenuItem(
              value: client,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(client.name),
                  if (client.address != null)
                    Text(
                      client.address!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6A7282),
                      ),
                    ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _StockInfoBox extends StatelessWidget {
  const _StockInfoBox({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context) {
    final blueBg = const Color(0xFFEFF6FF);
    final blueBorder = const Color(0xFFBEDBFF);
    final blueText = const Color(0xFF1C398E);
    final totalStock = client.emptyStock.values.fold<int>(
      0,
      (sum, qty) => sum + qty,
    );

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 1),
      decoration: BoxDecoration(
        color: blueBg,
        border: Border.all(color: blueBorder, width: 1.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📍 Stock de bouteilles vides disponibles',
            style: TextStyle(fontSize: 14, color: blueText),
          ),
          const SizedBox(height: 8),
          Text(
            totalStock == 0
                ? 'Aucune bouteille vide dans ce point de vente'
                : '${client.emptyStock.entries.map((e) => '${e.value} × ${e.key}kg').join(', ')} disponibles',
            style: TextStyle(
              fontSize: 14,
              color: totalStock == 0 ? const Color(0xFF1447E6) : blueText,
            ),
          ),
        ],
      ),
    );
  }
}
