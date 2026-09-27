import 'package:audio_service/audio_service.dart' show MediaItem;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'motion.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';

import '../../models/playlist.dart';
import '../player/player_controller.dart';
import '../screens/Settings/settings_screen_controller.dart';
import 'add_to_playlist.dart';
import '../utils/brand.dart';
import 'image_widget.dart';
import 'snackbar.dart';
import 'songinfo_bottom_sheet.dart';

class SongListTile extends StatelessWidget with RemoveSongFromPlaylistMixin {
  const SongListTile(
      {super.key,
      this.onTap,
      required this.song,
      this.playlist,
      this.isPlaylistOrAlbum = false,
      this.thumbReplacementWithIndex = false,
      this.index});
  final Playlist? playlist;
  final MediaItem song;
  final VoidCallback? onTap;
  final bool isPlaylistOrAlbum;

  /// Valid for Album songs
  final bool thumbReplacementWithIndex;
  final int? index;

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();
    return Listener(
        onPointerDown: (PointerDownEvent event) {
          if (event.buttons == kSecondaryMouseButton) {
            //show songinfobotomsheet
            showModalBottomSheet(
              constraints: const BoxConstraints(maxWidth: 500),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(10.0)),
              ),
              isScrollControlled: true,
              context: playerController.homeScaffoldkey.currentState!.context,
              barrierColor: Colors.transparent.withAlpha(100),
              builder: (context) => SongInfoBottomSheet(
                song,
                playlist: playlist,
              ),
            ).whenComplete(() => Get.delete<SongInfoController>());
          }
        },
        child: Slidable(
          enabled:
              Get.find<SettingsScreenController>().slidableActionEnabled.isTrue,
          startActionPane: ActionPane(motion: const DrawerMotion(), children: [
            SlidableAction(
              onPressed: (context) {
                showDialog(
                  context: context,
                  builder: (context) => AddToPlaylist([song]),
                ).whenComplete(() => Get.delete<AddToPlaylistController>());
              },
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Theme.of(context).textTheme.titleMedium!.color,
              icon: Icons.playlist_add,
              //label: 'Add to playlist',
            ),
            if (playlist != null && !playlist!.isCloudPlaylist)
              SlidableAction(
                onPressed: (context) {
                  removeSongFromPlaylist(song, playlist!);
                },
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).textTheme.titleMedium!.color,
                icon: Icons.delete,
                //label: 'delete',
              ),
          ]),
          endActionPane: ActionPane(motion: const DrawerMotion(), children: [
            SlidableAction(
              onPressed: (context) {
                playerController.enqueueSong(song).whenComplete(() {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(snackbar(
                      context, "songEnqueueAlert".tr,
                      size: SanckBarSize.MEDIUM));
                });
              },
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Theme.of(context).textTheme.titleMedium!.color,
              icon: Icons.merge,
              //label: 'Enqueue',
            ),
            SlidableAction(
              onPressed: (context) {
                playerController.playNext(song);
                ScaffoldMessenger.of(context).showSnackBar(snackbar(
                    context, "${"playnextMsg".tr} ${(song).title}",
                    size: SanckBarSize.BIG));
              },
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Theme.of(context).textTheme.titleMedium!.color,
              icon: Icons.next_plan_outlined,
              //label: 'Play Next',
            ),
          ]),
          child: _ModernSongRow(
            song: song,
            onTap: onTap,
            onMenu: () {
              showModalBottomSheet(
                constraints: const BoxConstraints(maxWidth: 500),
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(10.0)),
                ),
                isScrollControlled: true,
                context: playerController.homeScaffoldkey.currentState!.context,
                barrierColor: Colors.transparent.withAlpha(100),
                builder: (context) => SongInfoBottomSheet(
                  song,
                  playlist: playlist,
                ),
              ).whenComplete(() => Get.delete<SongInfoController>());
            },
            index: thumbReplacementWithIndex ? index : null,
          ),
        ));
  }
}

/// Modern song row: cover with a play badge (or track number), bold title,
/// "artist · length" subtitle and a menu button. The playing song is green.
class _ModernSongRow extends StatelessWidget {
  const _ModernSongRow(
      {required this.song, this.onTap, required this.onMenu, this.index});
  final MediaItem song;
  final VoidCallback? onTap;
  final VoidCallback onMenu;
  final int? index;

  static const _accent = kAccent;

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();
    final fg = Theme.of(context).textTheme.titleMedium?.color ?? Colors.white;
    final length = song.extras?['length'];
    final sub = [
      if ((song.artist ?? '').isNotEmpty) song.artist!,
      if (length != null && length.toString().isNotEmpty) length.toString(),
    ].join(' · ');

    return PressScale(
      scale: 0.98,
      child: InkWell(
      onTap: onTap,
      onLongPress: onMenu,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Obx(() {
          final isCurrent = playerController.currentSong.value?.id == song.id;
          final loading = isCurrent &&
              playerController.buttonState.value == PlayButtonState.loading;
          const spinner = SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white));
          return Row(
            children: [
              if (index != null)
                SizedBox(
                  width: 34,
                  child: Center(
                    child: loading
                        ? spinner
                        : isCurrent
                            ? const Icon(Icons.equalizer_rounded,
                                color: _accent, size: 20)
                            : Text("$index",
                                style: TextStyle(
                                    color: fg.withOpacity(0.6),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500)),
                  ),
                )
              else
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ImageWidget(size: 54, song: song),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(isCurrent ? 0.6 : 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: loading
                          ? const Center(child: spinner)
                          : Icon(
                              isCurrent
                                  ? Icons.equalizer_rounded
                                  : Icons.play_arrow_rounded,
                              size: 18,
                              color: isCurrent ? _accent : Colors.white),
                    ),
                  ],
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: isCurrent ? _accent : fg,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2)),
                    const SizedBox(height: 3),
                    Text(sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: fg.withOpacity(0.6), fontSize: 13)),
                  ],
                ),
              ),
              IconButton(
                splashRadius: 20,
                tooltip: "More",
                onPressed: onMenu,
                icon:
                    Icon(Icons.more_horiz_rounded, color: fg.withOpacity(0.6)),
              ),
            ],
          );
        }),
      ),
    ));
  }
}
