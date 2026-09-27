import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TVFocusWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleFactor;
  final BorderRadius? borderRadius;
  final Color? focusColor;
  final FocusNode? focusNode;
  final bool autofocus;

  const TVFocusWrapper({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleFactor = 1.05,
    this.borderRadius,
    this.focusColor,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  State<TVFocusWrapper> createState() => _TVFocusWrapperState();
}

class _TVFocusWrapperState extends State<TVFocusWrapper> {
  late FocusNode _focusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.gameButtonA) {
            widget.onTap?.call();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
          splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          highlightColor: Colors.transparent,
          child: StatefulBuilder(
            builder: (context, setInternalState) {
              return Listener(
                onPointerDown: (_) {
                  if (mounted) setState(() {});
                },
                onPointerUp: (_) {
                  if (mounted) setState(() {});
                },
                onPointerCancel: (_) {
                  if (mounted) setState(() {});
                },
                child: AnimatedScale(
                  scale: (_hasFocus || Focus.of(context).hasFocus)
                      ? widget.scaleFactor
                      : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      borderRadius:
                          widget.borderRadius ?? BorderRadius.circular(8),
                      border: Border.all(
                        color: _hasFocus
                            ? (widget.focusColor ??
                                Theme.of(context).colorScheme.primary)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: widget.child,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
