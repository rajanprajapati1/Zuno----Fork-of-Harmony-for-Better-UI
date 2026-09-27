import 'package:dio/dio.dart';
import 'package:zuno/models/tv_show.dart';

class IptvService {
  static const String _channelsUrl =
      'https://iptv-org.github.io/api/channels.json';
  static const String _streamsUrl =
      'https://iptv-org.github.io/api/streams.json';

  final Dio _dio = Dio();

  List<TvChannel>? _cachedChannels;
  List<TvStream>? _cachedStreams;

  /// Get all Indian TV channels
  Future<List<TvChannel>> getIndianChannels() async {
    if (_cachedChannels != null) return _cachedChannels!;

    try {
      final response = await _dio.get(_channelsUrl);
      final data = response.data as List;
      _cachedChannels = data
          .map((c) => TvChannel.fromJson(c))
          .where((c) => c.country == 'IN')
          .toList();
      return _cachedChannels!;
    } catch (e) {
      return [];
    }
  }

  /// Get stream URL for a channel
  Future<String?> getStreamUrl(String channelId) async {
    if (_cachedStreams == null) {
      try {
        final response = await _dio.get(_streamsUrl);
        final data = response.data as List;
        _cachedStreams = data.map((s) => TvStream.fromJson(s)).toList();
      } catch (e) {
        return null;
      }
    }

    final stream =
        _cachedStreams!.where((s) => s.channel == channelId).firstOrNull;
    return stream?.url;
  }

  /// Search channels by name
  Future<List<TvChannel>> searchChannels(String query) async {
    final channels = await getIndianChannels();
    final lowerQuery = query.toLowerCase();
    return channels
        .where((c) => c.name.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Get channels by category
  Future<List<TvChannel>> getChannelsByCategory(String category) async {
    final channels = await getIndianChannels();
    return channels.where((c) => c.categories.contains(category)).toList();
  }

  /// Get all unique categories from Indian channels
  Future<List<String>> getCategories() async {
    final channels = await getIndianChannels();
    final cats = <String>{};
    for (final c in channels) {
      cats.addAll(c.categories);
    }
    return cats.toList()..sort();
  }
}
