import 'package:flutter/material.dart';

// AUTH
import '../features/auth/login_page.dart';
import '../features/auth/register_page.dart';

// CUSTOMER
import '../features/customer/home_page.dart';
import '../features/customer/product_page.dart';
import '../features/customer/product_detail_page.dart';
import '../features/customer/checkout_page.dart';
import '../features/customer/payment_page.dart';
import '../features/customer/order_page.dart';
import '../features/customer/order_detail_page.dart';
import '../features/customer/profile_page.dart';
import '../features/customer/edit_profile_page.dart';
import '../features/customer/garansi_page.dart';
import '../features/customer/garansi_detail_page.dart';
import '../features/customer/garansiformpage.dart';
import '../features/customer/rules_page.dart';
import '../features/customer/social_page.dart';

// ADMIN (NEW SYSTEM)
import '../features/admin/admin_main_page.dart'; // 🔥 INI ROOT BARU
import '../features/admin/admin_order_page.dart';
import '../features/admin/admin_order_detail_page.dart';
import '../features/admin/admin_product_detail_page.dart';
import '../features/admin/admin_add_product_page.dart';
import '../features/admin/admin_add_variant_page.dart';
import '../features/admin/admin_garansi_page.dart';
import '../features/admin/admin_garansi_detail_page.dart';


class AppRoutes {
  static Map<String, WidgetBuilder> routes = {

    /// 🔐 AUTH
    '/login': (context) => const LoginPage(),
    '/register': (context) => const RegisterPage(),

    /// 👤 CUSTOMER
    '/home': (context) => const HomePage(),
    '/products': (context) => const ProductPage(),
    '/detail': (context) => const ProductDetailPage(),
    '/checkout': (context) => const CheckoutPage(),
    '/payment': (context) => const PaymentPage(),
    '/orders': (context) => const OrderPage(),
    '/order-detail': (context) => const OrderDetailPage(),
    '/profile': (context) => const ProfilePage(),
    '/edit-profile': (context) => const EditProfilePage(),
    '/garansi': (context) => const GaransiPage(),
    '/garansi-detail': (context) => const GaransiDetailPage(),
    '/rules': (context) => const RulesPage(),
    '/social': (context) => const SocialPage(),
    '/garansi-form': (context) => const GaransiFormPage(),

    /// 🛠 ADMIN (UPDATED)
    '/admin': (context) => const AdminMainPage(), // 🔥 FIX DI SINI

    '/admin-order': (context) => const AdminOrderPage(),
    '/admin-order-detail': (context) => const AdminOrderDetailPage(),

    '/admin-product-detail': (context) => const AdminProductDetailPage(),
    '/admin-add-product': (context) => const AdminAddProductPage(),
    '/admin-add-variant': (context) => const AdminAddVariantPage(),

    '/admin-garansi': (context) => const AdminGaransiPage(),
    '/admin-garansi-detail': (context) => const AdminGaransiDetailPage(),
  };
}