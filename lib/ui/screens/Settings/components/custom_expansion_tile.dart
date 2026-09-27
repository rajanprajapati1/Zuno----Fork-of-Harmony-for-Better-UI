import 'package:flutter/material.dart';

/// Flat settings section: icon + title row with a thin divider, expanding
/// to show its options on a faint tint. No card background or rounding.
class CustomExpansionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const CustomExpansionTile(
      {super.key,
      required this.children,
      required this.icon,
      required this.title});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.titleMedium!.color!;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.07)),
        ),
      ),
      child: Theme(
        // no default divider lines from ExpansionTile
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          childrenPadding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
          tilePadding: const EdgeInsets.only(right: 4, left: 2),
          minTileHeight: 60,
          textColor: textColor,
          iconColor: textColor,
          collapsedTextColor: textColor,
          collapsedIconColor: textColor.withOpacity(0.5),
          backgroundColor: Colors.white.withOpacity(0.03),
          title: Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2)),
          leading: Icon(icon, size: 22, color: textColor.withOpacity(0.75)),
          children: children,
        ),
      ),
    );
  }
}
