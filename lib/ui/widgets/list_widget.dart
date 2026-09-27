import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:zuno/models/album.dart';
import '../../models/artist.dart';
import '../../models/playling_from.dart';
import '../../models/playlist.dart';
import '../navigator.dart';
import '../player/player_controller.dart';
import 'image_widget.dart';
import 'song_list_tile.dart';
import 'songinfo_bottom_sheet.dart';

class ListWidget extends StatelessWidget with RemoveSongFromPlaylistMixin {
  const ListWidget(this.items, this.title, this.isCompleteList,
      {super.key,
      this.isPlaylistOrAlbum = false,
      this.isArtistSongs = false,
      this.playlist,
      this.album,
      this.artist,
      this.scrollController});
  final List<dynamic> items;
  final String title;
  final bool isCompleteList;
  final ScrollController? scrollController;

  /// Valid for songlist
  final bool isArtistSongs;
  final bool isPlaylistOrAlbum;
  final Playlist? playlist;
  final Album? album;
  final Artist? artist;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Expanded(
        child: Center(
          child: Text(
            "No ${title.toLowerCase().tr}!",
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
      );
    } else if (title == "Videos" || title.contains("Songs")) {
      return isCompleteList
          ? Expanded(
              child: listViewSongVid(items,
                  isPlaylistOrAlbum: isPlaylistOrAlbum,
                  playlist: playlist,
                  album: album,
                  artist: artist,
                  sc: scrollController,
                  isArtistSongs: isArtistSongs))
          : SizedBox(
              height: items.length * 75.0,
              child: listViewSongVid(items),
            );
    } else if (title.contains("playlists")) {
      return listViewPlaylists(items, sc: scrollController);
    } else if (title == "Albums" || title == "Singles") {
      return listViewAlbums(items, sc: scrollController);
    } else if (title.contains('Artists')) {
      return isCompleteList
          ? Expanded(child: listViewArtists(items, sc: scrollController))
          : SizedBox(
              height: items.length * 95.0,
              child: listViewArtists(items),
            );
    }
    return const SizedBox.shrink();
  }

  Widget listViewSongVid(List<dynamic> items,
      {bool isPlaylistOrAlbum = false,
      Playlist? playlist,
      Album? album,
      Artist? artist,
      bool isArtistSongs = false,
      ScrollController? sc}) {
    final playerController = Get.find<PlayerController>();
    return ListView.builder(
      padding: const EdgeInsets.only(
        bottom: 200,
        top: 0,
      ),
      addRepaintBoundaries: false,
      addAutomaticKeepAlives: false,
      controller: sc,
      itemCount: items.length,
      physics: isCompleteList
          ? const BouncingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) => SongListTile(
        song: items[index] as MediaItem,
        onTap: () {
          isArtistSongs
              // if song is from artist then play from artist
              ? playerController.playPlayListSong(
                  List<MediaItem>.from(items), index,
                  playfrom: PlaylingFrom(
                      type: PlaylingFromType.ARTIST,
                      name: artist?.name ?? "........."))
              :
              // if playlist is not null then play from playlist else play from album
              playlist != null && album == null
                  ? playerController.playPlayListSong(
                      List<MediaItem>.from(items), index,
                      playfrom: PlaylingFrom(
                        type: PlaylingFromType.PLAYLIST,
                        name: playlist.title,
                      ))
                  : playerController.pushSongToQueue(items[index] as MediaItem);
        },
      ),
    );
  }

  Widget listViewPlaylists(List<dynamic> playlists, {ScrollController? sc}) {
    return Expanded(
      child: ListView.builder(
          padding: const EdgeInsets.only(
            bottom: 210,
            top: 0,
          ),
          controller: sc,
          itemCount: playlists.length,
          itemExtent: 80,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) => wideListTile(context,
              playlist: playlists[index],
              title: playlists[index].title,
              subtitle: playlists[index]?.description ?? "NA",
              subtitle2: "")),
    );
  }

  Widget listViewAlbums(List<dynamic> albums, {ScrollController? sc}) {
    return Expanded(
      child: ListView.builder(
          padding: const EdgeInsets.only(
            bottom: 210,
            top: 0,
          ),
          controller: sc,
          itemCount: albums.length,
          itemExtent: 80,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            String artistName = "";
            try {
              for (dynamic items in (albums[index].artists).sublist(1)) {
                artistName = "${artistName + items['name']},";
              }
              // ignore: empty_catches
            } catch (e) {}
            artistName = artistName.length > 16
                ? artistName.substring(0, 16)
                : artistName;
            return wideListTile(context,
                album: albums[index],
                title: albums[index].title,
                subtitle: artistName,
                subtitle2: albums[index].artists.isEmpty
                    ? "${albums[index].year}"
                    : "${(albums[index].artists[0]['name'])} • ${albums[index].year}");
          }),
    );
  }

  Widget listViewArtists(List<dynamic> artists, {ScrollController? sc}) {
    return ListView.builder(
      padding: const EdgeInsets.only(
        bottom: 200,
        top: 5,
      ),
      controller: sc,
      itemCount: artists.length,
      itemExtent: 76,
      physics: isCompleteList
          ? const BouncingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final fg =
            Theme.of(context).textTheme.titleMedium?.color ?? Colors.white;
        return InkWell(
          onTap: () {
            Get.toNamed(ScreenNavigationSetup.artistScreen,
                id: ScreenNavigationSetup.id,
                arguments: [false, artists[index]]);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                ImageWidget(
                  size: 58,
                  artist: artists[index],
                  borderRadius: BorderRadius.circular(58),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(artists[index].name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: fg,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text(artists[index].subscribers ?? 'Artist',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: fg.withOpacity(0.6), fontSize: 13)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: fg.withOpacity(0.4)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget wideListTile(BuildContext context,
      {dynamic album,
      dynamic playlist,
      required String title,
      required String subtitle,
      required String subtitle2}) {
    return InkWell(
      onTap: () {
        if (album != null) {
          Get.toNamed(ScreenNavigationSetup.albumScreen,
              id: ScreenNavigationSetup.id, arguments: (album, album.browseId));
        } else {
          Get.toNamed(ScreenNavigationSetup.playlistScreen,
              id: ScreenNavigationSetup.id,
              arguments: [playlist, playlist.playlistId]);
        }
      },
      child: Builder(builder: (context) {
        final fg =
            Theme.of(context).textTheme.titleMedium?.color ?? Colors.white;
        final sub = [subtitle2, subtitle]
            .map((e) => e.trim().replaceAll(RegExp(r',$'), ''))
            .where((e) => e.isNotEmpty && e != 'NA')
            .join(' · ');
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              ImageWidget(size: 64, album: album, playlist: playlist),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: fg,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2)),
                    const SizedBox(height: 3),
                    Text(
                        [
                          album != null ? 'Album' : 'Playlist',
                          if (sub.isNotEmpty) sub
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: fg.withOpacity(0.6), fontSize: 13)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: fg.withOpacity(0.4)),
            ],
          ),
        );
      }),
    );
  }
}
