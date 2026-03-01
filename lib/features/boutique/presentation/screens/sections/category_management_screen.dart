import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/features/boutique/application/providers.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/category.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import '../../widgets/boutique_header.dart';

class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          BoutiqueHeader(
            title: "CATÉGORIES",
            subtitle: "Gestion du catalogue",
            gradientColors: [
              const Color(0xFF4B5563), // Gray 600
              const Color(0xFF1F2937), // Gray 800
            ],
            shadowColor: const Color(0xFF4B5563),
            actions: [
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () => _showAddEditDialog(context, ref),
                tooltip: 'Ajouter une catégorie',
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: categoriesAsync.when(
              data: (categories) => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final category = categories[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: category.colorValue != null 
                              ? Color(category.colorValue!) 
                              : Colors.grey[200],
                          child: Icon(
                            Icons.category_outlined,
                            color: category.colorValue != null ? Colors.white : Colors.grey,
                          ),
                        ),
                        title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _showAddEditDialog(context, ref, category: category),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _confirmDelete(context, ref, category),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: categories.length,
                ),
              ),
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (e, s) => SliverFillRemaining(child: Center(child: Text('Erreur: $e'))),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, WidgetRef ref, {Category? category}) {
    showDialog(
      context: context,
      builder: (context) => _AddEditCategoryDialog(category: category),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la catégorie ?'),
        content: Text('Voulez-vous vraiment supprimer "${category.name}" ? Les produits associés ne seront pas supprimés mais n\'auront plus de catégorie.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              await ref.read(storeControllerProvider).deleteCategory(category.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _AddEditCategoryDialog extends ConsumerStatefulWidget {
  final Category? category;
  const _AddEditCategoryDialog({this.category});

  @override
  ConsumerState<_AddEditCategoryDialog> createState() => _AddEditCategoryDialogState();
}

class _AddEditCategoryDialogState extends ConsumerState<_AddEditCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  Color _selectedColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      if (widget.category!.colorValue != null) {
        _selectedColor = Color(widget.category!.colorValue!);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.category == null ? 'Nouvelle Catégorie' : 'Modifier Catégorie'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nom de la catégorie'),
              validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 24),
            const Text('Couleur distinctive', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
                Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
                Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
                Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,
                Colors.brown, Colors.grey, Colors.blueGrey, Colors.black,
              ].map((color) => GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _selectedColor == color ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      if (_selectedColor == color)
                        BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4, spreadRadius: 2),
                    ],
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final enterpriseId = ref.read(activeEnterpriseProvider).value?.id ?? 'default';

    if (widget.category == null) {
      final category = Category(
        id: '',
        enterpriseId: enterpriseId,
        name: _nameController.text,
        colorValue: _selectedColor.toARGB32(),
        createdAt: DateTime.now(),
      );
      await ref.read(storeControllerProvider).createCategory(category);
    } else {
      final category = widget.category!.copyWith(
        name: _nameController.text,
        colorValue: _selectedColor.toARGB32(),
        updatedAt: DateTime.now(),
      );
      await ref.read(storeControllerProvider).updateCategory(category);
    }

    if (mounted) Navigator.pop(context);
  }
}
