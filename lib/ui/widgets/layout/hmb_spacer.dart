import 'package:flutter/material.dart';

class HMBSpacer extends StatelessWidget {
  final bool width;

  final bool height;

  const HMBSpacer({this.width = false, this.height = false, super.key});

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: width ? 16.0 : null, height: height ? 16.0 : null);
}
