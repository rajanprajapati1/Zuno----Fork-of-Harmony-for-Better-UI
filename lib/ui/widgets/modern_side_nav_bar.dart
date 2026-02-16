import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../screens/Home/home_screen_controller.dart';
import '../screens/Settings/settings_screen_controller.dart';

class ModernSideNavBar extends StatelessWidget {
  const ModernSideNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeScreenController controller = Get.find<HomeScreenController>();
    final SettingsScreenController settingsScreenController = Get.find<SettingsScreenController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark ? const Color(0xFF0F0F0F) : Colors.white;
    final sidebarWidth = 200.0; // Even more compact

    return Container(
      width: sidebarWidth,
      height: double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 8, right: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20), // Minimal top spacing

          // Navigation Items Grouped Together (Text Only, Fully Rounded)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [
                  _buildNavMenuItem(
                    context, 
                    index: 0, 
                    label: "Home", 
                    controller: controller
                  ),
                  _buildNavMenuItem(
                    context, 
                    index: 1, 
                    label: settingsScreenController.isBottomNavBarEnabled.isTrue ? "Search" : "Songs", 
                    controller: controller
                  ),
                  _buildNavMenuItem(
                    context, 
                    index: 2, 
                    label: "Playlists", 
                    controller: controller
                  ),
                  _buildNavMenuItem(
                    context, 
                    index: 4, 
                    label: "Artists", 
                    controller: controller
                  ),
                  _buildNavMenuItem(
                    context, 
                    index: 5, 
                    label: "Settings", 
                    controller: controller
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavMenuItem(
    BuildContext context, {
    required int index,
    required String label,
    required HomeScreenController controller,
  }) {
    return Obx(() {
      final isSelected = controller.tabIndex.value == index;
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: InkWell(
          onTap: () => controller.onSideBarTabSelected(index),
          borderRadius: BorderRadius.circular(100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              color: isSelected && isDark 
                  ? Colors.white.withOpacity(0.08) 
                  : isSelected ? theme.colorScheme.primary.withOpacity(0.12) : Colors.transparent,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected 
                    ? (isDark ? Colors.white : theme.colorScheme.primary)
                    : Colors.grey[isDark ? 500 : 700],
                letterSpacing: -0.4,
              ),
            ),
          ),
        ),
      );
    });
  }
}
