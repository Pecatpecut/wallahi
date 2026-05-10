import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  Color getColor() {
    switch (status) {
      case "success":
        return Colors.green;
      case "pending":
        return Colors.orange;
      case "expired":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String getText() {
    switch (status) {
      case "success":
        return "Success";
      case "pending":
        return "Pending";
      case "expired":
        return "Expired";
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: getColor().withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        getText(),
        style: TextStyle(
          color: getColor(),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}