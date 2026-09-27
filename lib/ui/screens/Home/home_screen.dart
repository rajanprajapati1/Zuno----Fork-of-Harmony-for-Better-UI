import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zuno/ui/utils/brand.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:audio_service/audio_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:zuno/models/media_Item_builder.dart';
import 'package:zuno/ui/widgets/image_widget.dart';
import 'package:zuno/ui/widgets/now_playing_overlay.dart';
import 'package:zuno/ui/widgets/made_by_refresh.dart';
import 'package:zuno/ui/widgets/motion.dart';

import '../Search/components/desktop_search_bar.dart';
import 'package:zuno/ui/screens/Search/search_screen_controller.dart';
import 'package:zuno/ui/widgets/animated_screen_transition.dart';
import '../Library/library_combined.dart';
import '../../widgets/side_nav_bar.dart';
import '../../widgets/modern_side_nav_bar.dart';
import '../Library/library.dart';
import '../Search/search_screen.dart';
import '../Settings/settings_screen_controller.dart';
import 'package:zuno/ui/player/player_controller.dart';
import 'package:zuno/ui/widgets/create_playlist_dialog.dart';
import '../../navigator.dart';
import '../../widgets/content_list_widget.dart';
import '../../widgets/quickpickswidget.dart';
import '../../widgets/shimmer_widgets/home_shimmer.dart';
import 'home_screen_controller.dart';
import '../Settings/settings_screen.dart';
import '../Playlist/favourites_screen.dart';
import '../Library/library_controller.dart';
import 'package:zuno/models/quick_picks.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final PlayerController playerController = Get.find<PlayerController>();
    final HomeScreenController homeScreenController =
        Get.find<HomeScreenController>();
    final SettingsScreenController settingsScreenController =
        Get.find<SettingsScreenController>();

    return Scaffold(
        floatingActionButton: Obx(
          () => ((homeScreenController.tabIndex.value == 0 &&
                          !GetPlatform.isDesktop) ||
                       homeScreenController.tabIndex.value == 2) &&
                  settingsScreenController.isBottomNavBarEnabled.isFalse
              ? Obx(
                  () => Padding(
                    padding: EdgeInsets.only(
                        bottom: playerController.playerPanelMinHeight.value >
                                Get.mediaQuery.padding.bottom
                            ? playerController.playerPanelMinHeight.value -
                                Get.mediaQuery.padding.bottom
                            : playerController.playerPanelMinHeight.value),
                    child: SizedBox(
                      height: 60,
                      width: 60,
                      child: FittedBox(
                        child: FloatingActionButton(
                            focusElevation: 0,
                            shape: const RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(14))),
                            elevation: 0,
                            onPressed: () async {
                              if (homeScreenController.tabIndex.value == 2) {
                                showDialog(
                                    context: context,
                                    builder: (context) =>
                                        const CreateNRenamePlaylistPopup());
                              } else {
                                Get.toNamed(ScreenNavigationSetup.searchScreen,
                                    id: ScreenNavigationSetup.id);
                              }
                              // file:///data/user/0/com.example.Zuno/cache/libCachedImageData/
                              //file:///data/user/0/com.example.Zuno/cache/just_audio_cache/
                            },
                            child: Icon(homeScreenController.tabIndex.value == 2
                                ? Icons.add
                                : Icons.search)),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        body: Obx(
          () => Row(
            children: <Widget>[
              // create a navigation rail
              settingsScreenController.isBottomNavBarEnabled.isFalse
                  ? const ModernSideNavBar()
                  : const SizedBox(
                      width: 0,
                    ),
              //const VerticalDivider(thickness: 1, width: 2),
              Expanded(
                child: _TabSwipe(
                    enabled:
                        settingsScreenController.isBottomNavBarEnabled.isTrue,
                    child: Obx(() => AnimatedScreenTransition(
                    enabled: settingsScreenController
                        .isTransitionAnimationDisabled.isFalse,
                    resverse: homeScreenController.reverseAnimationtransiton,
                    horizontalTransition:
                        settingsScreenController.isBottomNavBarEnabled.isTrue,
                    child: Center(
                      key: ValueKey<int>(homeScreenController.tabIndex.value),
                      child: const Body(),
                    )))),
              ),
            ],
          ),
        ));
  }
}

class Body extends StatelessWidget {
  const Body({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final homeScreenController = Get.find<HomeScreenController>();
    final settingsScreenController = Get.find<SettingsScreenController>();
    final size = MediaQuery.of(context).size;
    final topPadding = GetPlatform.isDesktop
        ? 85.0
        : context.isLandscape
            ? 50.0
            : size.height < 750
                ? 80.0
                : 85.0;
    final leftPadding =
        settingsScreenController.isBottomNavBarEnabled.isTrue ? 20.0 : 20.0;
    
    Widget content;
    final tab = homeScreenController.tabIndex.value;
    if (tab == 0) {
      content = _buildHomeTab(context, homeScreenController, topPadding);
    } else if (settingsScreenController.isBottomNavBarEnabled.isTrue) {
      // Bottom tabs: Home, Search, Library, Favourites, Settings
      content = switch (tab) {
        1 => const SearchScreen(),
        2 => const CombinedLibrary(),
        3 => const FavouritesScreen(),
        4 => const SettingsScreen(isBottomNavActive: true),
        _ => Center(child: Text("$tab")),
      };
    } else if (homeScreenController.tabIndex.value == 1) {
      content = settingsScreenController.isBottomNavBarEnabled.isTrue
          ? const SearchScreen()
          : const SongsLibraryWidget();
    } else if (homeScreenController.tabIndex.value == 2) {
      content = settingsScreenController.isBottomNavBarEnabled.isTrue
          ? const CombinedLibrary()
          : const PlaylistNAlbumLibraryWidget(isAlbumContent: false);
    } else if (homeScreenController.tabIndex.value == 3) {
      content = settingsScreenController.isBottomNavBarEnabled.isTrue
          ? const SettingsScreen(isBottomNavActive: true)
          : const PlaylistNAlbumLibraryWidget();
    } else if (homeScreenController.tabIndex.value == 4) {
      content = const LibraryArtistWidget();
    } else if (homeScreenController.tabIndex.value == 5) {
      content = const SettingsScreen();
    } else {
      content = Center(
        child: Text("${homeScreenController.tabIndex.value}"),
      );
    }

    return Padding(
      padding: EdgeInsets.only(left: leftPadding, right: 10.0),
      child: content,
    );
  }

  Widget _buildHomeTab(BuildContext context, HomeScreenController homeScreenController, double topPadding) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            // for Desktop search bar
            if (GetPlatform.isDesktop) {
              final sscontroller = Get.find<SearchScreenController>();
              if (sscontroller.focusNode.hasFocus) {
                sscontroller.focusNode.unfocus();
              }
            }
          },
          child: Obx(
            () => homeScreenController.networkError.isTrue
                ? SizedBox(
                    height: MediaQuery.of(context).size.height - 180,
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            "home".tr,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "networkError1".tr,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 15, vertical: 10),
                                    decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .textTheme
                                            .titleLarge!
                                            .color,
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: InkWell(
                                      onTap: () {
                                        homeScreenController
                                            .loadContentFromNetwork();
                                      },
                                      child: Text(
                                        "retry".tr,
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .canvasColor),
                                      ),
                                    ),
                                  ),
                                ]),
                          ),
                        )
                      ],
                    ),
                  )
                : Obx(() {
                    // dispose all detachached scroll controllers
                    homeScreenController.disposeDetachedScrollControllers();
                    final items = homeScreenController
                            .isContentFetched.value
                        ? [
                            if (!GetPlatform.isDesktop) const _Greeting(),
                            if (!GetPlatform.isDesktop) const _RecentlyPlayed(),
                            Obx(() {
                              final scrollController = ScrollController();
                              homeScreenController.contentScrollControllers
                                  .add(scrollController);
                              return QuickPicksWidget(
                                  content:
                                      homeScreenController.quickPicks.value,
                                  scrollController: scrollController);
                            }),
                            // Added: Your Favorites section from library
                            Obx(() {
                              final libSongsController = Get.find<LibrarySongsController>();
                              if (libSongsController.librarySongsList.isEmpty) return const SizedBox.shrink();
                              
                              final favSongs = libSongsController.librarySongsList
                                  .where((s) => s.extras?['isFavorite'] == true)
                                  .toList();
                              
                              if (favSongs.isEmpty) return const SizedBox.shrink();
                              
                              final scrollController = ScrollController();
                              homeScreenController.contentScrollControllers.add(scrollController);
                              
                              return QuickPicksWidget(
                                content: QuickPicks(
                                  favSongs.length > 20 ? favSongs.sublist(0, 20) : favSongs,
                                  title: "Your Favorites",
                                ),
                                scrollController: scrollController,
                              );
                            }),
                            ...getWidgetList(
                                homeScreenController.middleContent,
                                homeScreenController),
                            ...getWidgetList(
                                homeScreenController.fixedContent,
                                homeScreenController)
                          ]
                        : [const HomeShimmer()];
                    final list = ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                          parent: ClampingScrollPhysics()),
                      padding: EdgeInsets.only(
                          bottom: 200,
                          top: GetPlatform.isDesktop
                              ? topPadding
                              : MediaQuery.of(context).padding.top + 4),
                      itemCount: items.length,
                      // sections fade/slide in, staggered from the top
                      itemBuilder: (context, index) =>
                          items[index].appear(index: index),
                    );
                    if (GetPlatform.isDesktop) return list;
                    // pull down: "Made by ❤️ Rajan" + refresh
                    return MadeByRefresh(
                      onRefresh: () => homeScreenController
                          .loadContentFromNetwork(silent: true),
                      child: list,
                    );
                  }),
          ),
        ),
        if (GetPlatform.isDesktop)
          Align(
            alignment: Alignment.topCenter,
            child: LayoutBuilder(builder: (context, constraints) {
              return SizedBox(
                width: constraints.maxWidth > 800
                    ? 800
                    : constraints.maxWidth - 40,
                child: const Padding(
                    padding: EdgeInsets.only(top: 15.0),
                    child: DesktopSearchBar()),
              );
            }),
          )
      ],
    );
  }

  List<Widget> getWidgetList(
      dynamic list, HomeScreenController homeScreenController) {
    return list
        .map((content) {
          final scrollController = ScrollController();
          homeScreenController.contentScrollControllers.add(scrollController);
          return ContentListWidget(
              content: content, scrollController: scrollController);
        })
        .whereType<Widget>()
        .toList();
  }
}

