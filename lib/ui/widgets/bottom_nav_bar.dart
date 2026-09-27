import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:zuno/ui/screens/Home/home_screen_controller.dart';

/// Glass bottom bar: blurred translucent background with icon-only tabs
/// (Home, Search, Library, Favourites, Settings).
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  static const _icons = [
    'assets/icons/nav_home.svg',
    'assets/icons/nav_search.svg',
    'assets/icons/nav_library.svg',
    'assets/icons/nav_favourites.svg',
    'assets/icons/nav_settings.svg',
  ];

  @override
  Widget build(BuildContext context) {
    final homeScreenController = Get.find<HomeScreenController>();
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          // Compact 50dp bar (+ system inset); ScrollToHideWidget uses the same
          height: 50 + bottomInset,
          padding: EdgeInsets.only(bottom: bottomInset),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(0.10),
                Colors.white.withOpacity(0.16),
              ],
            ),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.12)),
            ),
          ),
          child: Obx(() {
            final selected = homeScreenController.tabIndex.value;
            return Row(
              children: [
                for (var i = 0; i < _icons.length; i++)
                  Expanded(
                    child: _NavItem(
                      asset: _icons[i],
                      selected: selected == i,
                      onTap: () =>
                          homeScreenController.onBottonBarTabSelected(i),
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.asset,
    required this.selected,
    required this.onTap,
  });

  final String asset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 28,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // soft glow behind the selected icon
            gradient: selected
                ? RadialGradient(colors: [
                    Colors.white.withOpacity(0.22),
                    Colors.white.withOpacity(0.0),
                  ])
                : null,
          ),
          child: Center(
            child: AnimatedScale(
              duration: const Duration(milliseconds: 250),
              scale: selected ? 1.05 : 1.0,
              child: SvgPicture.asset(
                asset,
                width: 26,
                height: 26,
                colorFilter: ColorFilter.mode(
                  selected ? Colors.white : Colors.white.withOpacity(0.45),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
