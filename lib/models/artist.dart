import '../models/thumbnail.dart';

class Artist {
  Artist({
    required this.name,
    required this.browseId,
    this.radioId,
    required this.thumbnailUrl,
    this.subscribers,
  });
  final String name;
  final String browseId;
  final String? radioId;
  final String? subscribers;
  final String thumbnailUrl;
  factory Artist.fromJson(dynamic json) {
    String? thumb;
    try {
      if (json["thumbnails"] != null && (json["thumbnails"] as List).isNotEmpty) {
        thumb = json["thumbnails"][0]["url"];
      }
    } catch (_) {}

    return Artist(
      name: json['artist'] ?? "Artist",
      browseId: json['browseId'] ?? "",
      radioId: json['radioId'],
      subscribers: (json['subscribers']) == null
          ? ""
          : (json['subscribers']).runtimeType.toString() == "String"
              ? json['subscribers']
              : json['subscribers']['text'],
      thumbnailUrl: thumb == null ? "" : Thumbnail(thumb).high);
  }

  Map<String, dynamic> toJson() => {
        'artist': name,
        'browseId': browseId,
        'radioId': radioId,
        'subscribers': subscribers,
        'thumbnails': [
          {'url': thumbnailUrl}
        ]
      };
}

class ArtistContent {
  ArtistContent(this.content, {this.title = "Artists"});
  final List<Artist> content;
  final String title;

  factory ArtistContent.fromJson(Map<dynamic, dynamic> json) => ArtistContent(
      (json['content'] as List).map((e) => Artist.fromJson(e)).toList(),
      title: json['title'] ?? "Artists");

  Map<String, dynamic> toJson() => {
        "type": "Artist Content",
        "title": title,
        "content": content.map((e) => e.toJson()).toList()
      };
}
