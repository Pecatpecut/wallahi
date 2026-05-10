import 'package:supabase_flutter/supabase_flutter.dart';

class ClaimsService {
  final supabase = Supabase.instance.client;

  /// 🔥 CREATE CLAIM
  Future<void> createClaim({
  required String orderId,
  required String userId,
  required String title,       // ✅ FIX: pisah jadi 2 param
  required String description,
  String? imageUrl,
}) async {
  await supabase.from('claims').insert({
    "order_id": orderId,
    "user_id": userId,
    "title": title,
    "problem_description": description,
    "proof_image": imageUrl,
    "status": "pending",
  });
}
  /// 🔥 GET USER CLAIMS
Future<List<Map<String, dynamic>>> getUserClaims() async {
  final user = supabase.auth.currentUser;
  if (user == null) return [];

  final data = await supabase
      .from('claims')
      .select('''
        id,
        title,
        problem_description,
        proof_image,
        status,
        created_at,
        order_id,

        orders (
          id,
          product_name,
          variant_type,

          products (
            image
          )
        )
      ''')
      .eq('user_id', user.id)
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(data);
}

/// 🔥 GET ALL CLAIMS (ADMIN - FIX TOTAL)
Future<List<Map<String, dynamic>>> getClaims() async {
  try {
    final data = await supabase
        .from('claims')
        .select('''
          id,
          title,
          problem_description,
          proof_image,
          status,
          created_at,
          order_id,

          orders!inner (
            id,
            product_name,
            variant_type
          )
        ''')
        .order('created_at', ascending: false);

    print("🔥 CLAIMS DATA: $data");

    return List<Map<String, dynamic>>.from(data);
  } catch (e) {
    print("❌ ERROR GET CLAIMS: $e");

    return [];
  }
}

  /// 🔥 GET CLAIM BY ORDER
  Future<List<Map<String, dynamic>>> getClaimsByOrder(
      String orderId) async {
    final data = await supabase
        .from('claims')
        .select()
        .eq('order_id', orderId);

    return List<Map<String, dynamic>>.from(data);
  }

  /// 🔥 UPDATE STATUS (APPROVE / REJECT)
  Future<void> updateClaimStatus(String id, String status) async {
    await supabase
        .from('claims')
        .update({"status": status})
        .eq('id', id);
  }

  /// 🔥 UPDATE CLAIM (STATUS + ADMIN NOTE)
Future<void> updateClaim({
  required String id,
  required String status,
  required String note,
}) async {
  await supabase.from('claims').update({
    "status": status,
    "admin_note": note,
  }).eq('id', id);
}


}