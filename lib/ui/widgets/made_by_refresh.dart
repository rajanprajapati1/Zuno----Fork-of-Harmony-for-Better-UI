import 'dart:math' as math;

import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../utils/brand.dart';

/// Pull-to-refresh for Home: pulling down pours a white "paint" panel from
/// the top whose bottom edge drips (drips stretch with the pull and wobble
/// while refreshing), showing "Made by ❤️ Rajan". Releasing past the
/// threshold runs [onRefresh] while the heart beats.
class MadeByRefresh extends StatelessWidget {
  const MadeByRefresh({super.key, required this.child, required this.onRefresh});
  final Widget child;
  final Future<void> Function() onRefresh;

  static const _armedAt = 96.0;

  @override
  Widget build(BuildContext context) {
    return CustomRefreshIndicator(
      offsetToArmed: _armedAt,
      onRefresh: () async {
        // keep the credit visible for a moment even on a fast refresh
        await Future.wait([
          onRefresh(),
          Future.delayed(const Duration(milliseconds: 1400)),
        ]);
      },
      builder: (context, child, c) {
        return AnimatedBuilder(
          animation: c,
          builder: (context, _) {
            final pull = c.value.clamp(0.0, 1.25);
            final height = _armedAt * pull;
            final busy = c.isLoading || c.isComplete || c.isFinalizing;
            // the panel bleeds past the page side padding to the screen edges
            final box = context.findRenderObject() as RenderBox?;
            final left = box != null && box.hasSize
                ? box.localToGlobal(Offset.zero).dx
                : 0.0;
            final screenW = MediaQuery.of(context).size.width;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // only mounted while actually visible: a near-zero leftover
                // pull must not keep the wobble ticker running
                if (height >= 2)
                  Positioned(
                    top: 0,
                    left: -left,
                    width: screenW,
                    height: height,
                    child: _DripPanel(
                      pull: pull.toDouble(),
                      busy: busy,
                      beating: busy || c.isArmed,
                    ),
                  ),
                // content sits below the paint body (drips overlap it)
                Transform.translate(
                    offset: Offset(
                        0, height >= 2 ? height * _DripPanel.bodyFraction : 0),
                    child: child),
              ],
            );
          },
        );
      },
      child: child,
    );
  }
}

/// White panel with a dripping bottom edge and the credit text.
class _DripPanel extends StatefulWidget {
  const _DripPanel(
      {required this.pull, required this.busy, required this.beating});
  final double pull;
  final bool busy;
  final bool beating;

  /// Share of the panel height that is solid body; the rest is drips.
  static const bodyFraction = 0.8;

  @override
  State<_DripPanel> createState() => _DripPanelState();
}

class _DripPanelState extends State<_DripPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wobble = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800))
    ..repeat();

  @override
  void dispose() {
    _wobble.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.pull.clamp(0.0, 1.0);
    return AnimatedBuilder(
      animation: _wobble,
      builder: (context, _) => CustomPaint(
        painter: _DripPainter(
          pull: widget.pull,
          phase: _wobble.value * 2 * math.pi,
          wobble: widget.busy ? 1.0 : 0.35,
        ),
        child: LayoutBuilder(
          builder: (context, box) => Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: box.maxHeight * _DripPanel.bodyFraction,
              child: Center(
                child: Opacity(
                  opacity: Curves.easeOut.transform(t),
                  child: Transform.scale(
                    scale: 0.7 + 0.3 * Curves.easeOutBack.transform(t),
                    child: _Credit(beating: widget.beating),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints a white body whose bottom edge melts into rounded drips.
class _DripPainter extends CustomPainter {
  _DripPainter({required this.pull, required this.phase, required this.wobble});
  final double pull;
  final double phase;
  final double wobble;

  // (x position, neck half-width, length factor) for each drip, left→right
  static const _drips = <(double, double, double)>[
    (0.07, 5, 0.6),
    (0.19, 4, 1.0),
    (0.31, 6, 0.5),
    (0.44, 4, 0.85),
    (0.57, 5, 0.45),
    (0.70, 4, 0.95),
    (0.82, 6, 0.6),
    (0.94, 4, 0.8),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final bodyH = size.height * _DripPanel.bodyFraction;
    final maxDrip = size.height - bodyH;
    final paint = Paint()..color = kAccent;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, bodyH);

    // walk the bottom edge right→left, dropping a drip at each position
    var x = w;
    for (var i = _drips.length - 1; i >= 0; i--) {
      final (fx, half, lenF) = _drips[i];
      final cx = fx * w;
      final grow = Curves.easeOut.transform(pull.clamp(0.0, 1.0));
      final len = math.max(
          0.0,
          maxDrip * lenF * grow +
              math.sin(phase + i * 1.3) * 3 * wobble * grow);
      final r = half * (0.8 + 0.4 * grow); // blob radius
      final shoulder = half * 2.4;

      // gentle wave between drips
      final midX = (x + cx + shoulder) / 2;
      path.quadraticBezierTo(
          midX, bodyH + math.sin(phase * 0.5 + i) * 3 * wobble, cx + shoulder, bodyH);

      if (len < r * 1.2) {
        // too short for a drip yet: small bump
        path.quadraticBezierTo(cx, bodyH + len + r * 0.6, cx - shoulder, bodyH);
      } else {
        final tipY = bodyH + len - r;
        // right side of the neck flowing into the blob
        path.cubicTo(cx + half, bodyH, cx + r * 0.7, tipY - r * 1.2,
            cx + r, tipY);
        // rounded tip
        path.arcToPoint(Offset(cx - r, tipY),
            radius: Radius.circular(r), clockwise: true);
        // left side back up to the body
        path.cubicTo(cx - r * 0.7, tipY - r * 1.2, cx - half, bodyH,
            cx - shoulder, bodyH);
      }
      x = cx - shoulder;
    }
    path
      ..quadraticBezierTo(x / 2, bodyH + math.sin(phase) * 3 * wobble, 0, bodyH)
      ..close();

    // soft shadow under the paint for depth
    canvas.drawShadow(path, kAccentDeep, 4, false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_DripPainter old) =>
      old.pull != pull || old.phase != phase || old.wobble != wobble;
}

class _Credit extends StatelessWidget {
  const _Credit({required this.beating});
  final bool beating;

  @override
  Widget build(BuildContext context) {
    const heart = Text("❤️", style: TextStyle(fontSize: 16));
    final style = sectionFont(size: 16, color: Colors.white);
    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top * 0.5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Made by ", style: style),
          beating
              ? heart
                  .animate(onPlay: (a) => a.repeat(reverse: true))
                  .scaleXY(
                      begin: 1,
                      end: 1.3,
                      duration: 420.ms,
                      curve: Curves.easeInOut)
              : heart,
          Text(" Rajan", style: style),
        ],
      ),
    );
  }
}
