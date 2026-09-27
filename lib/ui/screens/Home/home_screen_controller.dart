import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuno/ui/navigator.dart';
import 'package:hive/hive.dart';

import 'package:zuno/models/media_Item_builder.dart';
import 'package:zuno/ui/player/player_controller.dart';
import 'package:zuno/utils/update_check_flag_file.dart';
import 'package:zuno/utils/helper.dart';
import 'package:zuno/models/album.dart';
import 'package:zuno/models/playlist.dart';
import 'package:zuno/models/quick_picks.dart';
import 'package:zuno/services/music_service.dart';
import 'package:zuno/ui/screens/Settings/settings_screen_controller.dart';
import 'package:zuno/ui/widgets/new_version_dialog.dart';
import 'package:zuno/models/artist.dart';
import 'package:zuno/models/song.dart';

class HomeScreenController extends GetxController {
  final MusicServices _musicServices = Get.find<MusicServices>();
  final isContentFetched = false.obs;
  final isSidebarCollapsed = false.obs;
  final tabIndex = 0.obs;
  final networkError = false.obs;
  final quickPicks = QuickPicks([]).obs;
  final middleContent = [].obs;
  final fixedContent = [].obs;
  final showVersionDialog = true.obs;
  //isHomeScreenOnTop var only useful if bottom nav enabled
  final isHomeSreenOnTop = true.obs;
  final List<ScrollController> contentScrollControllers = [];
  bool reverseAnimationtransiton = false;

  @override
  onInit() {
    super.onInit();
    loadContent();
    if (updateCheckFlag) _checkNewVersion();
  }

  Future<void> loadContent() async {
    final box = Hive.box('AppPrefs');

    // One-time migration: clear old cached home data to pick up new sections
    if (box.get("homeCacheV5") == null) {
      try {
        final homeScreenData = await Hive.openBox("homeScreenData");
        await homeScreenData.clear();
        await homeScreenData.close();
      } catch (_) {}
      box.put("homeCacheV5", true);
      box.delete("homeScreenDataTime");
    }

    final isCachedHomeScreenDataEnabled =
        box.get("cacheHomeScreenData") ?? true;
    if (isCachedHomeScreenDataEnabled) {
      final loaded = await loadContentFromDb();

      if (loaded) {
        final currTimeSecsDiff = DateTime.now().millisecondsSinceEpoch -
            (box.get("homeScreenDataTime") ??
                DateTime.now().millisecondsSinceEpoch);
        if (currTimeSecsDiff / 1000 > 3600 * 8) {
          loadContentFromNetwork(silent: true);
        }
      } else {
        loadContentFromNetwork();
      }
    } else {
      loadContentFromNetwork();
    }
  }

  Future<bool> loadContentFromDb() async {
    try {
      final homeScreenData = await Hive.openBox("homeScreenData");
      if (homeScreenData.keys.isNotEmpty) {
        final String quickPicksType = homeScreenData.get("quickPicksType");
        final List quickPicksData = homeScreenData.get("quickPicks");
        final List middleContentData =
            homeScreenData.get("middleContent") ?? [];
        final List fixedContentData = homeScreenData.get("fixedContent") ?? [];
        quickPicks.value = QuickPicks(
            quickPicksData.map((e) => MediaItemBuilder.fromJson(e)).toList(),
            title: quickPicksType);
        middleContent.value = _deserializeContentList(middleContentData);
        fixedContent.value = _deserializeContentList(fixedContentData);
        isContentFetched.value = true;
        printINFO("Loaded from offline db");
        return true;
      } else {
        return false;
      }
    } catch (e) {
      printERROR("Failed to load cached home data, will refetch: $e");
      return false;
    }
  }

