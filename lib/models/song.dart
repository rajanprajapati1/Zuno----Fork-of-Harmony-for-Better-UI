import 'package:audio_service/audio_service.dart' show MediaItem;
import 'package:zuno/models/media_Item_builder.dart';

class SongContent {
  SongContent({required this.title, required this.songList});
  final String title;
  final List<MediaItem> songList;

  factory SongContent.fromJson(Map<dynamic, dynamic> json) => SongContent(
      title: json['title'],
      songList:
          (json['songlist'] as List).map((e) => MediaItemBuilder.fromJson(e)).toList());
  Map<String, dynamic> toJson() => {
        "type": "Song Content",
        "title": title,
        'songlist': songList.map((e) => MediaItemBuilder.toJson(e)).toList()
      };
}
