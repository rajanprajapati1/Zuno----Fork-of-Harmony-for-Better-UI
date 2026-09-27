import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:zuno/ui/widgets/motion.dart';
import 'package:zuno/ui/utils/brand.dart';
import 'package:get/get.dart';
import 'package:zuno/models/album.dart';
import 'package:zuno/models/artist.dart';
import 'package:zuno/models/playlist.dart';
import 'package:zuno/ui/player/player_controller.dart';
import 'package:zuno/ui/widgets/content_list_widget_item.dart';
import 'package:zuno/ui/widgets/image_widget.dart';
import 'package:zuno/ui/widgets/loader.dart';
import 'package:zuno/ui/widgets/page_title.dart';
import 'package:zuno/ui/widgets/song_list_tile.dart';

import '../../navigator.dart';
import '../../widgets/separate_tab_item_widget.dart';
import 'search_result_screen_controller.dart';

/// Search results (bottom-nav layout): search box header, square filter
/// chips and an "All" tab with top artist, featured playlists and a mixed
/// list of songs, albums and videos.
class SearchResultScreenBN extends StatelessWidget {
  const SearchResultScreenBN({super.key});

  @override
  Widget build(BuildContext context) {
    final SearchResultScreenController searchResScrController =
        Get.find<SearchResultScreenController>();
    final fg = Theme.of(context).textTheme.titleMedium?.color ?? Colors.white;
    void back() => Get.nestedKey(ScreenNavigationSetup.id)!.currentState!.pop();

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search box header; tapping it goes back to edit the query
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                children: [
                  IconButton(
                    tooltip: "back".tr,
                    onPressed: back,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 21),
                  ),
                  Expanded(
                    child: Material(
                      color: Colors.white.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(2),
                      child: InkWell(
                        onTap: back,
                        child: SizedBox(
                          height: 44,
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              Icon(Icons.search_rounded,
                                  size: 22, color: fg.withOpacity(0.7)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Obx(() => Text(
                                      searchResScrController.queryString.value,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: fg,
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w500),
                                    )),
                              ),
                              Icon(Icons.close_rounded,
                                  size: 20, color: fg.withOpacity(0.6)),
                              const SizedBox(width: 12),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                if (searchResScrController.isResultContentFetced.isTrue &&
                    searchResScrController.railItems.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("nomatch".tr,
                            style: Theme.of(context).textTheme.titleMedium),
                        Text(
                            "'${searchResScrController.queryString.value}'"),
                      ],
                    ),
                  );
                } else if (searchResScrController
                    .isResultContentFetced.isFalse) {
                  return const Center(child: LoadingIndicator());
                }
                final tabController = searchResScrController.tabController!;
                final labels = [
                  "All",
                  ...searchResScrController.railItems
                      .map((e) => e.toLowerCase().removeAllWhitespace.tr),
                ];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 34,
                      child: AnimatedBuilder(
                        animation: tabController.animation!,
                        builder: (context, _) {
                          final current =
                              tabController.animation!.value.round();
                          return ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: labels.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (_, i) => SquareChip(
                              label: labels[i],
                              selected: current == i,
                              onTap: () =>
                                  searchResScrController.onDestinationSelected(i),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: TabBarView(
                        controller: tabController,
                        children: [
                          const _AllResults(),
                          ...searchResScrController.railItems.map((tabName) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: SeparateTabItemWidget(
                                isResultWidget: true,
                                hideTitle: true,
                                items: const [],
                                title: tabName,
                                isCompleteList: true,
                                scrollController: searchResScrController
                                    .scrollControllers[tabName],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// "All" tab: top artist, "Featuring" playlists row, then songs/albums/videos.
class _AllResults extends StatelessWidget {
  const _AllResults();

  @override
  Widget build(BuildContext context) {
    final con = Get.find<SearchResultScreenController>();
    final playerController = Get.find<PlayerController>();
    final fg = Theme.of(context).textTheme.titleMedium?.color ?? Colors.white;

    List<T> listOf<T>(String key) =>
        List<T>.from((con.resultContent[key] as List?) ?? const []);

    return Obx(() {
      final artists = listOf<Artist>("Artists");
      final songs = listOf<MediaItem>("Songs");
      final videos = listOf<MediaItem>("Videos");
      final albums = listOf<Album>("Albums");
      final playlists = List<Playlist>.from(con.playlistPreview);

      return ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 200),
        children: <Widget>[
          if (artists.isNotEmpty) _ArtistRow(artist: artists.first, big: true),
          for (final s in songs.take(4))
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 4),
              child: SongListTile(
                  song: s, onTap: () => playerController.pushSongToQueue(s)),
            ),
          if (playlists.isNotEmpty) ...[
            _SectionTitle("Featuring ${con.queryString.value}"),
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: playlists.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => ContentListItem(content: playlists[i]),
              ),
            ),
          ],
          if (albums.isNotEmpty) ...[
            _SectionTitle("albums".tr),
            for (final a in albums.take(4))
              _MediaRow(
                image: ImageWidget(album: a, size: 56),
                title: a.title,
                subtitle: _albumSubtitle(a),
                fg: fg,
                onTap: () => Get.toNamed(ScreenNavigationSetup.albumScreen,
                    id: ScreenNavigationSetup.id, arguments: (a, a.browseId)),
              ),
          ],
          if (videos.isNotEmpty) ...[
            _SectionTitle("videos".tr),
            for (final v in videos.take(3))
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 4),
                child: SongListTile(
                    song: v, onTap: () => playerController.pushSongToQueue(v)),
              ),
          ],
          if (artists.length > 1) ...[
            _SectionTitle("artists".tr),
            for (final a in artists.skip(1).take(4)) _ArtistRow(artist: a),
          ],
        ].indexed.map((e) => e.$2.appear(index: e.$1)).toList(),
      );
    });
  }
}

/// "Album · Artist" (or year), skipping the type entries in the artist list.
String _albumSubtitle(Album a) {
  const types = {'Album', 'Single', 'EP'};
  final all = (a.artists ?? const [])
      .map((e) => (e['name'] ?? '').toString())
      .where((n) => n.isNotEmpty)
      .toList();
  final type = all.firstWhere(types.contains, orElse: () => 'Album');
  final names = all.where((n) => !types.contains(n)).toList();
  return [
    type,
    if (names.isNotEmpty) names.join(', ') else if (a.year != null) a.year!,
  ].join(' · ');
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 12),
      child: Text(text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: sectionFont(
              color: Theme.of(context).textTheme.titleMedium?.color)),
    );
  }
}