  Future<void> loadContentFromNetwork({bool silent = false}) async {
    final box = Hive.box('AppPrefs');
    String contentType = box.get("discoverContentType") ?? "QP";

    networkError.value = false;
    try {
      List middleContentTemp = [];
      // fetch every home section YouTube returns, not just the first few
      final homeContentListMap = await _musicServices.getHome(
          limit: max(
              Get.find<SettingsScreenController>().noOfHomeScreenContent.value,
              100));
      if (contentType == "TR") {
        final index = homeContentListMap
            .indexWhere((element) => element['title'] == "Trending");
        if (index != -1 && index != 0) {
          quickPicks.value = QuickPicks(
              List<MediaItem>.from(homeContentListMap[index]["contents"]),
              title: "Trending");
        } else if (index == -1) {
          List charts = await _musicServices.getCharts(contentType);
          final index = charts.indexWhere((element) =>
              element['title'] ==
              (contentType == "TMV" ? "Top Music Videos" : "Trending"));
          if (index != -1) {
            quickPicks.value = QuickPicks(
                List<MediaItem>.from(charts[index]["contents"]),
                title: charts[index]['title']);
            middleContentTemp.addAll(charts);
          }
        }
      } else if (contentType == "TMV") {
        final index = homeContentListMap
            .indexWhere((element) => element['title'] == "Top music videos");
        if (index != -1 && index != 0) {
          final con = homeContentListMap.removeAt(index);
          quickPicks.value = QuickPicks(List<MediaItem>.from(con["contents"]),
              title: con["title"]);
        } else if (index == -1) {
          List charts = await _musicServices.getCharts(contentType);
          final index = charts.indexWhere((element) =>
              element['title'] ==
              (contentType == "TMV" ? "Top Music Videos" : "Trending"));
          if (index != -1) {
            quickPicks.value = QuickPicks(
                List<MediaItem>.from(charts[index]["contents"]),
                title: charts[index]["title"]);
            middleContentTemp.addAll(charts);
          }
        }
      } else if (contentType == "BOLI") {
        try {
          final songId = box.get("recentSongId");
          if (songId != null) {
            final rel = (await _musicServices.getContentRelatedToSong(
                songId, getContentHlCode()));
            final con = rel.removeAt(0);
            quickPicks.value =
                QuickPicks(List<MediaItem>.from(con["contents"]));
            middleContentTemp.addAll(rel);
          }
        } catch (e) {
          printERROR(
              "Seems Based on last interaction content currently not available!");
        }
      }

      if (quickPicks.value.songList.isEmpty) {
        final index = homeContentListMap
            .indexWhere((element) => element['title'] == "Quick picks");
        if (index != -1) {
          final con = homeContentListMap.removeAt(index);
          quickPicks.value = QuickPicks(List<MediaItem>.from(con["contents"]),
              title: "Quick picks");
        }
      }

      middleContent.value = _setContentList(middleContentTemp);
      fixedContent.value = _setContentList(homeContentListMap);

      isContentFetched.value = true;

      // set home content last update time
      cachedHomeScreenData(updateAll: true);
      await Hive.box('AppPrefs')
          .put("homeScreenDataTime", DateTime.now().millisecondsSinceEpoch);

      // mood sections load after the main feed is already on screen
      _appendMoodSections();
      // ignore: unused_catch_stack
    } on NetworkError catch (r, e) {
      printERROR("Home Content not loaded due to ${r.message}");
      await Future.delayed(const Duration(seconds: 1));
      networkError.value = !silent;
    }
  }

  Future<void> _appendMoodSections() async {
    try {
      final moodSections = await _musicServices.getHomeMoodSections();
      final seenTitles = {
        quickPicks.value.title.toLowerCase(),
        ...[...middleContent, ...fixedContent]
            .map((e) => (e.title as String).toLowerCase()),
      };
      final newSections = moodSections.where((section) {
        final title = section['title']?.toString().toLowerCase();
        // "Quick picks" also appears inside chips; titles dedupe repeats
        return title != null && title != 'quick picks' && seenTitles.add(title);
      }).toList();
      if (newSections.isEmpty) return;
      fixedContent.addAll(_setContentList(newSections));
      cachedHomeScreenData(updateAll: true);
    } catch (e) {
      printERROR("Mood sections not loaded: $e");
    }
  }

