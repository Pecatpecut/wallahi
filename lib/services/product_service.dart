import 'supabase_service.dart';

class ProductService {
  final supabase = SupabaseService.client;

  Future<List<Map<String, dynamic>>> getProducts({String? category}) async {
    var query = supabase.from('products').select('''
      id,
      name,
      description,
      image,
      is_active,
      category,
      product_variants (
        id,
        type,
        price,
        duration_days
      )
    ''').eq('is_active', true);

    if (category != null && category != 'All') {
    query = query.eq('category', category);
  }

    return List<Map<String, dynamic>>.from(await query);
  }

  /// 🔥 UPDATE PRODUCT
Future<void> updateProduct(String id, Map data) async {
  await supabase.from('products').update(data).eq('id', id);
}

/// 🔥 DELETE PRODUCT
Future<void> deleteProduct(String id) async {
  await supabase.from('products').delete().eq('id', id);
}

/// 🔥 UPDATE VARIANT
Future<void> updateVariant(String id, Map data) async {
  await supabase
      .from('product_variants')
      .update(data)
      .eq('id', id);
}

/// 🔥 DELETE VARIANT
Future<void> deleteVariant(String id) async {
  await supabase
      .from('product_variants')
      .delete()
      .eq('id', id);
}

}