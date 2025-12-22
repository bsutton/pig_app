import 'package:flutter/material.dart';

class HMBPlaceHolder extends StatelessWidget {
  final double? width;

  final double? height;

  const HMBPlaceHolder({this.width, this.height, super.key});

  @override
  Widget build(BuildContext context) => SizedBox(width: width, height: height);
}
