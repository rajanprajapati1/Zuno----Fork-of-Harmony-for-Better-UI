import 'package:flutter/material.dart';
import 'package:zuno/ui/widgets/motion.dart';
import 'package:zuno/ui/utils/brand.dart';
import 'package:get/get.dart';

import 'package:zuno/models/playlist.dart';
import 'package:zuno/ui/navigator.dart';
import 'package:zuno/ui/screens/Settings/settings_screen_controller.dart';
import 'package:zuno/ui/widgets/content_list_widget_item.dart';
import 'package:zuno/ui/widgets/page_title.dart';
import 'package:zuno/ui/widgets/piped_sync_widget.dart';
import '../../widgets/create_playlist_dialog.dart';
import 'library.dart';
import 'library_controller.dart';

/// Library hub: four gradient tiles (Songs, Playlists, Albums, Artists) that
/// open their own pages, quick rows for the built-in collections, and a
/// "Recently added" grid.
class CombinedLibrary extends StatelessWidget {
  const CombinedLibrary({super.key});

  @override
  Widget build(BuildContext context) {
    final settingscrnController = Get.find<SettingsScreenController>();
    final songsCon = Get.find<LibrarySongsController>();
    final playlistsCon = Get.find<LibraryPlaylistsController>();
    final albumsCon = Get.find<LibraryAlbumsController>();
    final artistsCon = Get.find<LibraryArtistsController>();
    final defaultIds =
        LibraryPlaylistsController.initPlst.map((e) => e.playlistId).toSet();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 200, right: 4),
        children: [
          PageTitle(
            'library'.tr,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Obx(() => (settingscrnController.isLinkedWithPiped.isTrue)
                    ? const PipedSyncWidget(padding: EdgeInsets.zero)
                    : const SizedBox.shrink()),
                IconButton(
                  tooltip: "CreateNewPlaylist".tr,
                  icon: const Icon(Icons.add, size: 28),
                  onPressed: () => showDialog(
                      context: context,
                      builder: (context) =>
                          const CreateNRenamePlaylistPopup()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Obx(() {
            final userPlaylists = playlistsCon.libraryPlaylists
                .where((p) => !defaultIds.contains(p.playlistId))
                .length;
            return GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.3,
              children: [
                _HubTile(
                  index: 0,
                  label: "songs".tr,
                  count: songsCon.librarySongsList.length,
                  icon: Icons.music_note_rounded,
                  colors: const [Color(0xFF4A1FB8), Color(0xFF8E8EE5)],
                  onTap: () => _open(context, "songs".tr,
                      const SongsLibraryWidget(isBottomNavActive: true)),
                ),
                _HubTile(
                  index: 1,
                  label: "playlists".tr,
                  count: userPlaylists,
                  icon: Icons.queue_music_rounded,
                  colors: const [Color(0xFF9E2A48), Color(0xFFFF7A8A)],
                  onTap: () => _open(
                      context,
                      "playlists".tr,
                      const PlaylistNAlbumLibraryWidget(
                          isAlbumContent: false, isBottomNavActive: true)),
                ),
                _HubTile(
                  index: 2,
                  label: "albums".tr,
                  count: albumsCon.libraryAlbums.length,
                  icon: Icons.album_rounded,
                  colors: const [Color(0xFFA8321C), Color(0xFFF59E42)],
                  onTap: () => _open(context, "albums".tr,
                      const PlaylistNAlbumLibraryWidget(isBottomNavActive: true)),
                ),
                _HubTile(
                  index: 3,
                  label: "artists".tr,
                  count: artistsCon.libraryArtists.length,
                  icon: Icons.mic_rounded,
                  colors: const [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                  onTap: () => _open(context, "artists".tr,
                      const LibraryArtistWidget(isBottomNavActive: true)),
                ),
              ],
            );
          }),
          const SizedBox(height: 22),
          for (final (id, icon) in const [
            ("LIBFAV", Icons.favorite_rounded),
            ("SongDownloads", Icons.download_for_offline_rounded),
            ("LIBRP", Icons.history_rounded),
            ("SongsCache", Icons.offline_pin_rounded),
          ])
            _CollectionRow(
              index: 4 + ["LIBFAV", "SongDownloads", "LIBRP", "SongsCache"].indexOf(id),
              playlist: LibraryPlaylistsController.initPlst
                  .firstWhere((p) => p.playlistId == id),
              icon: icon,
            ),
          Obx(() {
            final recent = <dynamic>[
              ...playlistsCon.libraryPlaylists
                  .where((p) => !defaultIds.contains(p.playlistId)),
              ...albumsCon.libraryAlbums,
            ].reversed.take(6).toList();
            if (recent.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 30, bottom: 14, left: 2),
                  child: Text("Recently added",
                      style: sectionFont(
                          color: Theme.of(context).textTheme.titleMedium?.color)),
                ),
                LayoutBuilder(builder: (context, c) {
                  final w = (c.maxWidth - 20) / 3;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 16,
                    children: [
                      for (final item in recent)
                        SizedBox(
                          width: w,
                          height: w + 44,
                          child: _SizedCard(content: item, size: w),
                        ),
                    ],
                  );
                }),
              ],
            );
          }),
        ],
      ),
    );
  }

  void _open(BuildContext context, String title, Widget child) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _LibrarySectionPage(title: title, child: child)));
  }
}

