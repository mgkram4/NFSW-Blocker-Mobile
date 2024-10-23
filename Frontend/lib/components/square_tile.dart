import 'package:flutter/material.dart';

class SqaureTile extends StatelessWidget {
  final Icon icon;

  const SqaureTile({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[200],
      ),
      child: icon,
    );
  }
}
