import 'package:flutter/material.dart';
import 'motion.dart';
import 'package:get/get.dart';
import 'package:audio_service/audio_service.dart';

import '../navigator.dart';
import 'image_widget.dart';
import 'package:zuno/ui/player/player_controller.dart';
import 'package:zuno/models/artist.dart';
import '../../models/album.dart';
import '../../models/playlist.dart';

enum ContentItemStyle { standard, wide, list, circle }

class ContentListItem extends StatefulWidget {
  const ContentListItem({
    super.key,
    required this.content,
    this.isLibraryItem = false,
    this.style = ContentItemStyle.standard,
  });

  final dynamic content;
  final bool isLibraryItem;
  final ContentItemStyle style;

  @override
  State<ContentListItem> createState() => _ContentListItemState();
}

class _QuickItemStyle {
  final double width;
  final double height;
  final double imageWidth;
  final double imageHeight;
  const _QuickItemStyle({
    required this.width, 
    required this.height, 
    required this.imageWidth, 
    required this.imageHeight
  });
}

class _ContentListItemState extends State<ContentListItem> {
  bool _isHovered = false;

  _QuickItemStyle get _metrics {
    switch (widget.style) {
      case ContentItemStyle.circle:
        return const _QuickItemStyle(width: 140, height: 190, imageWidth: 140, imageHeight: 140);
      case ContentItemStyle.list:
        return const _QuickItemStyle(width: 280, height: 64, imageWidth: 52, imageHeight: 52);
      case ContentItemStyle.wide:
      case ContentItemStyle.standard:
        // Square cover with text underneath, no card background
        return const _QuickItemStyle(width: 140, height: 196, imageWidth: 140, imageHeight: 140);
    }
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _metrics;
    final isCircle = widget.style == ContentItemStyle.circle;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: SizedBox(
          width: metrics.width,
          height: metrics.height,
          child: PressScale(
            child: InkWell(
            onTap: _handleTap,
            child: widget.style == ContentItemStyle.list 
              ? _buildListLayout(metrics)
              : _buildCardLayout(metrics),
          )),
        ),
      ),
    );
  }

  void _handleTap() {
    final isAlbum = widget.content is Album;
    final isArtist = widget.content is Artist;
    final isSong = widget.content is MediaItem;
    
    if (isAlbum) {
      Get.toNamed(ScreenNavigationSetup.albumScreen,
          id: ScreenNavigationSetup.id,
          arguments: [widget.content, (widget.content as Album).browseId]);
    } else if (isArtist) {
      // Artist screen expects [bool isIdOnly, dynamic data]
      Get.toNamed(ScreenNavigationSetup.artistScreen,
          id: ScreenNavigationSetup.id, 
          arguments: [true, (widget.content as Artist).browseId]);
    } else if (isSong) {
      final playerController = Get.find<PlayerController>();
      playerController.pushSongToQueue(widget.content);
      playerController.play();
    } else {
      // Playlist case
      Get.toNamed(ScreenNavigationSetup.playlistScreen,
          id: ScreenNavigationSetup.id,
          arguments: [widget.content, widget.content.playlistId ?? widget.content.id]);
    }
  }

  Widget _buildListLayout(_QuickItemStyle metrics) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Hero(
            tag: _getHeroTag(),
            child: _buildImage(metrics.imageWidth, metrics.imageHeight),
          ),
          const SizedBox(width: 14),
          Expanded(child: _buildTextContent(fixed: true)),
        ],
      ),
    );
  }

  Widget _buildCardLayout(_QuickItemStyle metrics) {
    final isCircle = widget.style == ContentItemStyle.circle;
    
    return Column(
      // CHANGED: Removed MainAxisSize.min which broke Expanded inside
      crossAxisAlignment: isCircle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Hero(
          tag: _getHeroTag(),
          child: _buildImage(
            metrics.imageWidth, 
            metrics.imageHeight, 
            radius: isCircle ? 100 : null
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildTextContent()),
      ],
    );
  }

  String _getHeroTag() {
    if (widget.content is Album) return widget.content.browseId;
    if (widget.content is MediaItem) return widget.content.id;
    if (widget.content is Artist) return widget.content.browseId;
    return widget.content.playlistId ?? widget.content.title ?? UniqueKey().toString();
  }

  Widget _buildImage(double width, double height, {double? radius}) {
    final isCircle = widget.style == ContentItemStyle.circle;
    
    BorderRadius imgRadius;
    if (isCircle) {
      imgRadius = BorderRadius.circular(100);
    } else if (radius != null) {
      imgRadius = BorderRadius.circular(radius);
    } else {
      imgRadius = BorderRadius.zero;
    }

    return ImageWidget(
      size: width,
      width: width,
      height: height,
      borderRadius: imgRadius,
      album: widget.content is Album ? widget.content : null,
      song: widget.content is MediaItem ? widget.content : null,
      artist: widget.content is Artist ? widget.content : null,
      playlist: widget.content is Playlist ? widget.content : null,
    );
  }

  Widget _buildTextContent({bool fixed = false}) {
    final isCircle = widget.style == ContentItemStyle.circle;
    String title = "";
    String sub = "";

    if (widget.content is Artist) {
      title = widget.content.name;
      sub = "Artist";
    } else if (widget.content is Album) {
      title = widget.content.title;
      sub = widget.isLibraryItem ? "Album" : (widget.content.artists.isNotEmpty ? (widget.content.artists[0]['name'] ?? "Album") : "Album");
    } else if (widget.content is MediaItem) {
      title = widget.content.title ?? "Song";
      sub = widget.content.artist ?? "Unknown artist";
    } else {
      title = widget.content.title ?? "Playlist";
      sub = "Playlist"; // Default for library playlists
      try {
        if (widget.content.description != null && widget.content.description.isNotEmpty) {
           sub = widget.content.description.replaceAll("\n", " ");
        }
      } catch (e) {}
    }

    final fg = Theme.of(context).textTheme.titleMedium?.color ?? Colors.white;
    return Column(
      mainAxisAlignment: fixed ? MainAxisAlignment.center : MainAxisAlignment.start,
      crossAxisAlignment: fixed ? CrossAxisAlignment.start : (isCircle ? CrossAxisAlignment.center : CrossAxisAlignment.start),
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: isCircle ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14.5,
            letterSpacing: -0.2,
            color: fg,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          sub,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: isCircle ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: fg.withOpacity(0.6),
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }
}
