import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ScrollToHideWidget extends StatelessWidget {
  const ScrollToHideWidget(
      {super.key, required this.isVisible, required this.child});
  final Widget child;
  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      // Must match BottomNavBar height
      height: isVisible ? 50.0 + Get.mediaQuery.viewPadding.bottom : 0.0,
      child: child,
    );
  }
}
