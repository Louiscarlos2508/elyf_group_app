import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';

import '../../../../../../core/offline/drift_service.dart';
import '../../application/providers.dart';
import 'point_of_sale_table/pos_table_header.dart';
import 'point_of_sale_table/pos_table_row.dart';

/// Tableau des points de vente selon le design Figma.
class PointOfSaleTable extends ConsumerWidget {
  const PointOfSaleTable({
    super.key,
    required this.enterpriseId,
    required this.moduleId,
  });

  final String enterpriseId;
  final String moduleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // Debug: Log les paramètres utilisés
    AppLogger.debug(
      'PointOfSaleTable.build: enterpriseId=$enterpriseId, moduleId=$moduleId',
      name: 'gaz.point_of_sale',
    );
    
    final pointsOfSaleAsync = ref.watch(
      pointsOfSaleProvider((enterpriseId: enterpriseId, moduleId: moduleId)),
    );

    // Debug: Log l'état du provider
    pointsOfSaleAsync.when(
      data: (data) => AppLogger.debug(
        'PointOfSaleTable: ${data.length} points de vente trouvés',
        name: 'gaz.point_of_sale',
      ),
      loading: () => AppLogger.debug(
        'PointOfSaleTable: Chargement...',
        name: 'gaz.point_of_sale',
      ),
      error: (error, stack) => AppLogger.error(
        'PointOfSaleTable: Erreur - $error',
        name: 'gaz.point_of_sale',
        error: error,
        stackTrace: stack,
      ),
    );

