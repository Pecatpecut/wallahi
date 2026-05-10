import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  /// REGISTER
  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
    );

    final user = response.user;

    if (user == null) {
      throw Exception("Gagal membuat akun");
    }

    /// insert ke table users
    await supabase.from('users').insert({
      'id': user.id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': 'customer',
    });
  }

  /// LOGIN
  Future<String> login({
    required String email,
    required String password,
  }) async {
    final authRes = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = authRes.user;

    if (user == null) {
      throw Exception("Login gagal");
    }

    final data = await supabase
        .from('users')
        .select('role')
        .eq('id', user.id)
        .single();

    return data['role'];
  }

  /// LOGOUT
  Future<void> logout() async {
    await supabase.auth.signOut();
  }
}