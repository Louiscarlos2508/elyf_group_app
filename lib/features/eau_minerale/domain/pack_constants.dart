/// Constantes partagées pour le produit Pack (produits finis).
///
/// Le Pack existe à deux endroits :
/// - [packStockItemId] / Inventaire (stock_items) : quantité, mouvements.
/// - [packProductId] / Catalogue (products) : prix unitaire, ventes.
///
/// **Même Pack partout** : Stock, Dashboard, Paramètres, et le dialog
/// « Nouvelle vente » utilisent ces constantes. Le sélecteur de produit
/// (ventes) et [SalesController.createSale] référencent explicitement
/// [packProductId] / [packName].
const String packName = 'Pack';
const String packUnit = 'Unité';

/// ID du StockItem Pack (inventaire, écran stock, mouvements).
const String packStockItemId = 'pack-1';

/// ID du Product Pack (catalogue, paramètres, ventes).
const String packProductId = 'pack-1';

/// Matières premières par défaut
const String bobineName = 'Bobine';
const String bobineProductId = 'raw_bobine-1';

const String emballageName = 'Emballage';
const String emballageProductId = 'raw_emballage-1';
const int emballageDefaultUnitsPerLot = 1000;
