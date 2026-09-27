import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:zuno/services/stream_access.dart';

class StreamProvider {
  final bool playable;
  final List<Audio>? audioFormats;
  final String statusMSG;
  StreamProvider(
      {required this.playable, this.audioFormats, this.statusMSG = ""});

  /// YouTube regularly blocks individual clients, so try them in order and
  /// use the first one that returns audio streams.
  static final List<List<YoutubeApiClient>> _clientFallbacks = [
    [YoutubeApiClient.androidSdkless],
    [YoutubeApiClient.ios],
    [YoutubeApiClient.androidVr],
    [YoutubeApiClient.tv],
  ];

  /// About half of the stream urls YouTube hands out only serve the first
  /// ~1MB and answer 403 afterwards; nothing in the url tells them apart.
  /// Each manifest is probed and re-fetched up to this many times.
  static const _attemptsPerClient = 4;

  static Future<StreamProvider> fetch(String videoId) async {
    final yt = YoutubeExplode();
    Object? lastError;
    try {
      for (final clients in _clientFallbacks) {
        try {
          List<AudioOnlyStreamInfo> audio = [];
          for (var attempt = 1; attempt <= _attemptsPerClient; attempt++) {
            final res = await yt.videos.streamsClient
                .getManifest(videoId, ytClients: clients);
            audio = res.audioOnly.toList()
              ..sort((a, b) => a.bitrate.compareTo(b.bitrate));
            if (audio.isEmpty) break;
            final probe = audio.last;
            if (await StreamAccess.isAccessible(probe.url.toString(),
                size: probe.size.totalBytes)) {
              break;
            }
            if (attempt == _attemptsPerClient) audio = [];
          }
          if (audio.isEmpty) continue;
          return StreamProvider(
              playable: true,
              statusMSG: "OK",
              audioFormats: audio
                  .map((e) => Audio(
                      itag: e.tag,
                      audioCodec:
                          e.audioCodec.contains('mp') ? Codec.mp4a : Codec.opus,
                      bitrate: e.bitrate.bitsPerSecond,
                      duration: _durationMsFromUrl(e.url),
                      loudnessDb: 0.0,
                      url: e.url.toString(),
                      size: e.size.totalBytes))
                  .toList());
        } on SocketException {
          rethrow;
        } catch (e) {
          lastError = e;
        }
      }
      throw lastError ??
          VideoUnplayableException("Streams are not available for this video");
    } catch (e) {
      if (e is SocketException) {
        return StreamProvider(
          playable: false,
          statusMSG: "networkError",
        );
      } else if (e is VideoUnplayableException) {
        return StreamProvider(
          playable: false,
          statusMSG: "Song is unplayable",
        );
      } else if (e is VideoRequiresPurchaseException) {
        return StreamProvider(
          playable: false,
          statusMSG: "Song requires purchase",
        );
      } else if (e is VideoUnavailableException) {
        return StreamProvider(
          playable: false,
          statusMSG: "Song is unavailable",
        );
      } else if (e is YoutubeExplodeException) {
        return StreamProvider(
          playable: false,
          statusMSG: e.message,
        );
      } else {
        return StreamProvider(
          playable: false,
          statusMSG: "Unknown error occurred",
        );
      }
    } finally {
      yt.close();
    }
  }

  /// Stream urls carry the duration in seconds as the `dur` query param.
  static int _durationMsFromUrl(Uri url) {
    final dur = double.tryParse(url.queryParameters['dur'] ?? '');
    return dur == null ? 0 : (dur * 1000).round();
  }

  Audio? get highestQualityAudio =>
      audioFormats?.lastWhere((item) => item.itag == 251 || item.itag == 140,
          orElse: () => audioFormats!.first);

  Audio? get highestBitrateMp4aAudio =>
      audioFormats?.lastWhere((item) => item.itag == 140 || item.itag == 139,
          orElse: () => audioFormats!.first);

  Audio? get highestBitrateOpusAudio =>
      audioFormats?.lastWhere((item) => item.itag == 251 || item.itag == 250,
          orElse: () => audioFormats!.first);

  Audio? get lowQualityAudio =>
      audioFormats?.lastWhere((item) => item.itag == 249 || item.itag == 139,
          orElse: () => audioFormats!.first);

  Map<String, dynamic> get hmStreamingData {
    return {
      "playable": playable,
      "statusMSG": statusMSG,
      "lowQualityAudio": lowQualityAudio?.toJson(),
      "highQualityAudio": highestQualityAudio?.toJson()
    };
  }
}

class Audio {
  final int itag;
  final Codec audioCodec;
  final int bitrate;
  final int duration;
  final int size;
  final double loudnessDb;
  final String url;
  Audio(
      {required this.itag,
      required this.audioCodec,
      required this.bitrate,
      required this.duration,
      required this.loudnessDb,
      required this.url,
      required this.size});

  Map<String, dynamic> toJson() => {
        "itag": itag,
        "audioCodec": audioCodec.toString(),
        "bitrate": bitrate,
        "loudnessDb": loudnessDb,
        "url": url,
        "approxDurationMs": duration,
        "size": size
      };

  factory Audio.fromJson(json) => Audio(
      audioCodec: (json["audioCodec"] as String).contains("mp4a")
          ? Codec.mp4a
          : Codec.opus,
      itag: json['itag'],
      duration: json["approxDurationMs"] ?? 0,
      bitrate: json["bitrate"] ?? 0,
      loudnessDb: (json['loudnessDb'])?.toDouble() ?? 0.0,
      url: json['url'],
      size: json["size"] ?? 0);
}

enum Codec { mp4a, opus }
