import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:zuno/ui/widgets/motion.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import 'package:zuno/models/playling_from.dart';
import 'package:zuno/ui/player/player_controller.dart';
import 'package:zuno/ui/widgets/content_list_widget_item.dart';
import 'package:zuno/ui/widgets/image_widget.dart';
import 'package:zuno/ui/widgets/now_playing_overlay.dart';
import '../../navigator.dart';
import '../../widgets/loader.dart';
import '../../widgets/separate_tab_item_widget.dart';
import '../../widgets/snackbar.dart';
import '../../widgets/songinfo_bottom_sheet.dart';
import 'artist_screen_controller.dart';
import '../../utils/brand.dart';


/// Spotify-style artist page: full-width photo with the name on it, follow /
/// shuffle / play actions, numbered "Popular" songs, album and single rows,
/// videos and an About card.
class ArtistScreenBN extends StatelessWidget {
  const ArtistScreenBN(
      {super.key, required this.artistScreenController, required this.tag});
  final ArtistScreenController artistScreenController;
  final String tag;

  @override
  Widget build(BuildContext context) {
    final con = artistScreenController;
    final fg = Theme.of(context).textTheme.titleMedium?.color ?? Colors.white;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Obx(() {
        if (con.isArtistContentFetced.isFalse) {
          return Stack(children: [
            const Center(child: LoadingIndicator()),
            _BackButton(top: MediaQuery.of(context).padding.top),
          ]);
        }
        final data = con.artistData;
        final thumbs = (data['thumbnails'] as List?) ?? const [];
        final heroUrl = thumbs.isNotEmpty ? thumbs.last['url'] as String : '';
        List<T> contentOf<T>(String key) =>
            List<T>.from((data[key]?['content'] as List?) ?? const []);
        final songs = contentOf<MediaItem>("Songs");
        final albums = contentOf<dynamic>("Albums");
        final singles = contentOf<dynamic>("Singles");
        final videos = contentOf<MediaItem>("Videos");
        final artist = con.artist_;
        final playerController = Get.find<PlayerController>();

        void playAll({bool shuffle = false}) {
          if (songs.isEmpty) {
            final radioId = artist.radioId;
            if (radioId != null) {
              playerController.startRadio(null, playlistid: radioId);
            }
            return;
          }
          final list = List<MediaItem>.from(songs);
          if (shuffle) list.shuffle();
          playerController.playPlayListSong(list, 0,
              playfrom:
                  PlaylingFrom(type: PlaylingFromType.ARTIST, name: artist.name));
        }

        return CustomScrollView(
          slivers: [
            // Hero photo with the artist name on it
            SliverToBoxAdapter(
              child: SizedBox(
                height: width * 0.92,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (heroUrl.isNotEmpty)
                      CachedNetworkImage(imageUrl: heroUrl, fit: BoxFit.cover)
                    else
                      ImageWidget(artist: artist, size: width),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0, 0.35, 0.75, 1],
                          colors: [
                            Colors.black.withOpacity(0.35),
                            Colors.transparent,
                            Colors.black.withOpacity(0.25),
                            Theme.of(context).canvasColor,
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 10,
                      child: Text(
                        artist.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: headerFont(size: 56, color: Colors.white).copyWith(
                            shadows: const [
                              Shadow(color: Colors.black54, blurRadius: 20)
                            ]),
                      ).animate().fadeIn(duration: 500.ms).slideX(
                          begin: -0.08, end: 0, curve: Curves.easeOutCubic),
                    ),
                    _BackButton(top: MediaQuery.of(context).padding.top),
                  ],
                ),
              ),
            ),
            // Listeners + actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data['subscribers'] != null &&
                        data['subscribers'].toString() != '0')
                      Text("${data['subscribers']} subscribers",
                          style: TextStyle(
                              color: fg.withOpacity(0.6), fontSize: 13.5)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Obx(() => _FollowButton(
                              following: con.isAddedToLibrary.isTrue,
                              onTap: () {
                                final add = con.isAddedToLibrary.isFalse;
                                con.addNremoveFromLibrary(add: add).then((ok) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      snackbar(
                                          context,
                                          ok
                                              ? add
                                                  ? "artistBookmarkAddAlert".tr
                                                  : "artistBookmarkRemoveAlert"
                                                      .tr
                                              : "operationFailed".tr,
                                          size: SanckBarSize.MEDIUM));
                                });
                              },
                            )),
                        const SizedBox(width: 6),
                        IconButton(
                          tooltip: "Radio",
                          icon: Icon(Icons.sensors_rounded,
                              color: fg.withOpacity(0.8)),
                          onPressed: artist.radioId == null
                              ? null
                              : () => playerController.startRadio(null,
                                  playlistid: artist.radioId),
                        ),
                        IconButton(
                          tooltip: "share".tr,
                          icon: Icon(Icons.ios_share_rounded,
                              size: 21, color: fg.withOpacity(0.8)),
                          onPressed: () => Share.share(
                              "https://music.youtube.com/channel/${artist.browseId}"),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: "shuffle".tr,
                          iconSize: 27,
                          icon: Icon(Icons.shuffle_rounded, color: fg),
                          onPressed: () => playAll(shuffle: true),
                        ),
                        const SizedBox(width: 6),
                        Material(
                          color: kAccent,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: playAll,
                            child: const SizedBox(
                              width: 54,
                              height: 54,
                              child: Icon(Icons.play_arrow_rounded,
                                  size: 34, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (songs.isNotEmpty) ...[
              _Header("Popular",
                  onSeeAll: () => _openSection(context, 1, "songs".tr)),
              SliverList.builder(
                itemCount: songs.length.clamp(0, 5),
                itemBuilder: (context, i) => _PopularRow(
                  index: i,
                  song: songs[i],
                  onTap: () => playerController.playPlayListSong(
                      List<MediaItem>.from(songs), i,
                      playfrom: PlaylingFrom(
                          type: PlaylingFromType.ARTIST, name: artist.name)),
                ),
              ),
            ],
            if (albums.isNotEmpty) ...[
              _Header("albums".tr,
                  onSeeAll: () => _openSection(context, 3, "albums".tr)),
              _CardRow(items: albums),
            ],
            if (singles.isNotEmpty) ...[
              _Header("singles".tr,
                  onSeeAll: () => _openSection(context, 4, "singles".tr)),
              _CardRow(items: singles),
            ],
            if (videos.isNotEmpty) ...[
              _Header("videos".tr,
                  onSeeAll: () => _openSection(context, 2, "videos".tr)),
              _CardRow(items: videos),
            ],
            if (data['description'] != null) ...[
              const _Header("About"),
              SliverToBoxAdapter(
                child: _AboutCard(
                    imageUrl: heroUrl,
                    views: data['views'],
                    description: data['description'].toString()),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 200)),
          ],
        );
      }),
    );
  }

  /// Opens the full list for one section (Songs, Videos, Albums, Singles).
  void _openSection(BuildContext context, int index, String title) {
    final con = artistScreenController;
    const names = ["About", "Songs", "Videos", "Albums", "Singles"];
    con.onDestinationSelected(index);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 8),
            Row(children: [
              IconButton(
                tooltip: "back".tr,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Text("${con.artist_.name} · $title",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: headerFont(
                        size: 28,
                        color: Theme.of(context).textTheme.titleMedium?.color)),
              ),
            ]),
            Expanded(
              child: Obx(() {
                final item = names[index];
                if (con.isSeparatedArtistContentFetced.isFalse) {
                  return const Center(child: LoadingIndicator());
                }
                return Padding(
                  padding: const EdgeInsets.only(left: 12, right: 4),
                  child: SeparateTabItemWidget(
                    artistControllerTag: tag,
                    hideTitle: true,
                    isResultWidget: false,
                    items: con.sepataredContent.containsKey(item)
                        ? con.sepataredContent[item]['results']
                        : [],
                    title: item,
                    scrollController: [
                      null,
                      con.songScrollController,
                      con.videoScrollController,
                      con.albumScrollController,
                      con.singlesScrollController
                    ][index],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    ));
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.top});
  final double top;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top + 6,
      left: 6,
      child: Material(
        color: Colors.black.withOpacity(0.35),
        shape: const CircleBorder(),
        child: IconButton(
          tooltip: "back".tr,
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: Colors.white),
          onPressed: () =>
              Get.nestedKey(ScreenNavigationSetup.id)!.currentState!.pop(),
        ),
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({required this.following, required this.onTap});
  final bool following;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).textTheme.titleMedium?.color ?? Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: fg.withOpacity(following ? 0.9 : 0.45)),
        ),
        child: Text(following ? "Following" : "Follow",
            style: TextStyle(
                color: fg, fontSize: 13.5, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.title, {this.onSeeAll});
  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).textTheme.titleMedium?.color ?? Colors.white;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 26, 8, 10),
        child: Row(
          children: [
            Expanded(
              child: Text(title, style: sectionFont(color: fg)),
            ),
            if (onSeeAll != null)
              TextButton(
                onPressed: onSeeAll,
                child: Text("See all",
                    style: TextStyle(
                        color: fg.withOpacity(0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Numbered song row: index, cover with play badge, title, plays, menu.
class _PopularRow extends StatelessWidget {
  const _PopularRow(
      {required this.index, required this.song, required this.onTap});
  final int index;
  final MediaItem song;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).textTheme.titleMedium?.color ?? Colors.white;
    final sub = song.extras?['views'] ?? song.album ?? song.artist ?? '';
    return PressScale(
      scale: 0.98,
      child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 7, 4, 7),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: Text("${index + 1}",
                  style: TextStyle(
                      color: fg.withOpacity(0.6),
                      fontSize: 15,
                      fontWeight: FontWeight.w500)),
            ),
            const SizedBox(width: 8),
            Stack(children: [
              PlayBadgeCover(child: ImageWidget(song: song, size: 52)),
              NowPlayingOverlay(songId: song.id, size: 52),
            ]),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: fg,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(sub.toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(color: fg.withOpacity(0.6), fontSize: 13)),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.more_horiz_rounded, color: fg.withOpacity(0.6)),
              onPressed: () => showSongMenu(song),
            ),
          ],
        ),
      ),
    ));
  }
}