/// Artist row with a round photo; the top result gets a larger photo.
class _ArtistRow extends StatelessWidget {
  const _ArtistRow({required this.artist, this.big = false});
  final Artist artist;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).textTheme.titleMedium?.color ?? Colors.white;
    final size = big ? 64.0 : 52.0;
    return InkWell(
      onTap: () => Get.toNamed(ScreenNavigationSetup.artistScreen,
          id: ScreenNavigationSetup.id, arguments: [false, artist]),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            ImageWidget(
                artist: artist,
                size: size,
                borderRadius: BorderRadius.circular(size)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(artist.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: fg,
                                fontSize: big ? 17 : 15.5,
                                fontWeight: FontWeight.w700)),
                      ),
                      if (big) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded,
                            size: 16, color: Color(0xFF3D91F4)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                      artist.subscribers != null
                          ? "Artist · ${artist.subscribers}"
                          : "Artist",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(color: fg.withOpacity(0.6), fontSize: 13)),
                ],
              ),
            ),
            if (big)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  border: Border.all(color: fg.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text("View",
                    style: TextStyle(
                        color: fg, fontSize: 13, fontWeight: FontWeight.w600)),
              )
            else
              Icon(Icons.chevron_right_rounded, color: fg.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }
}

class _MediaRow extends StatelessWidget {
  const _MediaRow(
      {required this.image,
      required this.title,
      required this.subtitle,
      required this.fg,
      required this.onTap});
  final Widget image;
  final String title;
  final String subtitle;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        child: Row(
          children: [
            image,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: fg,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(color: fg.withOpacity(0.6), fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: fg.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }
}