/// Square gradient tile, same look as the Liked Songs cover.
class _HubTile extends StatelessWidget {
  const _HubTile(
      {required this.label,
      required this.count,
      required this.icon,
      required this.colors,
      required this.onTap,
      this.index = 0});
  final String label;
  final int count;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;
  final int index;

  @override
  Widget build(BuildContext context) {
    return PressScale(child: Material(
      borderRadius: BorderRadius.circular(2),
      clipBehavior: Clip.hardEdge,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              // large faint icon for depth
              Positioned(
                right: -14,
                bottom: -14,
                child: Icon(icon,
                    size: 96, color: Colors.white.withOpacity(0.16)),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 26, color: Colors.white),
                    const Spacer(),
                    Text(label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4)),
                    const SizedBox(height: 2),
                    Text("$count ${count == 1 ? 'item' : 'items'}",
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )).appear(index: index);
  }
}

/// Flat row for a built-in collection: icon, name, chevron.
class _CollectionRow extends StatelessWidget {
  const _CollectionRow(
      {required this.playlist, required this.icon, this.index = 0});
  final Playlist playlist;
  final IconData icon;
  final int index;

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).textTheme.titleMedium?.color ?? Colors.white;
    return PressScale(
        scale: 0.98,
        child: InkWell(
      onTap: () => Get.toNamed(ScreenNavigationSetup.playlistScreen,
          id: ScreenNavigationSetup.id,
          arguments: [playlist, playlist.playlistId]),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.07))),
        ),
        child: Row(
          children: [
            const SizedBox(width: 2),
            Icon(icon, size: 24, color: fg.withOpacity(0.85)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(playlist.title,
                  style: TextStyle(
                      color: fg,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.2)),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 24, color: fg.withOpacity(0.4)),
          ],
        ),
      ),
    )).appear(index: index);
  }
}

/// ContentListItem squeezed to the grid cell width.
class _SizedCard extends StatelessWidget {
  const _SizedCard({required this.content, required this.size});
  final dynamic content;
  final double size;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.contain,
      alignment: Alignment.topLeft,
      child: ContentListItem(content: content, isLibraryItem: true),
    );
  }
}

/// Full page for one library section, opened from a hub tile.
class _LibrarySectionPage extends StatelessWidget {
  const _LibrarySectionPage({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 8),
          Row(
            children: [
              IconButton(
                tooltip: "back".tr,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 4),
              Text(title,
                  style: headerFont(
                      size: 32,
                      color: Theme.of(context).textTheme.titleMedium?.color)),
            ],
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