  List _setContentList(
    List<dynamic> contents,
  ) {
    List contentTemp = [];
    for (var content in contents) {
      final List rawItems = content["contents"];
      if (rawItems.isEmpty) continue;

      // Filter out any null items
      final validItems = rawItems.where((e) => e != null).toList();
      if (validItems.isEmpty) continue;

      final firstItem = validItems[0];

      if (firstItem is Playlist) {
        final tmp = PlaylistContent(
            playlistList: validItems.whereType<Playlist>().toList(),
            title: content["title"]);
        if (tmp.playlistList.isNotEmpty) {
          contentTemp.add(tmp);
        }
      } else if (firstItem is Album) {
        final tmp = AlbumContent(
            albumList: validItems.whereType<Album>().toList(),
            title: content["title"]);
        if (tmp.albumList.isNotEmpty) {
          contentTemp.add(tmp);
        }
      } else if (firstItem is MediaItem) {
        final tmp = SongContent(
            songList: validItems.whereType<MediaItem>().toList(),
            title: content["title"]);
        if (tmp.songList.isNotEmpty) {
          contentTemp.add(tmp);
        }
      } else if (firstItem is Artist) {
        final tmp = ArtistContent(validItems.whereType<Artist>().toList(),
            title: content["title"]);
        if (tmp.content.isNotEmpty) {
          contentTemp.add(tmp);
        }
      }
    }
    return contentTemp;
  }

  Future<void> changeDiscoverContent(dynamic val, {String? songId}) async {
    QuickPicks? quickPicks_;
    if (val == 'QP') {
      final homeContentListMap = await _musicServices.getHome(limit: 3);
      quickPicks_ = QuickPicks(
          List<MediaItem>.from(homeContentListMap[0]["contents"]),
          title: homeContentListMap[0]["title"]);
    } else if (val == "TMV" || val == 'TR') {
      try {
        final charts = await _musicServices.getCharts(val);
        final index = charts.indexWhere((element) =>
            element['title'] ==
            (val == "TMV" ? "Top Music Videos" : "Trending"));
        quickPicks_ = QuickPicks(
            List<MediaItem>.from(charts[index]["contents"]),
            title: charts[index]["title"]);
      } catch (e) {
        printERROR(
            "Seems ${val == "TMV" ? "Top music videos" : "Trending songs"} currently not available!");
      }
    } else {
      songId ??= Hive.box('AppPrefs').get("recentSongId");
      if (songId != null) {
        try {
          final value = await _musicServices.getContentRelatedToSong(
              songId, getContentHlCode());
          middleContent.value = _setContentList(value);
          if (value.isNotEmpty && (value[0]['title']).contains("like")) {
            quickPicks_ =
                QuickPicks(List<MediaItem>.from(value[0]["contents"]));
            Hive.box('AppPrefs').put("recentSongId", songId);
          }
          // ignore: empty_catches
        } catch (e) {}
      }
    }
    if (quickPicks_ == null) return;

    quickPicks.value = quickPicks_;

    // set home content last update time
    cachedHomeScreenData(updateQuickPicksNMiddleContent: true);
    await Hive.box('AppPrefs')
        .put("homeScreenDataTime", DateTime.now().millisecondsSinceEpoch);
  }

  String getContentHlCode() {
    const List<String> unsupportedLangIds = ["ia", "ga", "fj", "eo"];
    final userLangId =
        Get.find<SettingsScreenController>().currentAppLanguageCode.value;
    return unsupportedLangIds.contains(userLangId) ? "en" : userLangId;
  }

  void onSideBarTabSelected(int index) {
    if (tabIndex.value == index) return;
    reverseAnimationtransiton = index > tabIndex.value;
    // Defer the tab change to the next microtask to avoid MouseTracker assertion errors
    // during navigation/rebuild triggered by a click.
    Future.microtask(() => tabIndex.value = index);
  }

  void onBottonBarTabSelected(int index) {
    // close pages opened on top of the tabs (playlist, album, artist,
    // library sections) so the chosen tab is actually shown; tapping the
    // current tab also returns to its main page
    final nav = Get.nestedKey(ScreenNavigationSetup.id)?.currentState;
    if (nav != null && nav.canPop()) nav.popUntil((route) => route.isFirst);
    if (tabIndex.value == index) return;
    reverseAnimationtransiton = index > tabIndex.value;
    tabIndex.value = index;
  }

