import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Shared motion values so every screen moves the same way.
class Motion {
  static const fast = Duration(milliseconds: 140);
  static const medium = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 480);
  static const curve = Curves.easeOutCubic;
}

/// Entrance animation: fade + short upward slide. The first few items of a
/// list are staggered; later ones (built while scrolling) animate at once so
/// scrolling never waits.
extension AppearAnimation on Widget {
  Widget appear({int index = 0, double offset = 0.06}) {
    final delay = index < 8 ? Duration(milliseconds: 55 * index) : Duration.zero;
    return animate(delay: delay)
        .fadeIn(duration: Motion.medium, curve: Motion.curve)
        .slideY(begin: offset, end: 0, duration: Motion.slow, curve: Motion.curve);
  }
}

/// Shrinks its child slightly while pressed, then springs back. Does not
/// consume the tap, so wrapped InkWells and GestureDetectors still work.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.scale = 0.96});
  final Widget child;
  final double scale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: _down ? Motion.fast : Motion.medium,
        curve: _down ? Curves.easeOut : Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}

/// Cross-fades and scales between children when [child]'s key changes
/// (play <-> pause icons, like heart, etc.).
class PopSwitcher extends StatelessWidget {
  const PopSwitcher({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Motion.medium,
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(scale: anim, child: child),
      ),
      child: child,
    );
  }
}
