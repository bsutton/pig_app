import 'package:flutter/widgets.dart';

typedef OnSwipe = void Function();

class HMBSwipeLeft extends StatelessWidget {
  final Widget child;

  final OnSwipe onSwipe;

  const HMBSwipeLeft({required this.child, required this.onSwipe, super.key});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onHorizontalDragEnd: (details) {
      // Check if the swipe is from left to right
      if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
        onSwipe();
      }
    },
    child: child,
  );
}
