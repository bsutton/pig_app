import 'package:flutter/material.dart';

class HMBScrollText extends StatelessWidget {
  final String text;

  final double maxHeight;

  const HMBScrollText({required this.text, this.maxHeight = 300, super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: maxHeight, // Set your maximum height here
      ),
      child: SingleChildScrollView(
        child: Text(text, style: const TextStyle(fontSize: 16)),
      ),
    ),
  );
}
