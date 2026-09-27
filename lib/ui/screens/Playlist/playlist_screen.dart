import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../utils/brand.dart';
import '../../widgets/motion.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:widget_marquee/widget_marquee.dart';

import 'package:zuno/models/playling_from.dart';
import 'package:zuno/models/thumbnail.dart';
import 'package:zuno/ui/widgets/playlist_album_scroll_behaviour.dart';
import '../../../services/downloader.dart';
import '../../navigator.dart';
import '../../player/player_controller.dart';
import '../../widgets/create_playlist_dialog.dart';
import '../../widgets/image_widget.dart';
import '../../widgets/loader.dart';
import '../../widgets/playlist_export_dialog.dart';
import '../../widgets/snackbar.dart';
import '../../widgets/song_list_tile.dart';
import '../../widgets/songinfo_bottom_sheet.dart';
import '../../widgets/sort_widget.dart';
import '../Library/library_controller.dart';
import 'playlist_screen_controller.dart';

class PlaylistScreen extends StatelessWidget {
  const PlaylistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tag = key.hashCode.toString();
    final playlistController =
        (Get.isRegistered<PlaylistScreenController>(tag: tag))
            ? Get.find<PlaylistScreenController>(tag: tag)
            : Get.put(PlaylistScreenController(), tag: tag);
    final size = MediaQuery.of(context).size;
    final playerController = Get.find<PlayerController>();
    final landscape = size.width > size.height;
    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          final scrollOffset = scrollInfo.metrics.pixels;