/// Swipe left/right on a tab page to move to the next/previous bottom-nav
/// tab. Horizontal scrollers inside (carousels, swipeable rows) win the
/// gesture first, so they keep working.
class _TabSwipe extends StatefulWidget {
  const _TabSwipe({required this.enabled, required this.child});
  final bool enabled;
  final Widget child;

  @override
  State<_TabSwipe> createState() => _TabSwipeState();
}

class _TabSwipeState extends State<_TabSwipe> {
  static const _tabCount = 5;
  double _dx = 0;

  void _end(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    final dx = _dx;
    _dx = 0;
    // needs either a flick or a clear drag distance
    if (v.abs() < 350 && dx.abs() < 90) return;
    final c = Get.find<HomeScreenController>();
    final next = c.tabIndex.value + ((v != 0 ? v : dx) < 0 ? 1 : -1);
    if (next < 0 || next >= _tabCount) return;
    HapticFeedback.selectionClick();
    c.onBottonBarTabSelected(next);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || GetPlatform.isDesktop) return widget.child;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (_) => _dx = 0,
      onHorizontalDragUpdate: (d) => _dx += d.delta.dx,
      onHorizontalDragEnd: _end,
      child: widget.child,
    );
  }
}

/// Home header: bell + profile actions and a big condensed "Home" title.
class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    final textColor =
        Theme.of(context).textTheme.titleLarge?.color ?? Colors.white;
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Notifications',
                icon: SvgPicture.asset('assets/icons/notifications-outline.svg',
                    width: 25,
                    height: 25,
                    colorFilter:
                        ColorFilter.mode(textColor, BlendMode.srcIn)),
                onPressed: () {},
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'settings'.tr,
                icon: SvgPicture.asset('assets/icons/person-outline.svg',
                    width: 25,
                    height: 25,
                    colorFilter:
                        ColorFilter.mode(textColor, BlendMode.srcIn)),
                onPressed: () =>
                    Get.find<HomeScreenController>().onBottonBarTabSelected(4),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('home'.tr,
              style: headerFont(color: textColor)),
        ],
      ),
    );
  }
}

