import '../entities/category.dart';

abstract class CategoryRepository {
  Future<List<Category>> fetchCategories();
  Future<Category?> getCategory(String id);
  Future<String> createCategory(Category category);
  Future<void> updateCategory(Category category);
  Future<void> deleteCategory(String id, {required String deletedBy});
  Stream<List<Category>> watchCategories();
}
