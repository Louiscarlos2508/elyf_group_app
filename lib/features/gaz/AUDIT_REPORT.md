# 🔍 Audit du Module Gaz

**Date:** $(date)  
**Objectif:** Vérifier la séparation UI/Logique, la réutilisation des widgets et le respect de la limite de 200 lignes par fichier.

---

## 📊 Résumé Exécutif

### Problèmes Critiques Identifiés

1. **❌ Fichiers dépassant 200 lignes:** 8+ fichiers
2. **❌ Logique métier dans les écrans:** Formatage, calculs dans les widgets
3. **❌ Duplication de code:** Fonction `_formatCurrency` dupliquée 20+ fois
4. **❌ Styles de boutons dupliqués:** 32 occurrences de styles répétés

---

## 1️⃣ Fichiers Dépassant 200 Lignes

### 🔴 Critique (> 500 lignes)

| Fichier | Lignes | Problème | Action Requise |
|---------|-------|----------|----------------|
| `tour_detail_screen.dart` | **1719** | Écran monolithique | Découper en widgets enfants |
| `collection_form_dialog.dart` | **916** | Dialog trop complexe | Extraire sous-widgets |
| `payment_form_dialog.dart` | **613** | Dialog trop complexe | Extraire sous-widgets |
| `expenses_screen.dart` | **562** | Écran avec logique | Extraire logique et widgets |
| `gas_sale_form_dialog.dart` | **542** | Dialog trop complexe | Extraire sous-widgets |

### 🟡 Important (200-500 lignes)

| Fichier | Lignes | Action Requise |
|---------|-------|----------------|
| `approvisionnement_screen.dart` | 483 | Découper en widgets |
| `retail_screen.dart` | 463 | Extraire logique métier |
| `dashboard_screen.dart` | 430 | Extraire calculs |
| `point_of_sale_stock_card.dart` | 400 | Découper en sous-widgets |
| `tour_form_dialog.dart` | 401 | Extraire sous-widgets |
| `point_of_sale_table.dart` | 387 | Découper en widgets |
| `stock_screen.dart` | 384 | Extraire logique |
| `cylinder_leak_screen.dart` | 363 | Découper en widgets |
| `wholesale_price_config_card.dart` | 354 | Découper en sous-widgets |
| `profit_report_content_v2.dart` | 328 | Découper en widgets |
| `expense_form_dialog.dart` | 316 | Extraire sous-widgets |
| `bottle_price_table.dart` | 310 | Découper en widgets |
| `cylinder_form_dialog.dart` | 299 | Extraire sous-widgets |

---

## 2️⃣ Séparation UI/Logique

### ❌ Logique Métier dans les Écrans

#### Problème: Calculs dans les Widgets

**Fichiers concernés:**
- `dashboard_screen.dart` (lignes 159-308): Calculs de ventes, dépenses, profits
- `retail_screen.dart` (lignes 219-232): Calculs de totaux
- `expenses_screen.dart` (lignes 54-68): Calculs de dépenses du jour
- `tour_detail_screen.dart` (lignes 483-491): Calculs de totaux de bouteilles

**Solution:** Créer un service `gaz_calculation_service.dart` dans `domain/services/`

#### Problème: Formatage dans les Widgets

**Fonction `_formatCurrency` dupliquée dans 20+ fichiers:**
- `dashboard_screen.dart`
- `retail_screen.dart`
- `expenses_screen.dart`
- `cylinder_sale_card.dart`
- `financial_report_content_v2.dart`
- `dashboard_point_of_sale_performance.dart`
- `collection_item_widget.dart`
- `tour_summary_card.dart`
- `gas_sale_form_dialog.dart`
- `expense_card.dart`
- `expenses_report_content_v2.dart`
- `monthly_expense_summary.dart`
- `stock_summary_card.dart`
- `cylinder_list_item.dart`
- `dashboard_kpi_grid.dart`
- `financial_summary_card.dart`
- `sales_report_content_v2.dart`
- `report_kpi_cards_v2.dart`
- `profit_report_content_v2.dart`
- `dashboard_month_section.dart`
- `dashboard_today_section.dart`

**Solution:** Créer `lib/shared/utils/currency_formatter.dart`

**Fonction `_formatDate` dupliquée:**
- `wholesale_date_filter_card.dart`
- `dashboard_header.dart`

**Solution:** Créer `lib/shared/utils/date_formatter.dart`

---

## 3️⃣ Duplication de Widgets

### Styles de Boutons Dupliqués

**32 occurrences** de styles de boutons répétés dans:
- `tour_detail_screen.dart` (7 occurrences)
- `collection_form_dialog.dart` (3 occurrences)
- `payment_form_dialog.dart` (2 occurrences)
- Et 12 autres fichiers...

**Styles répétés:**
```dart
// Style FilledButton noir
FilledButton.styleFrom(
  backgroundColor: const Color(0xFF030213),
  foregroundColor: Colors.white,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  minimumSize: const Size(0, 36),
)

// Style OutlinedButton
OutlinedButton.styleFrom(
  side: BorderSide(color: Colors.black.withValues(alpha: 0.1), width: 1.305),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  padding: const EdgeInsets.symmetric(horizontal: 17.305, vertical: 9.305),
  minimumSize: const Size(0, 36),
)
```

