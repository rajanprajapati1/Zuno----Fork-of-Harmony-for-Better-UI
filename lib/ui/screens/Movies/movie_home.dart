import 'package:flutter/material.dart';
import 'package:zuno/services/session_guard.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:zuno/services/tmdb_service.dart';
import 'package:zuno/services/iptv_service.dart';
import 'package:zuno/ui/screens/Movies/movie_home_controller.dart';
import 'package:zuno/ui/screens/Movies/movie_discover_screen.dart';
import 'package:zuno/ui/screens/Movies/tv_show_discover_screen.dart';
import 'package:zuno/ui/screens/Movies/live_tv_screen.dart';
import 'package:zuno/ui/screens/Movies/movie_search_screen.dart';
import 'package:zuno/ui/screens/Settings/settings_screen.dart';
import 'package:zuno/ui/widgets/tv_focus_wrapper.dart';

class MovieHome extends StatefulWidget {
  const MovieHome({super.key});

  @override
  State<MovieHome> createState() => _MovieHomeState();
}

class _MovieHomeState extends State<MovieHome> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<TmdbService>()) Get.put(TmdbService());
    if (!Get.isRegistered<IptvService>()) Get.put(IptvService());
    if (!Get.isRegistered<MovieHomeController>())
      Get.put(MovieHomeController());
  }

  final _contentPages = const [
    MovieDiscoverScreen(),
    TvShowDiscoverScreen(),
    LiveTvScreen(),
    MovieSearchScreen(),
  ];

  final _navItems = const [
    _NavItem(Icons.movie_outlined, Icons.movie, 'Movies'),
    _NavItem(Icons.tv_outlined, Icons.tv, 'TV Shows'),
    _NavItem(Icons.live_tv_outlined, Icons.live_tv, 'Live TV'),
    _NavItem(Icons.search_outlined, Icons.search, 'Search'),
    _NavItem(Icons.settings_outlined, Icons.settings, 'Settings'),
    _NavItem(Icons.music_note_outlined, Icons.music_note, 'Music'),
  ];

  void _onNavTap(int i) {
    if (i == 4) {
      // Settings — open as bottom sheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.92,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Expanded(
                  child: SettingsScreen(isBottomNavActive: true),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }
    if (i == 5) {
      _switchToMusic();
      return;
    }
    setState(() => _selectedIndex = i);
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE50914),
          surface: Colors.black,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: isWideScreen
            ? Row(
                children: [
                  _buildSidebar(context),
                  Expanded(child: _contentPages[_selectedIndex]),
                ],
              )
            : _contentPages[_selectedIndex],
        bottomNavigationBar: isWideScreen
            ? null
            : Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  border: Border(
                      top: BorderSide(color: Colors.grey[800]!, width: 0.5)),
                ),
                child: NavigationBar(
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  indicatorColor:
                      const Color(0xFFE50914).withValues(alpha: 0.2),
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onNavTap,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: _navItems
                      .map((item) => NavigationDestination(
                            icon: Icon(item.icon, color: Colors.grey),
                            selectedIcon: Icon(item.activeIcon,
                                color: const Color(0xFFE50914)),
                            label: item.label,
                          ))
                      .toList(),
                ),
              ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 220,
      color: const Color(0xFF141414),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Image.asset('assets/logo.png', width: 36, height: 36),
                const SizedBox(width: 10),
                const Text('Zuno',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(
              _navItems.length, (i) => _buildSidebarItem(_navItems[i], i)),
          const Spacer(),
          // Switch to Music
          Padding(
            padding: const EdgeInsets.all(16),
            child: TVFocusWrapper(
              onTap: _switchToMusic,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.music_note, color: Colors.white70, size: 20),
                    SizedBox(width: 8),
                    Text('Switch to Music',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
          TextButton.icon(
            onPressed: SessionGuard.confirmLogout,
            style: TextButton.styleFrom(foregroundColor: Colors.white54),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Log out'),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(_NavItem item, int index) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: TVFocusWrapper(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFE50914).withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(isSelected ? item.activeIcon : item.icon,
                  color:
                      isSelected ? const Color(0xFFE50914) : Colors.grey[500],
                  size: 22),
              const SizedBox(width: 12),
              Text(item.label,
                  style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[500],
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  void _switchToMusic() {
    Hive.box('AppPrefs').put('appMode', 'music');
    Get.offAllNamed('/');
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}