  void _checkNewVersion() {
    showVersionDialog.value =
        Hive.box('AppPrefs').get("newVersionVisibility") ?? true;
    if (showVersionDialog.isTrue) {
      newVersionCheck(Get.find<SettingsScreenController>().currentVersion)
          .then((value) {
        if (value) {
          showDialog(
              context: Get.context!,
              builder: (context) => const NewVersionDialog());
        }
      });
    }
  }

  void onChangeVersionVisibility(bool val) {
    Hive.box('AppPrefs').put("newVersionVisibility", !val);
    showVersionDialog.value = !val;
  }

  ///This is used to minimized bottom navigation bar by setting [isHomeSreenOnTop.value] to `true` and set mini player height.
  ///
  ///and applicable/useful if bottom nav enabled
  void whenHomeScreenOnTop() {
    if (Get.find<SettingsScreenController>().isBottomNavBarEnabled.isTrue) {
      final currentRoute = getCurrentRouteName();
      final isHomeOnTop = currentRoute == '/homeScreen';
      final isResultScreenOnTop = currentRoute == '/searchResultScreen';
      final playerCon = Get.find<PlayerController>();

      isHomeSreenOnTop.value = isHomeOnTop;

      // Set miniplayer height accordingly
      if (!playerCon.initFlagForPlayer) {
        if (isHomeOnTop) {
          playerCon.playerPanelMinHeight.value = 75.0;
        } else {
          Future.delayed(
              isResultScreenOnTop
                  ? const Duration(milliseconds: 300)
                  : Duration.zero, () {
            playerCon.playerPanelMinHeight.value =
                75.0 + Get.mediaQuery.viewPadding.bottom;
          });
        }
      }
    }
  }

  Future<void> cachedHomeScreenData({
    bool updateAll = false,
    bool updateQuickPicksNMiddleContent = false,
  }) async {
    if (Get.find<SettingsScreenController>().cacheHomeScreenData.isFalse ||
        quickPicks.value.songList.isEmpty) {
      return;
    }

    final homeScreenData = Hive.box("homeScreenData");

    if (updateQuickPicksNMiddleContent) {
      await homeScreenData.putAll({
        "quickPicksType": quickPicks.value.title,
        "quickPicks": _getContentDataInJson(quickPicks.value.songList,
            isQuickPicks: true),
        "middleContent": _getContentDataInJson(middleContent.toList()),
      });
    } else if (updateAll) {
      await homeScreenData.putAll({
        "quickPicksType": quickPicks.value.title,
        "quickPicks": _getContentDataInJson(quickPicks.value.songList,
            isQuickPicks: true),
        "middleContent": _getContentDataInJson(middleContent.toList()),
        "fixedContent": _getContentDataInJson(fixedContent.toList())
      });
    }

    printINFO("Saved Homescreen data data");
  }

  List<Map<String, dynamic>> _getContentDataInJson(List content,
      {bool isQuickPicks = false}) {
    if (isQuickPicks) {
      return content.toList().map((e) => MediaItemBuilder.toJson(e)).toList();
    } else {
      return content
          .map<Map<String, dynamic>>((e) {
            if (e is AlbumContent) {
              return e.toJson();
            } else if (e is SongContent) {
              return e.toJson();
            } else if (e is PlaylistContent) {
              return e.toJson();
            } else if (e is ArtistContent) {
              return e.toJson();
            }
            return <String, dynamic>{};
          })
          .where((e) => e.isNotEmpty)
          .toList();
    }
  }

  List _deserializeContentList(List data) {
    return data.map((e) {
      final type = e["type"];
      if (type == "Album Content") {
        return AlbumContent.fromJson(e);
      } else if (type == "Song Content") {
        return SongContent.fromJson(e);
      } else if (type == "Artist Content") {
        return ArtistContent.fromJson(e);
      } else {
        return PlaylistContent.fromJson(e);
      }
    }).toList();
  }

  void disposeDetachedScrollControllers({bool disposeAll = false}) {
    final scrollControllersCopy = contentScrollControllers.toList();
    for (final contoller in scrollControllersCopy) {
      if (!contoller.hasClients || disposeAll) {
        contentScrollControllers.remove(contoller);
        contoller.dispose();
      }
    }
  }

  @override
  void dispose() {
    disposeDetachedScrollControllers(disposeAll: true);
    super.dispose();
  }
}
