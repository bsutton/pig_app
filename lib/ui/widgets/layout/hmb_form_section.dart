import 'package:flutter/material.dart';

class HMBFormSection extends StatelessWidget {
  final bool leadingSpace;

  final List<Widget> children;

  const HMBFormSection({
    required this.children,
    super.key,
    this.leadingSpace = true,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: children,
  );
}