          if (landscape) {
            playlistController.scrollOffset.value = 0;
          } else {
            playlistController.scrollOffset.value = scrollOffset;
          }
          if (scrollOffset > 270 || (landscape && scrollOffset > 215)) {
            playlistController.appBarTitleVisible.value = true;
          } else {
            playlistController.appBarTitleVisible.value = false;
          }
          return true;
        },
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 10,
                      left: 10,
                      right: 10),
                  height: 80,
                  child: Center(
                    child: Row(
                      children: [
                        SizedBox(
                          width: 50,
                          child: IconButton(
                              tooltip: "back".tr,
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              icon: const Icon(Icons.arrow_back_ios)),
                        ),
                        Expanded(
                          child: Obx(
                            () => Marquee(
                              delay: const Duration(milliseconds: 300),
                              duration: const Duration(seconds: 5),
                              id: "${playlistController.playlist.value.title.hashCode.toString()}_appbar",
                              child: Text(
                                playlistController.appBarTitleVisible.isTrue
                                    ? playlistController.playlist.value.title
                                    : "",
                                maxLines: 1,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                          ),
                        ),
                        if (!playlistController
                                .playlist.value.isCloudPlaylist &&
                            playlistController.isDefaultPlaylist.isFalse)
                          SizedBox(
                            width: 50,
                            child: IconButton(
                                onPressed: () {
                                  showModalBottomSheet(
                                    constraints:
                                        const BoxConstraints(maxWidth: 500),
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(10.0)),
                                    ),
                                    context: Get.find<PlayerController>()
                                        .homeScaffoldkey
                                        .currentState!
                                        .context,
                                    barrierColor:
                                        Colors.transparent.withAlpha(100),
                                    builder: (context) => SizedBox(
                                      height: 140,
                                      child: Column(
                                        children: [
                                          ListTile(
                                            leading: const Icon(Icons.edit),
                                            title: Text("renamePlaylist".tr),
                                            onTap: () {
                                              Navigator.of(context).pop();
                                              showDialog(
                                                context: context,
                                                builder: (context) =>
                                                    CreateNRenamePlaylistPopup(
                                                        renamePlaylist: true,
                                                        playlist:
                                                            playlistController
                                                                .playlist
                                                                .value),
                                              );
                                            },
                                          ),
                                          ListTile(
                                            leading: const Icon(Icons.delete),
                                            title: Text("removePlaylist".tr),
                                            onTap: () {
                                              Navigator.of(context).pop();
                                              playlistController
                                                  .addNremoveFromLibrary(
                                                      playlistController
                                                          .playlist.value,
                                                      add: false)
                                                  .then((value) {
                                                Get.nestedKey(
                                                        ScreenNavigationSetup
                                                            .id)!
                                                    .currentState!
                                                    .pop();
                                                ScaffoldMessenger.of(
                                                        Get.context!)
                                                    .showSnackBar(snackbar(
                                                        Get.context!,
                                                        value
                                                            ? "playlistRemovedAlert"
                                                                .tr
                                                            : "operationFailed"
                                                                .tr,
                                                        size: SanckBarSize
                                                            .MEDIUM));
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.more_vert)),
                          )
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 800,
                      ),
                      child: Obx(
                        () => ScrollConfiguration(
                          behavior: PlaylistAlbumScrollBehaviour(),
                          child: ListView.builder(
                            addRepaintBoundaries: false,
                            padding: EdgeInsets.only(
                              top: playlistController.isSearchingOn.isTrue
                                  ? 0
                                  : 4,
                              bottom: 200,
                            ),
                            itemCount: playlistController.songList.isEmpty ||
                                    playlistController.isContentFetched.isFalse
                                ? 4
                                : playlistController.songList.length + 3,
                            itemBuilder: (_, index) {
                              if (index == 1) {
                                void playAll({bool shuffle = false}) {
                                  final songs = List<MediaItem>.from(
                                      playlistController.songList);
                                  if (songs.isEmpty) return;
                                  if (shuffle) songs.shuffle();
                                  playerController.playPlayListSong(songs, 0,
                                      playfrom: PlaylingFrom(
                                          name: playlistController
                                              .playlist.value.title,
                                          type: PlaylingFromType.PLAYLIST));
                                }

                                return Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(8, 10, 16, 6),
                                  child: SizedBox(
                                    height: 56,
                                    child: Row(children: [
                                      Expanded(
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: [
                                              // Bookmark button
                                              Obx(() => (playlistController
                                                          .playlist
                                                          .value
                                                          .isPipedPlaylist ||
                                                      !playlistController
                                                          .playlist
                                                          .value
                                                          .isCloudPlaylist)
                                                  ? const SizedBox.shrink()
                                                  : IconButton(
                                                      tooltip: playlistController
                                                              .isAddedToLibrary
                                                              .isFalse
                                                          ? "addToLibrary".tr
                                                          : "removeFromLibrary"
                                                              .tr,
                                                      splashRadius: 10,
                                                      onPressed: () {
                                                        final add =
                                                            playlistController
                                                                .isAddedToLibrary
                                                                .isFalse;
                                                        playlistController
                                                            .addNremoveFromLibrary(
                                                                playlistController
                                                                    .playlist
                                                                    .value,
                                                                add: add)
                                                            .then((value) {
                                                          if (!context
                                                              .mounted) {
                                                            return;
                                                          }

                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                              snackbar(
                                                                  context,
                                                                  value
                                                                      ? add
                                                                          ? "playlistBookmarkAddAlert"
                                                                              .tr
                                                                          : "listBookmarkRemoveAlert"
                                                                              .tr
                                                                      : "operationFailed"
                                                                          .tr,
                                                                  size: SanckBarSize
                                                                      .MEDIUM));
                                                        });
                                                      },
                                                      icon: Icon(playlistController
                                                              .isAddedToLibrary
                                                              .isFalse
                                                          ? Icons.bookmark_add
                                                          : Icons
                                                              .bookmark_added))),
                                              // Enqueue button
                                              IconButton(
                                                  tooltip: "enqueueSongs".tr,
                                                  onPressed: () {
                                                    Get.find<PlayerController>()
                                                        .enqueueSongList(
                                                            playlistController
                                                                .songList
                                                                .toList())
                                                        .whenComplete(() {
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(snackbar(
                                                                context,
                                                                "songEnqueueAlert"
                                                                    .tr,
                                                                size: SanckBarSize
                                                                    .MEDIUM));
                                                      }
                                                    });
                                                  },
                                                  icon: Icon(
                                                    Icons.merge,
                                                    color: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium!
                                                        .color,
                                                  )),

                                              // Download button
                                              GetX<Downloader>(
                                                  builder: (controller) {
                                                final id = playlistController
                                                    .playlist.value.playlistId;
                                                return IconButton(
                                                  tooltip:
                                                      "downloadPlaylist".tr,
                                                  onPressed: () {
                                                    if (playlistController
                                                        .isDownloaded.isTrue) {
                                                      return;
                                                    }
                                                    controller.downloadPlaylist(
                                                        id,
                                                        playlistController
                                                            .songList
                                                            .toList());
                                                  },
                                                  icon: playlistController
                                                          .isDownloaded.isTrue
                                                      ? const Icon(
                                                          Icons.download_done)
                                                      : controller.playlistQueue
                                                                  .containsKey(
                                                                      id) &&
                                                              controller
                                                                      .currentPlaylistId
                                                                      .toString() ==
                                                                  id
                                                          ? Stack(
                                                              children: [
                                                                Center(
                                                                    child: Text(
                                                                        "${controller.playlistDownloadingProgress.value}/${playlistController.songList.length}",
                                                                        style: Theme.of(context)
                                                                            .textTheme
                                                                            .titleMedium!
                                                                            .copyWith(
                                                                                fontSize: 10,
                                                                                fontWeight: FontWeight.bold))),
                                                                const Center(
                                                                    child:
                                                                        LoadingIndicator(
                                                                  dimension: 30,
                                                                ))
                                                              ],
                                                            )
                                                          : controller
                                                                  .playlistQueue
                                                                  .containsKey(
                                                                      id)
                                                              ? const Stack(
                                                                  children: [
                                                                    Center(
                                                                        child:
                                                                            Icon(
                                                                      Icons
                                                                          .hourglass_bottom,
                                                                      size: 20,
                                                                    )),
                                                                    Center(
                                                                        child:
                                                                            LoadingIndicator(
                                                                      dimension:
                                                                          30,
                                                                    ))
                                                                  ],
                                                                )
                                                              : const Icon(Icons
                                                                  .download),
                                                );
                                              }),

                                              if (playlistController
                                                  .isAddedToLibrary.isTrue)
                                                IconButton(
                                                    tooltip:
                                                        "syncPlaylistSongs".tr,
                                                    onPressed: () {
                                                      playlistController
                                                          .syncPlaylistSongs();
                                                    },
                                                    icon: const Icon(
                                                        Icons.cloud_sync)),
                                              if (playlistController.playlist
                                                  .value.isPipedPlaylist)
                                                IconButton(
                                                    tooltip:
                                                        "blacklistPipedPlaylist"
                                                            .tr,
                                                    icon: const Icon(
                                                      Icons.block,
                                                      size: 20,
                                                    ),
                                                    splashRadius: 10,
                                                    onPressed: () {
                                                      Get.nestedKey(
                                                              ScreenNavigationSetup
                                                                  .id)!
                                                          .currentState!
                                                          .pop();
                                                      Get.find<
                                                              LibraryPlaylistsController>()
                                                          .blacklistPipedPlaylist(
                                                              playlistController
                                                                  .playlist
                                                                  .value);
                                                      ScaffoldMessenger.of(
                                                              Get.context!)
                                                          .showSnackBar(snackbar(
                                                              Get.context!,
                                                              "playlistBlacklistAlert"
                                                                  .tr,
                                                              size: SanckBarSize
                                                                  .MEDIUM));
                                                    }),
                                              if (playlistController.playlist
                                                  .value.isCloudPlaylist)
                                                IconButton(
                                                  tooltip: "sharePlaylist".tr,
                                                  visualDensity:
                                                      const VisualDensity(
                                                    vertical: -3,
                                                  ),
                                                  splashRadius: 10,
                                                  onPressed: () {
                                                    final content =
                                                        playlistController
                                                            .playlist.value;
                                                    if (content
                                                        .isPipedPlaylist) {
                                                      Share.share(
                                                          "https://piped.video/playlist?list=${content.playlistId}");
                                                    } else {
                                                      final isPlaylistIdPrefixAvlbl =
                                                          content.playlistId
                                                                  .substring(
                                                                      0, 2) ==
                                                              "VL";
                                                      String url =
                                                          "https://youtube.com/playlist?list=";

                                                      url = isPlaylistIdPrefixAvlbl
                                                          ? url +
                                                              content.playlistId
                                                                  .substring(2)
                                                          : url +
                                                              content
                                                                  .playlistId;
                                                      Share.share(url);
                                                    }
                                                  },
                                                  icon: const Icon(
                                                    Icons.share,
                                                    size: 20,
                                                  ),
                                                ),
                                              // Export button - opens export dialog
                                              IconButton(
                                                onPressed: () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (dialogContext) =>
                                                        PlaylistExportDialog(
                                                      controller:
                                                          playlistController,
                                                      parentContext: context,
                                                    ),
                                                  );
                                                },
                                                icon: const Icon(
                                                    Icons.file_upload),
                                                tooltip: "exportPlaylist".tr,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: "shuffle".tr,
                                        iconSize: 26,
                                        onPressed: () => playAll(shuffle: true),
                                        icon: const Icon(Icons.shuffle_rounded),
                                      ),
                                      const SizedBox(width: 6),
                                      Material(
                                        color: Colors.white,
                                        shape: const CircleBorder(),
                                        child: InkWell(
                                          customBorder: const CircleBorder(),
                                          onTap: playAll,
                                          child: const SizedBox(
                                            width: 52,
                                            height: 52,
                                            child: Icon(
                                                Icons.play_arrow_rounded,
                                                size: 32,
                                                color: Colors.black),
                                          ),
                                        ),
                                      ),
                                    ]),
                                  ),
                                );
                              } else if (index == 0) {
                                final playlist =
                                    playlistController.playlist.value;
                                final description = playlist.description;
                                final count =
                                    playlistController.songList.length;
                                final muted = Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .color!
                                    .withOpacity(0.6);

                                return AnimatedBuilder(
                                  animation:
                                      playlistController.animationController,
                                  builder: (context, child) {
                                    // header collapses while searching
                                    return SizedBox(
                                      height: playlistController
                                              .heightAnimation.value /
                                          75 *
                                          (description != null ? 170 : 140),
                                      child: Opacity(
                                        opacity: playlistController
                                            .scaleAnimation.value
                                            .clamp(0.0, 1.0),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: SingleChildScrollView(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    padding:
                                        const EdgeInsets.fromLTRB(16, 6, 16, 0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            ImageWidget(
                                                playlist: playlist, size: 112),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    playlist.title,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: headerFont(
                                                        size: 28,
                                                        color: Theme.of(context)
                                                            .textTheme
                                                            .titleMedium!
                                                            .color),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    "${"playlist".tr.capitalizeFirst} · $count ${"songs".tr.toLowerCase()}",
                                                    style: TextStyle(
                                                        fontSize: 13,
                                                        color: muted),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (description != null)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 12),
                                            child: Text(
                                              description,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  fontSize: 13.5,
                                                  height: 1.35,
                                                  color: muted),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              } else if (index == 2) {
                                return SizedBox(
                                    height:
                                        playlistController.isSearchingOn.isTrue
                                            ? 60
                                            : 40,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          left: 15.0, right: 10),
                                      child: Obx(
                                        () => SortWidget(
                                          tag: playlistController
                                              .playlist.value.playlistId,
                                          screenController: playlistController,
                                          isSearchFeatureRequired: true,
                                          isPlaylistRearrageFeatureRequired: !playlistController
                                                  .playlist
                                                  .value
                                                  .isCloudPlaylist &&
                                              playlistController.playlist.value
                                                      .playlistId !=
                                                  "LIBRP" &&
                                              playlistController.playlist.value
                                                      .playlistId !=
                                                  "SongDownloads" &&
                                              playlistController.playlist.value
                                                      .playlistId !=
                                                  "SongsCache",
                                          isSongDeletetioFeatureRequired:
                                              !playlistController.playlist.value
                                                  .isCloudPlaylist,
                                          itemCountTitle:
                                              "${playlistController.songList.length}",
                                          itemIcon: Icons.music_note,
                                          titleLeftPadding: 9,
                                          requiredSortTypes:
                                              buildSortTypeSet(false, true),
                                          onSort: playlistController.onSort,
                                          onSearch: playlistController.onSearch,
                                          onSearchClose:
                                              playlistController.onSearchClose,
                                          onSearchStart:
                                              playlistController.onSearchStart,
                                          startAdditionalOperation:
                                              playlistController
                                                  .startAdditionalOperation,
                                          selectAll:
                                              playlistController.selectAll,
                                          performAdditionalOperation:
                                              playlistController
                                                  .performAdditionalOperation,
                                          cancelAdditionalOperation:
                                              playlistController
                                                  .cancelAdditionalOperation,
                                        ),
                                      ),
                                    ));
                              } else if (playlistController
                                      .isContentFetched.isFalse ||
                                  playlistController.songList.isEmpty) {
                                return SizedBox(
                                  height: 300,
                                  child: Center(
                                    child: playlistController
                                            .isContentFetched.isFalse
                                        ? const LoadingIndicator()
                                        : Text(
                                            "emptyPlaylist".tr,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall,
                                          ),
                                  ),
                                );
                              }

                              return Padding(
                                padding:
                                    const EdgeInsets.only(left: 20.0, right: 5),
                                child: SongListTile(
                                  onTap: () {
                                    playerController.playPlayListSong(
                                        List<MediaItem>.from(
                                            playlistController.songList),
                                        index - 3,
                                        playfrom: PlaylingFrom(
                                            name: playlistController
                                                .playlist.value.title,
                                            type: PlaylingFromType.PLAYLIST));
                                  },
                                  song: playlistController.songList[index - 3],
                                  isPlaylistOrAlbum: true,
                                  playlist: playlistController.playlist.value,
                                ),
                              ).appear(index: index - 3);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future openBottomSheet(BuildContext context, MediaItem song) {
    return showModalBottomSheet(
      constraints: const BoxConstraints(maxWidth: 500),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10.0)),
      ),
      isScrollControlled: true,
      context: context,
      barrierColor: Colors.transparent.withAlpha(100),
      builder: (context) => SongInfoBottomSheet(song),
    ).whenComplete(() => Get.delete<SongInfoController>());
  }
}
