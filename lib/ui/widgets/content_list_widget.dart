import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../screens/Search/search_result_screen_controller.dart';
import 'package:zuno/ui/widgets/content_list_widget_item.dart';
import 'package:zuno/models/artist.dart';
import 'package:zuno/models/song.dart';
import 'package:zuno/models/album.dart';
import 'package:zuno/models/playlist.dart';

class ContentListWidget extends StatelessWidget {
  const ContentListWidget({
    super.key,
    this.content,
    this.isHomeContent = true,
    this.scrollController,
  });

  final dynamic content;
  final bool isHomeContent;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    if (content == null) return const SizedBox.shrink();
    
    final isAlbumContent = content is AlbumContent;
    final isSongContent = content is SongContent;
    final isArtistContent = content is ArtistContent;
    final isPlaylistContent = content is PlaylistContent;

    final String title = content.title ?? "";

    // Calibrated heights matching the new, taller ContentListItem metrics
    ContentItemStyle style = ContentItemStyle.standard;
    double listHeight = 275; // Matches standard card height + breathing room

    if (isArtistContent) {
      style = ContentItemStyle.circle;
      listHeight = 195;
    } else if (isSongContent) {
      style = ContentItemStyle.list;
      listHeight = 90; 
    } else if (isPlaylistContent) {
      style = ContentItemStyle.wide;
      listHeight = 295; // Matches wide card height + breathing room
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, title),
          const SizedBox(height: 12),
          _buildContent(context, style, listHeight),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
            ),
          ),
          if (!isHomeContent)
            TextButton(
              onPressed: () {
                final scrresController = Get.find<SearchResultScreenController>();
                scrresController.viewAllCallback(title);
              },
              child: Text(
                "viewAll".tr,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ContentItemStyle style, double height) {
    final List list = _getListFromContent();
    if (list.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: height,
      child: ListView.separated(
        controller: scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          return ContentListItem(
            content: list[index],
            style: style,
          );
        },
      ),
    );
  }

  List _getListFromContent() {
    if (content is AlbumContent) return content.albumList;
    if (content is SongContent) return content.songList;
    if (content is ArtistContent) return content.content;
    if (content is PlaylistContent) return content.playlistList;
    return [];
  }
}
