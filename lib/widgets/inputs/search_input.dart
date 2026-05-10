import 'package:flutter/material.dart';

class SearchInput extends StatelessWidget {
  final Function(String) onChanged;

  const SearchInput({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: "Search...",
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}