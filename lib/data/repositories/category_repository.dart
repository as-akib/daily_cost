import '../models/category_item.dart';
import '../services/supabase_service.dart';

class CategoryRepository {
  final SupabaseService supabaseService;

  CategoryRepository({required this.supabaseService});

  Stream<List<CategoryItem>> streamCategories(String uid) =>
      supabaseService.streamCategories(uid);

  Future<void> saveCategory(String uid, CategoryItem category) =>
      supabaseService.addCategory(uid, category);

  Future<void> deleteCategory(String uid, String categoryId) =>
      supabaseService.deleteCategory(uid, categoryId);
}
