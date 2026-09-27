import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zuno/ui/widgets/tv_focus_wrapper.dart';

/// In-app video player that uses webview to play content via embed URLs
class VideoPlayerScreen extends StatefulWidget {
  final String title;
  final String embedUrl;

  const VideoPlayerScreen({
    super.key,
    required this.title,
    required this.embedUrl,
  });

  /// Play a movie by TMDB ID
  factory VideoPlayerScreen.movie({
    Key? key,
    required String title,
    required int tmdbId,
  }) {
    return VideoPlayerScreen(
      key: key,
      title: title,
      embedUrl: 'https://vidcore.org/embed/movie/$tmdbId',
    );
  }

  /// Play a TV show episode
  factory VideoPlayerScreen.tvEpisode({
    Key? key,
    required String title,
    required int tmdbId,
    required int season,
    required int episode,
  }) {
    return VideoPlayerScreen(
      key: key,
      title: title,
      embedUrl: 'https://vidcore.org/embed/tv/$tmdbId/$season/$episode',
    );
  }

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _isFullscreen = false;
  final bool _isDesktop =
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  @override
  void initState() {
    super.initState();

    if (_isDesktop) {
      // Desktop fallback
      _launchInBrowser();
      return;
    }

    // Force landscape for movie watching (Mobile only)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
            // Inject CSS to hide ads and make video fullscreen
            _controller?.runJavaScript('''
              document.querySelectorAll('iframe').forEach(f => {
                f.style.width = '100%';
                f.style.height = '100%';
              });
              // Hide common ad elements
              var ads = document.querySelectorAll('[class*="ad"], [id*="ad"], .popup, .overlay');
              ads.forEach(a => a.style.display = 'none');
            ''');
          },
          onNavigationRequest: (request) {
            final url = request.url.toLowerCase();
            // Block non-HTTP/HTTPS URLs (like intent://, market://) which crash Android WebView
            if (!url.startsWith('http')) {
              return NavigationDecision.prevent;
            }
            // Block pop-ups and ad URLs
            if (url.contains('ads') ||
                url.contains('pop') ||
                url.contains('click') ||
                url.contains('tracker')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..setUserAgent(
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36')
      ..loadRequest(Uri.parse(widget.embedUrl));
  }

  Future<void> _launchInBrowser() async {
    final uri = Uri.parse(widget.embedUrl);
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch video player')),
        );
      }
    }
  }

  @override
  void dispose() {
    if (!_isDesktop) {
      // Restore orientation
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    super.dispose();
  }

  void _toggleFullscreen() {
    if (_isDesktop) return;
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDesktop) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(widget.title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.open_in_new, size: 60, color: Colors.white54),
              const SizedBox(height: 20),
              const Text(
                'Opening player in external browser...',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _launchInBrowser,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Open Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE50914),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _isFullscreen
          ? null
          : AppBar(
              backgroundColor: Colors.black,
              leading: TVFocusWrapper(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              title: Text(
                widget.title,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                TVFocusWrapper(
                  onTap: _toggleFullscreen,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
      body: Stack(
        children: [
          if (_controller != null) WebViewWidget(controller: _controller!),
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFFE50914)),
                  SizedBox(height: 16),
                  Text('Loading player...',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
