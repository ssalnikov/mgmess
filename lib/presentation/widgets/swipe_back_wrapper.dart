import 'package:flutter/material.dart';

class SwipeBackWrapper extends StatelessWidget {
  final Widget child;
  final VoidCallback onSwipeBack;

  const SwipeBackWrapper({
    super.key,
    required this.child,
    required this.onSwipeBack,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 20,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: (details) {
              if ((details.primaryVelocity ?? 0) > 300) {
                onSwipeBack();
              }
            },
          ),
        ),
      ],
    );
  }
}
