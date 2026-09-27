import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final double strokeWidth;
  final double? value;
  final double dimension;

  /// Defaults to the theme's title colour; pass one for light backgrounds.
  final Color? color;
  const LoadingIndicator(
      {super.key,
      this.strokeWidth = 4,
      this.dimension = 25,
      this.value,
      this.color});
  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
        dimension: dimension,
        child: CircularProgressIndicator(
          value: value,
          strokeWidth: strokeWidth,
          color: color ?? Theme.of(context).textTheme.titleLarge!.color,
        ));
  }
}
