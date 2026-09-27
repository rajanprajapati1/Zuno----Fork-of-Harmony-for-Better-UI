import 'package:flutter/material.dart';
import '../utils/brand.dart';

/// Large page title used at the top of the main tabs (Search, Library,
/// Favourites, Settings), aligned with the Home greeting.
class PageTitle extends StatelessWidget {
  const PageTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  /// Space above the title: status bar + the same gap Home uses.
  static double topPadding(BuildContext context) =>
      MediaQuery.of(context).padding.top + 28;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topPadding(context), left: 2, right: 4),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: headerFont(
                    color: Theme.of(context).textTheme.titleLarge?.color),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

/// Flat, square filter chip (selected = light fill, dark text).
class SquareChip extends StatelessWidget {
  const SquareChip(
      {super.key,
      required this.label,
      required this.selected,
      required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.black : Colors.white.withOpacity(0.9),
          ),
        ),
      ),
    );
  }
}
