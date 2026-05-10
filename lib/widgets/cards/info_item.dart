import 'package:flutter/material.dart';

class InfoItem extends StatelessWidget {
  final String title;
  final String value;

  const InfoItem({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title),
        Text(value, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}