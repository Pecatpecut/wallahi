import 'package:flutter/material.dart';

class PaymentCard extends StatelessWidget {
  final String amount;

  const PaymentCard({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [

          const Text("QRIS Payment",
              style: TextStyle(fontWeight: FontWeight.bold)),

          const SizedBox(height: 15),

          /// 🔥 QR IMAGE
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              'assets/images/qris.png',
              height: 150,
            ),
          ),

          const SizedBox(height: 15),

          /// 🔥 PRICE
          Text(
            amount,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}