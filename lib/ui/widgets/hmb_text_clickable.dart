import 'package:flutter/material.dart';

import 'text/hmb_text.dart';

class HMBTextClickable extends StatelessWidget {
  final String text;

  final VoidCallback onPressed;

  final bool bold;

  final Color color;

  const HMBTextClickable({
    required this.text,
    required this.onPressed,
    this.bold = false,
    this.color = Colors.blue,
    super.key,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onPressed,
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: HMBText(text, bold: bold, underline: true),
    ),
  );
}