/// "Recently played" row of square covers, read from the LIBRP history box.
class _RecentlyPlayed extends StatelessWidget {
  const _RecentlyPlayed();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Box>(
      future: Hive.openBox("LIBRP"),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        return ValueListenableBuilder(
          valueListenable: snap.data!.listenable(),
          builder: (context, Box box, _) {
            final songs = box.values
                .map((e) => MediaItemBuilder.fromJson(e))
                .toList()
                .reversed
                .take(15)
                .toList();
            if (songs.isEmpty) return const SizedBox.shrink();
            final playerController = Get.find<PlayerController>();
            final textColor =
                Theme.of(context).textTheme.titleLarge?.color ?? Colors.white;
            return Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 12),
                    child: Text('Recently played',
                        style: sectionFont(color: textColor)),
                  ),
                  SizedBox(
                    height: 132,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(left: 2, right: 10),
                      itemCount: songs.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) => PressScale(
                          child: InkWell(
                        onTap: () =>
                            playerController.pushSongToQueue(songs[i]),
                        child: SizedBox(
                          width: 100,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(children: [
                                ImageWidget(song: songs[i], size: 100),
                                NowPlayingOverlay(
                                    songId: songs[i].id, size: 100),
                              ]),
                              const SizedBox(height: 7),
                              Text(songs[i].title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: textColor.withOpacity(0.75),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      )),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