**Solution:** Créer `lib/shared/presentation/widgets/gaz_button_styles.dart`

### KPI Cards Dupliquées

Plusieurs types de KPI cards avec logique similaire:
- `DashboardOverviewKpiCard`
- `RetailKpiCard`
- `ExpenseKpiCard`
- `StockKpiCard`
- `WholesaleKpiCard`
- `DashboardKpiCard`
- `EnhancedKpiCard`

**Solution:** Créer un widget générique `GazKpiCard` avec paramètres configurables

---

## 4️⃣ Structure Recommandée

### Nouveaux Fichiers à Créer

```
lib/
├── shared/
│   ├── utils/
│   │   ├── currency_formatter.dart      # Formatage monétaire unifié
│   │   └── date_formatter.dart          # Formatage dates unifié
│   └── presentation/
│       └── widgets/
│           └── gaz_button_styles.dart  # Styles de boutons réutilisables
│
└── features/
    └── gaz/
        ├── domain/
        │   └── services/
        │       └── gaz_calculation_service.dart  # Calculs métier
        │
        └── presentation/
            └── widgets/
                ├── gaz_kpi_card.dart              # KPI card générique
                ├── tour_detail/
                │   ├── tour_detail_header.dart
                │   ├── tour_workflow_stepper.dart
                │   ├── collection_step_content.dart
                │   ├── transport_step_content.dart
                │   ├── return_step_content.dart
                │   └── closure_step_content.dart
                ├── collection_form/
                │   ├── collection_type_selector.dart
                │   ├── client_selector.dart
                │   └── bottle_quantity_input.dart
                └── payment_form/
                    ├── payment_amount_input.dart
                    └── payment_proof_input.dart
```

---

## 5️⃣ Plan d'Action Prioritaire

### Phase 1: Extraction de la Logique (Priorité Haute)

1. ✅ Créer `currency_formatter.dart` et remplacer toutes les occurrences
2. ✅ Créer `date_formatter.dart` et remplacer toutes les occurrences
3. ✅ Créer `gaz_calculation_service.dart` et extraire les calculs

### Phase 2: Découpage des Fichiers Critiques (Priorité Haute)

1. ✅ Découper `tour_detail_screen.dart` (1719 lignes) en 6+ widgets
2. ✅ Découper `collection_form_dialog.dart` (916 lignes) en sous-widgets
3. ✅ Découper `payment_form_dialog.dart` (613 lignes) en sous-widgets

### Phase 3: Réutilisation des Widgets (Priorité Moyenne)

1. ✅ Créer `gaz_button_styles.dart` et remplacer les styles dupliqués
2. ✅ Créer `GazKpiCard` générique et remplacer les KPI cards dupliquées

### Phase 4: Découpage des Autres Fichiers (Priorité Moyenne)

1. ✅ Découper les fichiers 200-500 lignes restants

---

## 6️⃣ Métriques

### Avant Refactoring
- **Fichiers > 200 lignes:** 20+
- **Duplications `_formatCurrency`:** 20+
- **Duplications styles boutons:** 32+
- **Fichiers avec logique métier:** 8+

### Objectifs Après Refactoring
- **Fichiers > 200 lignes:** 0
- **Duplications `_formatCurrency`:** 0 (utiliser utilitaire)
- **Duplications styles boutons:** 0 (utiliser styles partagés)
- **Fichiers avec logique métier:** 0 (logique dans services)

---

## 7️⃣ Exemples de Refactoring

### Exemple 1: Extraction de `_formatCurrency`

**Avant:**
```dart
// Dans chaque fichier
String _formatCurrency(double amount) {
  if (amount == 0) return '0 FCFA';
  return amount.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]} ',
  ) + ' FCFA';
}
```

**Après:**
```dart
// lib/shared/utils/currency_formatter.dart
class CurrencyFormatter {
  static String format(double amount) {
    if (amount == 0) return '0 FCFA';
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    ) + ' FCFA';
  }
}

// Utilisation
Text(CurrencyFormatter.format(amount))
```

### Exemple 2: Découpage de `tour_detail_screen.dart`

**Structure actuelle:**
- 1 fichier de 1719 lignes avec tout le code

**Structure recommandée:**
```
tour_detail_screen.dart (100 lignes max)
├── tour_detail_header.dart (widget)
├── tour_workflow_stepper.dart (widget)
├── collection_step_content.dart (widget)
├── transport_step_content.dart (widget)
├── return_step_content.dart (widget)
└── closure_step_content.dart (widget)
```

---

## ✅ Conclusion

Le module gaz nécessite un refactoring important pour respecter les règles du projet:
- **Séparation UI/Logique:** ❌ Non respectée
- **Réutilisation des widgets:** ❌ Non respectée
- **Limite de 200 lignes:** ❌ Non respectée (8+ fichiers critiques)

**Priorité:** Commencer par les fichiers critiques (> 500 lignes) et l'extraction de la logique métier.

