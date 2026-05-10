import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  final supabase = Supabase.instance.client;

  // TOTAL ORDERS
  Future<int> getTotalOrders() async {
    final data = await supabase.from('orders').select('id');
    return data.length;
  }

  // TOTAL USERS
  Future<int> getTotalUsers() async {
    final data = await supabase.from('users').select('id');
    return data.length;
  }

  // TOTAL INCOME
  Future<int> getTotalIncome() async {
    final data = await supabase
        .from('orders')
        .select('price')
        .eq('status', 'approved');

    int total = 0;
    for (var item in data) {
      total += (item['price'] ?? 0) as int;
    }

    return total;
  }

  Future<int> getPendingOrders() async {
  final response = await supabase
      .from('orders')
      .select()
      .eq('status', 'pending');

  return response.length;
}

  // INCOME PER BULAN
  Future<List<int>> getMonthlyIncome() async {
    final data = await supabase
        .from('orders')
        .select('price, created_at')
        .eq('status', 'approved');

    List<int> monthly = List.generate(12, (_) => 0);

    for (var item in data) {
      final date = DateTime.parse(item['created_at']);
      final month = date.month - 1;

      monthly[month] += (item['price'] ?? 0) as int;
    }

    return monthly;
  }
}