    return pointsOfSaleAsync.when(
      data: (pointsOfSale) {
        // Debug: Afficher les informations de débogage
        AppLogger.debug(
          'PointOfSaleTable data: ${pointsOfSale.length} points de vente',
          name: 'gaz.point_of_sale',
        );
        for (final pos in pointsOfSale) {
          AppLogger.debug(
            'PointOfSaleTable: ${pos.name} (id: ${pos.id}, parentEnterpriseId: ${pos.parentEnterpriseId}, moduleId: ${pos.moduleId})',
            name: 'gaz.point_of_sale',
          );
        }
        
        if (pointsOfSale.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(25.285),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.1),
                width: 1.305,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.store_outlined,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun point de vente',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Créez votre premier point de vente',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Debug info
                  Column(
                    children: [
                      Text(
                        'Debug: enterpriseId=$enterpriseId, moduleId=$moduleId',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Bouton pour forcer la resynchronisation
                      OutlinedButton.icon(
                        onPressed: () async {
                          AppLogger.debug(
                            'FORCE SYNC: Démarrage de la resynchronisation...',
                            name: 'gaz.point_of_sale',
                          );
                          
                          // Vérifier directement dans Firestore
                          try {
                            final firestore = FirebaseFirestore.instance;
                            final path = 'enterprises/$enterpriseId/pointsOfSale';
                            AppLogger.debug(
                              'FIRESTORE CHECK: Vérification de $path',
                              name: 'gaz.point_of_sale',
                            );
                            
                            final snapshot = await firestore.collection(path).get();
                            AppLogger.debug(
                              'FIRESTORE CHECK: ${snapshot.docs.length} points de vente trouvés dans Firestore pour $enterpriseId',
                              name: 'gaz.point_of_sale',
                            );
                            
                            for (final doc in snapshot.docs) {
                              final data = doc.data();
                              final parentEnterpriseId = data['parentEnterpriseId'] as String?;
                              final enterpriseIdInData = data['enterpriseId'] as String?;
                              AppLogger.debug(
                                'FIRESTORE CHECK: Point de vente - id: ${doc.id}, name: ${data['name']}, parentEnterpriseId: $parentEnterpriseId, enterpriseId (dans data): $enterpriseIdInData',
                                name: 'gaz.point_of_sale',
                              );
                              if (parentEnterpriseId == enterpriseIdInData) {
                                AppLogger.warning(
                                  'FIRESTORE CHECK WARNING: parentEnterpriseId == enterpriseId dans les données (problème de structure)',
                                  name: 'gaz.point_of_sale',
                                );
                              }
                            }
                            
                            // Vérifier aussi dans toutes les entreprises pour voir s'il y a des points de vente ailleurs
                            AppLogger.debug(
                              'FIRESTORE CHECK: Recherche dans toutes les entreprises...',
                              name: 'gaz.point_of_sale',
                            );
                            final allEnterprisesSnapshot = await firestore.collection('enterprises').get();
                            int totalPos = 0;
                            for (final enterpriseDoc in allEnterprisesSnapshot.docs) {
                              try {
                                final posSnapshot = await firestore
                                    .collection('enterprises/${enterpriseDoc.id}/pointsOfSale')
                                    .get();
                                if (posSnapshot.docs.isNotEmpty) {
                                  totalPos += posSnapshot.docs.length;
                                  AppLogger.debug(
                                    'FIRESTORE CHECK: ${posSnapshot.docs.length} points de vente trouvés dans enterprises/${enterpriseDoc.id}/pointsOfSale',
                                    name: 'gaz.point_of_sale',
                                  );
                                  for (final posDoc in posSnapshot.docs.take(3)) {
                                    final posData = posDoc.data();
                                    AppLogger.debug(
                                      'FIRESTORE CHECK: ${posData['name']} (id: ${posDoc.id}), parentEnterpriseId: ${posData['parentEnterpriseId']}, enterpriseId: ${posData['enterpriseId']}',
                                      name: 'gaz.point_of_sale',
                                    );
                                  }
                                }
                              } catch (e) {
                                // Ignorer les erreurs pour les entreprises sans pointsOfSale
                              }
                            }
                            AppLogger.debug(
                              'FIRESTORE CHECK: Total de points de vente dans toutes les entreprises: $totalPos',
                              name: 'gaz.point_of_sale',
                            );
                          } catch (e, stackTrace) {
                            AppLogger.error(
                              'FIRESTORE CHECK ERROR: $e',
                              name: 'gaz.point_of_sale',
                              error: e,
                              stackTrace: stackTrace,
                            );
                          }
                          
                          // Vérifier dans Drift
                          try {
                            final driftService = DriftService.instance;
                            final allRows = await driftService.records.listForCollection(
                              collectionName: 'pointOfSale',
                              moduleType: 'gaz',
                            );
                            AppLogger.debug(
                              'DRIFT CHECK: ${allRows.length} points de vente dans Drift (toutes entreprises)',
                              name: 'gaz.point_of_sale',
                            );
                            
                            for (final row in allRows.take(5)) {
                              AppLogger.debug(
                                'DRIFT CHECK: enterpriseId dans Drift: ${row.enterpriseId}, localId: ${row.localId}',
                                name: 'gaz.point_of_sale',
                              );
                            }
                          } catch (e, stackTrace) {
                            AppLogger.error(
                              'DRIFT CHECK ERROR: $e',
                              name: 'gaz.point_of_sale',
                              error: e,
                              stackTrace: stackTrace,
                            );
                          }
                          
                          // Invalider le provider pour forcer le rechargement
                          ref.invalidate(
                            pointsOfSaleProvider((enterpriseId: enterpriseId, moduleId: moduleId)),
                          );
                        },
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Rafraîchir'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(25.285, 25.285, 1.305, 1.305),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.1),
              width: 1.305,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête de la carte
              Row(
                children: [
                  const Icon(Icons.store, size: 20, color: Color(0xFF0A0A0A)),
                  const SizedBox(width: 8),
                  Text(
                    'Points de vente',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                      color: const Color(0xFF0A0A0A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 42),
              // Tableau
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.1),
                    width: 1.305,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    // En-tête du tableau
                    const PosTableHeader(),
                    // Corps du tableau
                    ...pointsOfSale.map(
                      (pos) => PosTableRow(
                        pointOfSale: pos,
                        enterpriseId: enterpriseId,
                        moduleId: moduleId,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(25.285),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.1),
            width: 1.305,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) {
        // Log l'erreur pour déboguer
        AppLogger.error(
          'Erreur lors du chargement des points de vente: $error',
          name: 'gaz.point_of_sale',
          error: error,
          stackTrace: stack,
        );
        AppLogger.debug(
          'EnterpriseId: $enterpriseId, ModuleId: $moduleId',
          name: 'gaz.point_of_sale',
        );
        
        return Container(
          padding: const EdgeInsets.all(25.285),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.1),
              width: 1.305,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur de chargement',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
