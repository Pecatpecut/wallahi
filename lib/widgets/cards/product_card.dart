import 'package:flutter/material.dart';
import 'app_card.dart';

class ProductCard extends StatelessWidget {
  final String image;
  final String title;
  final String price;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.image,
    required this.title,
    required this.price,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                image,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 5),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(price),
                const Icon(Icons.shopping_cart),
              ],
            ),
          ],
        ),
      ),
    );
  }
}