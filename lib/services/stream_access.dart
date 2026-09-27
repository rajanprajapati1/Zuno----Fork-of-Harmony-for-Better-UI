import 'dart:io';

import 'package:dio/dio.dart';

import '../utils/helper.dart';

/// A stream url together with its size in bytes.
typedef StreamSource = ({String url, int size});

/// Helpers that make access to googlevideo stream urls robust.
///
/// Stream urls can go stale well before their `expire` time: a stale url
/// still serves roughly the first megabyte but answers 403 for anything
/// beyond it. Players then fail right away (they request an open range) or
/// stop about a minute into the song.
class StreamAccess {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 20),
    validateStatus: (_) => true,
  ));

  static const _chunkSize = 1024 * 1024;
  static const _maxRetriesPerChunk = 4;
  static const _maxUrlRefreshes = 3;

  /// googlevideo urls are bound to the innertube client that issued them
  /// (the `c` query param), so send that client's User-Agent.
  static Map<String, String>? headersFor(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.host.endsWith('googlevideo.com')) return null;
    final userAgent = switch (uri.queryParameters['c']) {
      'ANDROID' || 'ANDROID_MUSIC' =>
        'com.google.android.youtube/20.10.38 (Linux; U; Android 11) gzip',
      'ANDROID_VR' =>
        'com.google.android.apps.youtube.vr.oculus/1.56.21 (Linux; U; Android 12L; eureka-user Build/SQ3A.220605.009.A1) gzip',
      'IOS' =>
        'com.google.ios.youtube/20.10.4 (iPhone16,2; U; CPU iOS 18_3_2 like Mac OS X;)',
      'TVHTML5' =>
        'Mozilla/5.0 (ChromiumStylePlatform) Cobalt/Version,gzip(gfe)',
      _ => null,
    };
    return userAgent == null ? null : {'User-Agent': userAgent};
  }

  /// Size of the stream from the `clen` query param, or 0 when unknown.
  static int sizeFromUrl(String url) =>
      int.tryParse(Uri.tryParse(url)?.queryParameters['clen'] ?? '') ?? 0;

  /// Checks that the whole stream is reachable by requesting a small range
  /// near its end (a stale url still serves the beginning).
  ///
  /// Returns true for non-http urls, and on network errors, so offline
  /// handling stays with the caller.
  static Future<bool> isAccessible(String url, {int size = 0}) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.scheme.startsWith('http')) return true;
    if (size <= 0) size = sizeFromUrl(url);
    final start = size > 128 * 1024 ? size - 64 * 1024 : 0;
    try {
      final res = await _dio.get<List<int>>(url,
          options: Options(
            responseType: ResponseType.bytes,
            headers: {
              ...?headersFor(url),
              'Range': 'bytes=$start-${start + 1023}',
            },
          ));
      final ok = res.statusCode == 206 || res.statusCode == 200;
      if (!ok) printINFO("Stream url not accessible (${res.statusCode})");
      return ok;
    } on DioException catch (e) {
      printERROR("Stream url check failed: ${e.message}");
      return true;
    }
  }

  /// Downloads [source] to [filePath] in bounded chunks.
  ///
  /// Each chunk is retried on network errors. When the url is rejected
  /// (403/410) [refreshSource] is asked for a new one and the download
  /// resumes from the same offset (or restarts if the new stream differs).
  /// Data is written to `<filePath>.part` and only renamed to [filePath]
  /// once the full size has been received.
  static Future<void> download({
    required StreamSource source,
    required String filePath,
    required Future<StreamSource?> Function() refreshSource,
    void Function(int received, int total)? onProgress,
  }) async {
    var url = source.url;
    var size = source.size > 0 ? source.size : sizeFromUrl(url);
    if (size <= 0) {
      throw const HttpException("Unknown stream size");
    }

    final partFile = File("$filePath.part");
    await partFile.parent.create(recursive: true);
    var raf = await partFile.open(mode: FileMode.write);
    var offset = 0;
    var refreshes = 0;

    try {
      while (offset < size) {
        final end = (offset + _chunkSize < size ? offset + _chunkSize : size) - 1;
        List<int>? bytes;
        var rejected = false;

        for (var attempt = 0; attempt < _maxRetriesPerChunk; attempt++) {
          try {
            final res = await _dio.get<List<int>>(url,
                options: Options(
                  responseType: ResponseType.bytes,
                  headers: {...?headersFor(url), 'Range': 'bytes=$offset-$end'},
                ));
            if (res.statusCode == 206 &&
                res.data != null &&
                res.data!.length == end - offset + 1) {
              bytes = res.data;
              break;
            }
            if (res.statusCode == 403 || res.statusCode == 410) {
              rejected = true;
              break;
            }
            printINFO("Chunk $offset-$end got ${res.statusCode}, retrying");
          } on DioException catch (e) {
            printERROR("Chunk $offset-$end failed: ${e.message}");
          }
          await Future.delayed(Duration(seconds: 1 << attempt));
        }

        if (bytes != null) {
          await raf.writeFrom(bytes);
          offset = end + 1;
          onProgress?.call(offset, size);
          continue;
        }

        if (!rejected || refreshes >= _maxUrlRefreshes) {
          throw HttpException("Download failed at byte $offset", uri: Uri.tryParse(url));
        }

        refreshes++;
        printINFO("Stream url rejected at byte $offset, fetching a new one");
        final fresh = await refreshSource();
        if (fresh == null) {
          throw HttpException("Could not refresh stream url", uri: Uri.tryParse(url));
        }
        final freshSize = fresh.size > 0 ? fresh.size : sizeFromUrl(fresh.url);
        url = fresh.url;
        if (freshSize != size) {
          // Different stream (other format/client): start over.
          size = freshSize;
          offset = 0;
          await raf.close();
          raf = await partFile.open(mode: FileMode.write);
        }
      }
      await raf.close();

      if (await partFile.length() != size) {
        throw const HttpException("Downloaded size mismatch");
      }
      final target = File(filePath);
      if (await target.exists()) await target.delete();
      await partFile.rename(filePath);
    } catch (_) {
      try {
        await raf.close();
      } catch (_) {}
      if (await partFile.exists()) await partFile.delete();
      rethrow;
    }
  }
}