/// Opens the standard song options sheet.
void showSongMenu(MediaItem song) {
  final playerController = Get.find<PlayerController>();
  showModalBottomSheet(
    constraints: const BoxConstraints(maxWidth: 500),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(10.0)),
    ),
    isScrollControlled: true,
    context: playerController.homeScaffoldkey.currentState!.context,
    barrierColor: Colors.transparent.withAlpha(100),
    builder: (context) => SongInfoBottomSheet(song),
  ).whenComplete(() => Get.delete<SongInfoController>());
}

/// Cover with a small translucent play circle in the middle.
class PlayBadgeCover extends StatelessWidget {
  const PlayBadgeCover({super.key, required this.child, this.badge = 24});
  final Widget child;
  final double badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        child,
        Container(
          width: badge,
          height: badge,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.45),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.play_arrow_rounded,
              size: badge * 0.72, color: Colors.white),
        ),
      ],
    );
  }
}

class _CardRow extends StatelessWidget {
  const _CardRow({required this.items});
  final List<dynamic> items;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 200,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) => ContentListItem(content: items[i]),
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard(
      {required this.imageUrl, required this.description, this.views});
  final String imageUrl;
  final String description;
  final String? views;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (ctx) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            builder: (ctx, sc) => SingleChildScrollView(
              controller: sc,
              padding: const EdgeInsets.all(20),
              child: Text(description,
                  style: const TextStyle(fontSize: 15, height: 1.5)),
            ),
          ),
        ),
        child: Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl.isNotEmpty)
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      alignment: const Alignment(0, -0.4)),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (views != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(views!,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    Text(description,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.color
                                ?.withOpacity(0.75))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
