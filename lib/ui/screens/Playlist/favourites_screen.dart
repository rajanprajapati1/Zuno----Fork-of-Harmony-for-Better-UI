import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:zuno/ui/utils/brand.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import 'package:zuno/models/media_Item_builder.dart';
import 'package:zuno/ui/player/player_controller.dart';
import 'package:zuno/ui/widgets/page_title.dart';
import 'package:zuno/ui/widgets/songinfo_bottom_sheet.dart';

/// A standalone Favourites screen that reads directly from the LIBFAV Hive box.
/// Does NOT rely on the full PlaylistScreenController to stay lightweight.
class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  List<MediaItem> _songs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final box = await Hive.openBox('LIBFAV');
    final songs = box.values
        .map<MediaItem?>((e) => MediaItemBuilder.fromJson(e))
        .whereType<MediaItem>()
        .toList();
    if (mounted) {
      setState(() {
        _songs = songs;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildList(context),
    );
  }

  /// "Liked Songs" hero: gradient cover, title, count and play controls.
  Widget _buildHeader(BuildContext context) {
    final playerController = Get.find<PlayerController>();
    final count = _songs.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageTitle('Favourites'),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 116,
                height: 116,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4A1FB8), Color(0xFF8E8EE5)],
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black45,
                        blurRadius: 18,
                        offset: Offset(0, 8)),
                  ],
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/nav_favourites.svg',
                    width: 46,
                    height: 46,
                    colorFilter: const ColorFilter.mode(
                        Colors.white, BlendMode.srcIn),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PLAYLIST',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                            color: Colors.white.withOpacity(0.5))),
                    const SizedBox(height: 4),
                    Text('Liked Songs',
                        style: headerFont(
                            size: 32,
                            color: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.color)),
                    const SizedBox(height: 6),
                    Text('$count song${count == 1 ? '' : 's'}',
                        style: TextStyle(
                            fontSize: 13.5,
                            color: Colors.white.withOpacity(0.55))),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (count > 0)
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Shuffle',
                  icon: Icon(Icons.shuffle_rounded,
                      color: Colors.white.withOpacity(0.7)),
                  onPressed: () => playerController.playPlayListSong(
                      (List<MediaItem>.from(_songs)..shuffle()), 0),
                ),
                const Spacer(),
                Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () =>
                        playerController.playPlayListSong(_songs, 0),
                    child: const SizedBox(
                      width: 52,
                      height: 52,
                      child: Icon(Icons.play_arrow_rounded,
                          size: 32, color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 70),
      child: Column(
        children: [
          Icon(Icons.favorite_border_rounded,
              size: 40, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 14),
          Text('Songs you like will appear here',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.85))),
          const SizedBox(height: 6),
          Text('Tap the heart on any song to save it.',
              style: TextStyle(
                  fontSize: 13.5, color: Colors.white.withOpacity(0.45))),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    final playerController = Get.find<PlayerController>();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(context)),
        if (_songs.isEmpty) SliverToBoxAdapter(child: _buildEmpty(context)),

        // ── Song list ───────────────────────────────────────────────────
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final song = _songs[index];
              return _SongTile(
                song: song,
                index: index,
                songs: _songs,
                playerController: playerController,
                onRemoved: () {
                  setState(() {
                    _songs.removeAt(index);
                  });
                },
              );
            },
            childCount: _songs.length,
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 200)),
      ],
    );
  }
}

class _SongTile extends StatelessWidget {
  final MediaItem song;
  final int index;
  final List<MediaItem> songs;
  final PlayerController playerController;
  final VoidCallback onRemoved;

  const _SongTile({
    required this.song,
    required this.index,
    required this.songs,
    required this.playerController,
    required this.onRemoved,
  });

  @override
  Widget build(BuildContext context) {
    final artistStr = (song.extras?['artists'] as List?)
            ?.map((a) => a['name'])
            .join(', ') ??
        '';

    return InkWell(
      borderRadius: BorderRadius.zero,
      onTap: () {
        playerController.playPlayListSong(
          songs,
          index,
        );
      },
      onLongPress: () {
        final scaffoldCtx =
            playerController.homeScaffoldkey.currentContext ?? context;
        showModalBottomSheet(
          context: scaffoldCtx,
          isScrollControlled: true,
          useRootNavigator: true,
          backgroundColor: Colors.transparent,
          builder: (_) => SongInfoBottomSheet(song),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.zero,
              child: SizedBox(
                width: 50,
                height: 50,
                child: song.artUri != null
                    ? CachedNetworkImage(
                        imageUrl: song.artUri.toString(),
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _thumbPlaceholder(),
                      )
                    : _thumbPlaceholder(),
              ),
            ),
            const SizedBox(width: 12),

            // Title + Artist
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                  ),
                  if (artistStr.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      artistStr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 13,
                          ),
                    ),
                  ],
                ],
              ),
            ),

            // More button
            IconButton(
              icon: Icon(Icons.more_vert,
                  size: 18, color: Colors.white.withOpacity(0.4)),
              onPressed: () {
                final scaffoldCtx =
                    playerController.homeScaffoldkey.currentContext ?? context;
                showModalBottomSheet(
                  context: scaffoldCtx,
                  isScrollControlled: true,
                  useRootNavigator: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => SongInfoBottomSheet(song),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbPlaceholder() => Container(
        color: Colors.white.withOpacity(0.06),
        child: const Icon(Icons.music_note, color: Colors.white30, size: 20),
      );
}
